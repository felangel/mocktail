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
    var isMatching =
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
      if (roleArg is ArgMatcher) {
        if (roleArg is ArgMatcher && roleArg._capture) {
          _capturedArgs.add(actArg);
        }
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

    Set roleKeys = roleInvocation.namedArguments.keys.toSet();
    Set actKeys = invocation.namedArguments.keys.toSet();
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
}
