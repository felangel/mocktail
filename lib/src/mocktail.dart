import 'package:matcher/matcher.dart';

/// {@template mocktail_failure}
/// An exception thrown from the mocktail library.
/// {@endtemplate}
class MocktailFailure implements Exception {
  /// {@macro mocktail_failure}
  const MocktailFailure(this.message);

  /// The failure message
  final String message;

  @override
  String toString() => 'MocktailFailure: $message';
}

/// {@template mock}
/// Extend this class to mark an implementation as a [Mock].
///
/// A mocked class implements all fields and methods with a default
/// implementation that does not throw a [NoSuchMethodError], and may be further
/// customized at runtime to define how it may behave using [when].
/// ````dart
/// // Real class.
/// class Cat {
///   String getSound(String suffix) => 'Meow$suffix';
/// }
///
/// // Mock class.
/// class MockCat extends Mock implements Cat {}
///
/// void main() {
///   // Create a mock Cat at runtime.
///   final cat = MockCat();
///
///   // When 'getSound' is called, return 'Woof'
///   when(cat).calls('getSound').thenReturn('Woof');
///
///   // Try making a Cat sound...
///   print(cat.getSound('foo')); // Prints 'Woof'
/// }
/// ```
///
/// A class which `extends Mock` should not have any directly implemented
/// overridden fields or methods. These fields would not be usable as a [Mock]
/// with [verify] or [when].
/// {@endtemplate}
class Mock {
  final _stubs = <_Invocation, _Stub>{};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final positionalArgs = List<Object?>.of(invocation.positionalArguments);
    final namedArgs = Map<Symbol, Object?>.of(invocation.namedArguments);
    final _invocationStrict = _Invocation(
      memberName: invocation.memberName,
      positionalArguments: positionalArgs,
      namedArguments: namedArgs,
    );
    final _invocationLax = _Invocation(memberName: invocation.memberName);

    if (_stubs.containsKey(_invocationStrict)) {
      final stub = _stubs[_invocationStrict]!.._invocation = invocation;
      return stub.result();
    }

    if (_stubs.containsKey(_invocationLax)) {
      final stub = _stubs[_invocationLax]!.._invocation = invocation;
      return stub.result();
    }

    final invocationMatch = _stubs.keys.firstWhere(
      (invocation) {
        final positionalArgsMatch = _listEquals<Object?>(
          invocation.positionalArguments.toList(),
          positionalArgs,
        );
        final namedArgsMatch = _mapEquals<Symbol, Object?>(
          invocation.namedArguments,
          namedArgs,
        );
        return positionalArgsMatch && namedArgsMatch;
      },
      orElse: () => _Invocation.empty,
    );

    if (invocationMatch != _Invocation.empty) {
      final stub = _stubs[invocationMatch]!.._invocation = invocation;
      return stub.result();
    }

    return super.noSuchMethod(invocation);
  }
}

/// Create a stub method response.
///
/// Call a method on a mock object within the call to `when`, and call a
/// canned response method on the result. For example:
///
/// ```dart
/// when(cat).calls('eatFood').withArgs(positional: ["fish"]).thenReturn(true);
/// ```
///
/// Mocktail will store the stub for `cat.eatFood`, and pair the exact
/// arguments given with the response. When `cat.eatFood` is called,
/// Mocktail will respond with the stubbed response
/// if it can match the mock method parameters.
///
/// The response generators include `thenReturn`, `thenAnswer`, and `thenThrow`.
_WhenCall when(Object object) {
  if (object is! Mock) {
    throw StateError('when called on a real object.');
  }
  return _WhenCall(object);
}

/// Verify that a method on a mock object was called with the given arguments.
///
/// Call a method on a mock object within the call to `verify`.
///
/// ```dart
/// cat.eatFood("chicken");
/// verify(cat).calls("eatFood").withArgs(positional: ["chicken"]).times(1);
/// ```
///
/// Mocktail will fail the current test case if `cat.eatFood`
/// has not been called with `"chicken"`.
_VerifyCall verify(Object object) {
  if (object is! Mock) {
    throw StateError('verify called on a real object.');
  }
  return _VerifyCall(object);
}

