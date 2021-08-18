part of 'mocktail.dart';

/// An instance of an `_InvocationMatcher` using the provide [invocation].
Matcher isInvocation(Invocation invocation) => _InvocationMatcher(invocation);

class _InvocationMatcher implements Matcher {
  _InvocationMatcher(this._invocation);

  static Description _describeInvocation(Description d, Invocation invocation) {
    // For a getter or a setter, just return get <member> or set <member> <arg>.
    if (invocation.isAccessor) {
      d = d
          .add(invocation.isGetter ? 'get ' : 'set ')
          .add(_symbolToString(invocation.memberName));
      if (invocation.isSetter) {
        d = d.add(' ').addDescriptionOf(invocation.positionalArguments.first);
      }
      return d;
    }
    // For a method, return <member><<typeArgs>>(<args>).
    d = d.add(_symbolToString(invocation.memberName));

    if (invocation.typeArguments.isNotEmpty) {
      d.add('<').addAll('', ', ', '', invocation.typeArguments).add('>');
    }

    d.add('(').addAll('', ', ', '', invocation.positionalArguments);
    if (invocation.positionalArguments.isNotEmpty &&
        invocation.namedArguments.isNotEmpty) {
      d = d.add(', ');
    }
    // Also added named arguments, if any.
    return d.addAll('', ', ', '', _namedArgsAndValues(invocation)).add(')');
  }

  // Returns named arguments as an iterable of '<name>: <value>'.
  static Iterable<String> _namedArgsAndValues(Invocation invocation) =>
      invocation.namedArguments.keys.map((name) =>
          '${_symbolToString(name)}: ${invocation.namedArguments[name]}');

  // This will give is a mangled symbol in dart2js/aot with minification
  // enabled, but it's safe to assume very few people will use the invocation
  // matcher in a production test anyway due to noSuchMethod.
  static String _symbolToString(Symbol symbol) {
    return symbol.toString().split('"')[1];
  }

  final Invocation _invocation;

  @override
  Description describe(Description d) => _describeInvocation(d, _invocation);

  @override
  Description describeMismatch(dynamic item, Description d, _, __) {
    if (item is Invocation) {
      d = d.add('Does not match ');
      return _describeInvocation(d, item);
    }
    return d.add('Is not an Invocation');
  }

  @override
  bool matches(dynamic item, _) =>
      item is Invocation &&
      _invocation.memberName == item.memberName &&
      _invocation.isSetter == item.isSetter &&
      _invocation.isGetter == item.isGetter &&
      const ListEquality<dynamic>(_MatcherEquality())
          .equals(_invocation.typeArguments, item.typeArguments) &&
      const ListEquality<dynamic>(_MatcherEquality())
          .equals(_invocation.positionalArguments, item.positionalArguments) &&
      const MapEquality<dynamic, dynamic>(values: _MatcherEquality())
          .equals(_invocation.namedArguments, item.namedArguments);
}

// Uses both DeepCollectionEquality and custom matching for invocation matchers.
class _MatcherEquality extends DeepCollectionEquality {
  const _MatcherEquality();

  @override
  bool equals(dynamic e1, dynamic e2) {
    // All argument matches are wrapped in `ArgMatcher`, so we have to unwrap
    // them into the raw `Matcher` type in order to finish our equality checks.
    if (e1 is ArgMatcher) {
      e1 = e1.matcher;
    }
    if (e2 is ArgMatcher) {
      e2 = e2.matcher;
    }
    if (e1 is Matcher && e2 is! Matcher) {
      return e1.matches(e2, <dynamic, dynamic>{});
    }
    if (e2 is Matcher && e1 is! Matcher) {
      return e2.matches(e1, <dynamic, dynamic>{});
    }
    return super.equals(e1, e2);
  }

  // We force collisions on every value so equals() is called.
  @override
  int hash(_) => 0;
}

// When using an [ArgMatcher], we transform our invocation to have knowledge of
// which arguments are wrapped, and which ones are not. Otherwise we just use
// the existing invocation object.
Invocation _useMatchedInvocationIfSet(Invocation invocation) {
  if (_storedArgs.isNotEmpty || _storedNamedArgs.isNotEmpty) {
    invocation = _InvocationForMatchedArguments(invocation);
  }
  return invocation;
}

/// An Invocation implementation that takes arguments from [_storedArgs] and
/// [_storedNamedArgs].
class _InvocationForMatchedArguments extends Invocation {
  _InvocationForMatchedArguments._(
    this.memberName,
    this.positionalArguments,
    this.namedArguments,
    this.isGetter,
    this.isMethod,
    this.isSetter,
  );

  @override
  factory _InvocationForMatchedArguments(Invocation invocation) {
    // Handle named arguments first, so that we can provide useful errors for
    // the various bad states. If all is well with the named arguments, then we
    // can process the positional arguments, and resort to more general errors
    // if the state is still bad.
    final namedArguments = _reconstituteNamedArgs(invocation);
    final positionalArguments = _reconstitutePositionalArgs(invocation);

    _storedArgs.clear();
    _storedNamedArgs.clear();

    return _InvocationForMatchedArguments._(
      invocation.memberName,
      positionalArguments,
      namedArguments,
      invocation.isGetter,
      invocation.isMethod,
      invocation.isSetter,
    );
  }

