part of 'mocktail.dart';

/// {@template invocation_matcher}
/// A [Matcher] for [Invocation] instances.
/// {@endtemplate}
class InvocationMatcher {
  /// {@macro incovation_matcher}
  InvocationMatcher(this.roleInvocation);

  /// The role invocation
  final Invocation roleInvocation;

  /// matches function which determines whether the current
  /// [roleInvocation] matches the provided [invocation].
  bool matches(Invocation invocation) {
    final isMatching =
        _isMethodMatches(invocation) && _isArgumentsMatches(invocation);
    if (isMatching) {
      _captureArguments(invocation);
    }
    return isMatching;
  }

  bool _isMethodMatches(Invocation invocation) {
    if (invocation.memberName != roleInvocation.memberName) {
      return false;
    }
    if ((invocation.isGetter != roleInvocation.isGetter) ||
        (invocation.isSetter != roleInvocation.isSetter) ||
        (invocation.isMethod != roleInvocation.isMethod)) {
      return false;
    }
    return true;
  }

  void _captureArguments(Invocation invocation) {
    var index = 0;
    for (final roleArg in roleInvocation.positionalArguments) {
      final dynamic actArg = invocation.positionalArguments[index];
      if (roleArg is ArgMatcher && roleArg._capture) {
        _capturedArgs.add(actArg);
      }
      index++;
    }
    for (final roleKey in roleInvocation.namedArguments.keys) {
      final dynamic roleArg = roleInvocation.namedArguments[roleKey];
      final dynamic actArg = invocation.namedArguments[roleKey];
      if (roleArg is ArgMatcher && roleArg._capture) {
        _capturedArgs.add(actArg);
      }
    }
  }

  bool _isArgumentsMatches(Invocation invocation) {
    if (invocation.positionalArguments.length !=
        roleInvocation.positionalArguments.length) {
      return false;
    }
    if (invocation.namedArguments.length !=
        roleInvocation.namedArguments.length) {
      return false;
    }
    if (invocation.typeArguments.length !=
        roleInvocation.typeArguments.length) {
      return false;
    }

    var positionalArgIndex = 0;
    for (final roleArg in roleInvocation.positionalArguments) {
      final dynamic actArg = invocation.positionalArguments[positionalArgIndex];
      if (!_isMatchingArg(roleArg, actArg)) {
        return false;
      }
      positionalArgIndex++;
    }

    var typeArgIndex = 0;
    for (final roleArg in roleInvocation.typeArguments) {
      final dynamic actArg = invocation.typeArguments[typeArgIndex];
      if (!_isMatchingTypeArg(roleArg, actArg)) {
        return false;
      }
      typeArgIndex++;
    }

    final roleKeys = roleInvocation.namedArguments.keys.toSet();
    final actKeys = invocation.namedArguments.keys.toSet();
    if (roleKeys.difference(actKeys).isNotEmpty ||
        actKeys.difference(roleKeys).isNotEmpty) {
      return false;
    }
    for (final roleKey in roleInvocation.namedArguments.keys) {
      final dynamic roleArg = roleInvocation.namedArguments[roleKey];
      final dynamic actArg = invocation.namedArguments[roleKey];
      if (!_isMatchingArg(roleArg, actArg)) {
        return false;
      }
    }
    return true;
  }

  bool _isMatchingArg(dynamic roleArg, dynamic actArg) {
    if (roleArg is ArgMatcher) {
      return roleArg.matcher.matches(actArg, <dynamic, dynamic>{});
    } else {
      return equals(roleArg).matches(actArg, <dynamic, dynamic>{});
    }
  }

  bool _isMatchingTypeArg(Type roleTypeArg, dynamic actTypeArg) {
    return roleTypeArg == actTypeArg;
  }