/// Verifies that all stubs were used.
/// It is generally recommended to call `verifyMocks`
/// in the `tearDown` in order to ensure that all stubs
/// were invoked.
void verifyMocks(Object object) {
  if (object is! Mock) {
    throw StateError('verifyMocks called on a real object.');
  }
  for (final entry in object._stubs.entries) {
    if (entry.value.callCount == 0) {
      var argString = '';
      final hasArgs = entry.key.namedArguments.isNotEmpty ||
          entry.key.positionalArguments.isNotEmpty;
      if (entry.value._invocation?.isMethod == true || hasArgs) {
        argString = _argsToString(
          namedArgs: entry.key.namedArguments,
          positionalArgs: entry.key.positionalArguments.toList(),
        );
      }
      throw MocktailFailure(
        '''${object.runtimeType}.${entry.key.memberName.value}$argString => ${entry.value._result(Invocation.getter(const Symbol('entry.key.memberName')))} was stubbed but never invoked.''',
      );
    }
  }
}

/// Reset the state of the mock, typically for use between tests.
void reset(Object object) {
  if (object is! Mock) {
    throw StateError('reset called on a real object.');
  }
  object._stubs.clear();
}

/// Argument matcher which matches any argument.
///
/// ```dart
/// final calculator = MockCalculator();
///
/// when(calculator).calls(#sum)
///   .withArgs(named: {#x: any, #y: any})
///   .thenReturn(42);
///
/// expect(calculator.sum(42, 1), equals(42));
///
/// verify(calculator).calls(#sum)
///   .withArgs(named: {#x: 42, #y: 1})
///   .times(1);
/// ```
const any = _ArgMatcher.anything();

/// Argument matcher which matches any argument which matches against
/// the provided [predicate].
/// The predicate can be an object instance or a [Matcher].
///
/// ```dart
/// final calculator = MockCalculator();
/// final isEven = isA<int>().having((x) => x % 2 == 0, 'even', true);
///
/// when(calculator).calls(#sum)
///   .withArgs(named: {#x: anyThat(isEven), #y: any})
///   .thenReturn(42);
///
/// expect(calculator.sum(42, 1), equals(42));
///
/// verify(calculator).calls(#sum)
///   .withArgs(named: {#x: anyThat(isEven), #y: 1})
///   .times(1);
/// ```
Object anyThat(dynamic predicate) {
  return _ArgMatcher.matches(wrapMatcher(predicate));
}

class _ArgMatcher {
  const _ArgMatcher._(this._anything, this._matcher);
  const _ArgMatcher.anything() : this._(true, null);
  const _ArgMatcher.matches(Matcher matcher) : this._(false, matcher);

  final bool _anything;
  final Matcher? _matcher;

  bool matches(dynamic value) {
    if (_anything) return true;
    if (_matcher == null) return false;
    return _matcher!.matches(value, <dynamic, dynamic>{});
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is _ArgMatcher &&
        o._anything == _anything &&
        o._matcher == _matcher;
  }

  @override
  int get hashCode => _anything.hashCode ^ _matcher.hashCode;
}

class _Invocation {
  const _Invocation({
    required this.memberName,
    this.positionalArguments = const [],
    this.namedArguments = const {},
  });

  final Symbol memberName;
  final Iterable<Object?> positionalArguments;
  final Map<Symbol, Object?> namedArguments;

  static const empty = _Invocation(memberName: Symbol(''));

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is _Invocation &&
        o.memberName == memberName &&
        _listEquals(
            o.positionalArguments.toList(), positionalArguments.toList()) &&
        _mapEquals(o.namedArguments, namedArguments);
  }

  @override
  int get hashCode {
    final positionalArgumentsHash = positionalArguments.fold<int>(
        0, (previous, element) => previous ^ element.hashCode);
    final namedArgumentsHash =
        namedArguments.entries.fold<int>(0, (previous, element) {
      return previous ^ element.key.hashCode ^ element.value.hashCode;
    });
    return memberName.hashCode ^ positionalArgumentsHash ^ namedArgumentsHash;
  }
}