  @override
  final Symbol memberName;
  @override
  final Map<Symbol, dynamic> namedArguments;
  @override
  final List<dynamic> positionalArguments;
  @override
  final bool isGetter;
  @override
  final bool isMethod;
  @override
  final bool isSetter;

  // Reconstitutes the named arguments in an invocation from
  // [_storedNamedArgs].
  //
  // The `namedArguments` in [invocation] which are null should be represented
  // by a stored value in [_storedNamedArgs].
  static Map<Symbol, dynamic> _reconstituteNamedArgs(Invocation invocation) {
    final namedArguments = <Symbol, dynamic>{};
    final storedNamedArgSymbols = _storedNamedArgs.keys.map(
      (name) => Symbol(name),
    );

    // Iterate through [invocation]'s named args, validate them, and add them
    // to the return map.
    invocation.namedArguments.forEach((name, dynamic arg) {
      if (arg == null) {
        if (!storedNamedArgSymbols.contains(name)) {
          // Either this is a parameter with default value `null`, or a `null`
          // argument was passed, or an unnamed ArgMatcher was used. Just use
          // `null`.
          namedArguments[name] = null;
        }
      } else {
        // Add each real named argument (not wrapped in an ArgMatcher).
        namedArguments[name] = arg;
      }
    });

    // Iterate through the stored named args, validate them, and add them to
    // the return map.
    _storedNamedArgs.forEach((name, arg) {
      var nameSymbol = Symbol(name);
      if (!invocation.namedArguments.containsKey(nameSymbol)) {
        // Clear things out for the next call.
        _storedArgs.clear();
        _storedNamedArgs.clear();
        throw ArgumentError(
          'An ArgumentMatcher was declared as named $name, but was not '
          'passed as an argument named $name.\n\n'
          'BAD:  when(() => obj.fn(any(named: "a")))\n'
          'GOOD: when(() => obj.fn(a: any(named: "a")))',
        );
      }
      final dynamic namedArgValue = invocation.namedArguments[nameSymbol];
      final isNotFallbackValue = namedArgValue != arg._fallbackValue;
      if (namedArgValue != null && isNotFallbackValue) {
        // Clear things out for the next call.
        _storedArgs.clear();
        _storedNamedArgs.clear();
        throw ArgumentError(
          'An ArgumentMatcher was declared as named $name, but a different '
          'value (${invocation.namedArguments[nameSymbol]}) was passed as '
          '$name.\n\n'
          'BAD:  when(() => obj.fn(b: any(named: "a")))\n'
          'GOOD: when(() => obj.fn(b: any(named: "b")))',
        );
      }
      namedArguments[nameSymbol] = arg;
    });

    return namedArguments;
  }

  static List<dynamic> _reconstitutePositionalArgs(Invocation invocation) {
    final positionalArguments = <dynamic>[];
    final nullPositionalArguments =
        invocation.positionalArguments.where((dynamic arg) {
      return arg == null ||
          _storedArgs.any(
            (storedArg) => storedArg._fallbackValue == arg,
          );
    });
    if (_storedArgs.length > nullPositionalArguments.length) {
      // More _positional_ ArgMatchers were stored than were actually passed as
      // positional arguments. There are three ways this call could have been
      // parsed and resolved:
      //
      // * an ArgMatcher was passed in [invocation] as a named argument, but
      //   without a name, and thus stored in [_storedArgs], something like
      //   `when(() => obj.fn(a: any()))`,
      // * an ArgMatcher was passed in an expression which was passed in
      //   [invocation], and thus stored in [_storedArgs], something like
      //   `when(() => obj.fn(Foo(any())))`, or
      // * a combination of the above.
      _storedArgs.clear();
      _storedNamedArgs.clear();
      throw ArgumentError(
        'An argument matcher (like `any()`) was either not used as an '
        'immediate argument to ${invocation.memberName} (argument matchers '
        'can only be used as an argument for the very method being stubbed '
        'or verified), or was used as a named argument without the Mocktail '
        '"named" API (Each argument matcher that is used as a named argument '
        'needs to specify the name of the argument it is being used in. For '
        'example: `when(() => obj.fn(x: any(named: "x")))`).',
      );
    }
    var storedIndex = 0;
    var positionalIndex = 0;
    while (storedIndex < _storedArgs.length &&
        positionalIndex < invocation.positionalArguments.length) {
      final arg = _storedArgs[storedIndex];
      final dynamic positionalArgument =
          invocation.positionalArguments[positionalIndex];
      if (positionalArgument == null ||
          positionalArgument == arg._fallbackValue) {
        // Add the [ArgMatcher] given to the argument matching helper.
        positionalArguments.add(arg);
        storedIndex++;
        positionalIndex++;
      } else {
        // An argument matching helper was not used; add the [ArgMatcher] from
        // [invocation].
        positionalArguments
            .add(invocation.positionalArguments[positionalIndex]);
        positionalIndex++;
      }
    }
    while (positionalIndex < invocation.positionalArguments.length) {
      // Some trailing non-ArgMatcher arguments.
      positionalArguments.add(invocation.positionalArguments[positionalIndex]);
      positionalIndex++;
    }

    return positionalArguments;
  }
}