  /// Returns an [_ArgumentMismatch] for each argument of [invocation] that
  /// does not match [roleInvocation].
  ///
  /// Returns `null` when [invocation] does not target the same member with
  /// the same shape (positional arity, named argument keys and type
  /// arguments), in which case a per-argument comparison is meaningless.
  List<_ArgumentMismatch>? _argumentMismatches(Invocation invocation) {
    if (!_isMethodMatches(invocation)) return null;
    if (invocation.positionalArguments.length !=
        roleInvocation.positionalArguments.length) {
      return null;
    }
    if (invocation.typeArguments.length !=
        roleInvocation.typeArguments.length) {
      return null;
    }
    final roleKeys = roleInvocation.namedArguments.keys.toSet();
    final actKeys = invocation.namedArguments.keys.toSet();
    if (roleKeys.difference(actKeys).isNotEmpty ||
        actKeys.difference(roleKeys).isNotEmpty) {
      return null;
    }

    var typeArgIndex = 0;
    for (final roleTypeArg in roleInvocation.typeArguments) {
      final dynamic actTypeArg = invocation.typeArguments[typeArgIndex];
      if (!_isMatchingTypeArg(roleTypeArg, actTypeArg)) return null;
      typeArgIndex++;
    }

    final mismatches = <_ArgumentMismatch>[];
    var positionalArgIndex = 0;
    for (final roleArg in roleInvocation.positionalArguments) {
      final dynamic actArg = invocation.positionalArguments[positionalArgIndex];
      if (!_isMatchingArg(roleArg, actArg)) {
        mismatches.add(
          _ArgumentMismatch(
            'positional argument #$positionalArgIndex',
            roleArg,
            actArg,
          ),
        );
      }
      positionalArgIndex++;
    }
    for (final roleKey in roleInvocation.namedArguments.keys) {
      final dynamic roleArg = roleInvocation.namedArguments[roleKey];
      final dynamic actArg = invocation.namedArguments[roleKey];
      if (!_isMatchingArg(roleArg, actArg)) {
        mismatches.add(
          _ArgumentMismatch(
            "named argument '${_symbolToString(roleKey)}'",
            roleArg,
            actArg,
          ),
        );
      }
    }
    return mismatches;
  }
}

/// The length beyond which a mismatched [String] argument is considered
/// large enough that a rich diff (via [Matcher.describeMismatch]) is more
/// readable than the plain listing of the two calls.
const _stringDiffThreshold = 40;

/// The number of elements beyond which a mismatched collection argument is
/// considered large enough for a rich diff.
const _collectionDiffThreshold = 5;

/// A single argument of a real invocation that did not match the
/// corresponding argument of the invocation being verified.
class _ArgumentMismatch {
  factory _ArgumentMismatch(String location, dynamic roleArg, dynamic actArg) {
    if (roleArg is ArgMatcher) {
      return _ArgumentMismatch._(location, roleArg.matcher, null, actArg);
    }
    return _ArgumentMismatch._(location, equals(roleArg), roleArg, actArg);
  }

  const _ArgumentMismatch._(
    this.location,
    this.matcher,
    this.expectedValue,
    this.actualArg,
  );

  /// A human readable location of the argument within the invocation,
  /// e.g. `positional argument #0` or `named argument 'style'`.
  final String location;

  /// The [Matcher] the argument was compared against.
  final Matcher matcher;

  /// The expected value, or `null` when the expectation was an [ArgMatcher]
  /// rather than a concrete value.
  final dynamic expectedValue;

  /// The actual value the mock was invoked with.
  final dynamic actualArg;

  /// Whether the mismatched values are large enough that a rich diff is
  /// meaningfully more readable than the existing short form.
  bool get isDiffWorthy => _isLarge(expectedValue) || _isLarge(actualArg);

  static bool _isLarge(dynamic value) {
    if (value is String) {
      return value.contains('\n') || value.length > _stringDiffThreshold;
    }
    if (value is Iterable) return value.length > _collectionDiffThreshold;
    if (value is Map) return value.length > _collectionDiffThreshold;
    return false;
  }

  /// Describes the mismatch using [matcher], which produces readable diffs
  /// for long strings (pinpointing the offset at which they differ) and for
  /// collections (pinpointing the mismatched index or key).
  String describe() {
    final mismatch = StringDescription();
    // Matchers expect [Matcher.describeMismatch] to receive the same match
    // state that [Matcher.matches] populated for the mismatched value.
    final matchState = <dynamic, dynamic>{};
    matcher
      ..matches(actualArg, matchState)
      ..describeMismatch(actualArg, mismatch, matchState, false);
    final description = mismatch.toString();
    if (description.trim().isNotEmpty) return description;
    final expected = StringDescription();
    matcher.describe(expected);
    final actual = StringDescription()..addDescriptionOf(actualArg);
    return 'expected $expected but was $actual';
  }
}