class _Stub {
  _Stub(this._result);

  final Object? Function(Invocation) _result;
  Invocation? _invocation;

  Object? result() {
    _callCount++;
    return _result(_invocation!);
  }

  int _callCount = 0;
  int get callCount => _callCount;
}

class _WhenCall {
  const _WhenCall(this._object);
  final Mock _object;

  _StubFunction calls(Symbol memberName) => _StubFunction(_object, memberName);
}

class _VerifyCall {
  const _VerifyCall(this._object);
  final Mock _object;

  _VerifyArgsCall called(Symbol memberName) =>
      _VerifyArgsCall(_object, memberName);
}

class _VerifyArgsCall extends _CallCountCall {
  _VerifyArgsCall(
    Mock object,
    Symbol memberName, {
    Iterable<Object?>? positionalArguments,
    Map<Symbol, Object?>? namedArguments,
  }) : super(object, memberName,
            positionalArguments: positionalArguments,
            namedArguments: namedArguments);

  _CallCountCall withArgs({
    Iterable<Object?>? positional,
    Map<Symbol, Object?>? named,
  }) {
    return _CallCountCall(
      _object,
      _memberName,
      positionalArguments: positional,
      namedArguments: named,
    );
  }
}

class _CallCountCall extends _MockInvocationCall {
  _CallCountCall(
    Mock object,
    Symbol memberName, {
    Iterable<Object?>? positionalArguments,
    Map<Symbol, Object?>? namedArguments,
  }) : super(object, memberName,
            positionalArguments: positionalArguments,
            namedArguments: namedArguments);

  void times(dynamic callCount) => _times(callCount);
  void once() => _times(1);
  void never() => _times(0);

  void _times(dynamic callCount) {
    _Stub? stub;
    var actualCallCount = 0;
    final positionalArgs = _positionalArguments?.toList() ?? <Object?>[];
    final namedArgs = _namedArguments ?? <Symbol, Object?>{};

    // Lax Invocation Verification (any)
    if (_positionalArguments == null && _namedArguments == null) {
      for (final entry in _object._stubs.entries) {
        if (entry.key.memberName == _memberName) {
          stub = entry.value;
          actualCallCount += entry.value.callCount;
        }
      }
    }
    // Strict Invocation Verification
    else {
      final strictStub = _object._stubs[_invocation];
      if (strictStub != null) {
        stub = strictStub;
        actualCallCount = strictStub.callCount;
      } else {
        final laxStub = _object._stubs[_Invocation(memberName: _memberName)];
        if (laxStub != null) {
          stub = laxStub;
          final invocation = laxStub._invocation;
          final positionalArgsMatch = _listEquals<Object?>(
            invocation?.positionalArguments ?? [],
            positionalArgs,
          );
          final namedArgsMatch = _mapEquals<Symbol, Object?>(
            invocation?.namedArguments ?? {},
            namedArgs,
          );

          if (positionalArgsMatch && namedArgsMatch) {
            actualCallCount = laxStub._callCount;
          }
        } else {
          final invocationMatch = _object._stubs.keys.firstWhere(
            (invocation) {
              final positionalArgsMatch = _listEquals<Object?>(
                invocation.positionalArguments.toList(),
                positionalArgs,
              );
              final namedArgsMatch = _mapEquals<Symbol, Object?>(
                invocation.namedArguments,
                namedArgs,
              );
              return positionalArgsMatch && namedArgsMatch;
            },
            orElse: () => _Invocation.empty,
          );

          if (invocationMatch != _Invocation.empty) {
            stub = _object._stubs[invocationMatch]!;
            actualCallCount = stub._callCount;
          }
        }
      }
    }

    var argString = '';
    if (stub != null && stub._invocation?.isMethod == true) {
      argString = _argsToString(
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
      );
    }

    final matcher = wrapMatcher(callCount);
    if (!matcher.matches(actualCallCount, <dynamic, dynamic>{})) {
      throw MocktailFailure(
        '''Expected ${_object.runtimeType}.${_memberName.value}$argString to be called ${matcher.describe(StringDescription())} time(s) but actual call count was <$actualCallCount>.''',
      );
    }
  }
}

class _StubFunction extends _MockInvocationCall {
  _StubFunction(
    Mock object,
    Symbol memberName, {
    Iterable<Object?>? positionalArguments,
    Map<Symbol, Object?>? namedArguments,
  }) : super(object, memberName,
            positionalArguments: positionalArguments,
            namedArguments: namedArguments);

  _StubFunction withArgs({
    Iterable<Object?>? positional,
    Map<Symbol, Object?>? named,
  }) {
    return _StubFunction(
      _object,
      _memberName,
      positionalArguments: positional,
      namedArguments: named,
    );
  }

  void thenReturn(Object? result) {
    _object._stubs[_invocation] = _Stub((_) => result);
  }

  void thenAnswer(Object? Function(Invocation) callback) {
    _object._stubs[_invocation] = _Stub(callback);
  }

  void thenThrow(Object throwable) {
    // ignore: only_throw_errors
    _object._stubs[_invocation] = _Stub((_) => throw throwable);
  }
}

class _MockInvocationCall {
  _MockInvocationCall(
    this._object,
    this._memberName, {
    Iterable<Object?>? positionalArguments,
    Map<Symbol, Object?>? namedArguments,
  })  : _positionalArguments = positionalArguments,
        _namedArguments = namedArguments;

  final Mock _object;
  final Symbol _memberName;
  final Iterable<Object?>? _positionalArguments;
  final Map<Symbol, Object?>? _namedArguments;

  _Invocation get _invocation {
    if (_positionalArguments == null && _namedArguments == null) {
      return _Invocation(memberName: _memberName);
    }
    if (_positionalArguments != null && _namedArguments == null) {
      return _Invocation(
        memberName: _memberName,
        positionalArguments: _positionalArguments!,
      );
    }
    if (_positionalArguments == null && _namedArguments != null) {
      return _Invocation(
        memberName: _memberName,
        namedArguments: _namedArguments!,
      );
    }
    return _Invocation(
      memberName: _memberName,
      positionalArguments: _positionalArguments!,
      namedArguments: _namedArguments!,
    );
  }
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (var index = 0; index < a.length; index += 1) {
    if (!_isMatch(a[index], b[index])) return false;
  }
  return true;
}

bool _mapEquals<T, U>(Map<T, U>? a, Map<T, U>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    if (!_isMatch(a[key], b[key])) return false;
  }
  return true;
}

bool _isMatch(dynamic a, dynamic b) {
  if (identical(a, b)) return true;
  if (a == any || b == any) return true;
  if (a is _ArgMatcher && b is _ArgMatcher) return a == b;
  if (a is _ArgMatcher) return a.matches(b);
  if (b is _ArgMatcher) return b.matches(a);
  return a == b;
}

final _memberNameRegExp = RegExp(r'Symbol\("(.*?)"\)');

extension on Symbol {
  String get value {
    return _memberNameRegExp.firstMatch(toString())?.group(1) ?? toString();
  }
}

String _argsToString({
  List<Object?> positionalArgs = const [],
  Map<Symbol, Object?> namedArgs = const {},
}) {
  var argString = '(${positionalArgs.join(',')}';
  if (namedArgs.isNotEmpty) {
    if (positionalArgs.isNotEmpty) argString += ', ';
    for (final entry in namedArgs.entries) {
      argString += '${entry.key.value}: ${entry.value}, ';
    }
    argString = argString.substring(0, argString.length - 2);
  }
  argString += ')';
  return argString;
}
