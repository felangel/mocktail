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
/// ```dart
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
    final _invocationStrict = _Invocation.fromInvocation(invocation);
    final _invocationLax = _Invocation(memberName: invocation.memberName);

    if (_stubs.containsKey(_invocationStrict)) {
      final stub = _stubs[_invocationStrict]!;
      if (!stub._calls.any((call) => call._invocation == _invocationStrict)) {
        stub._calls.add(_CallPair(invocation));
      }
      return stub.result(_invocationStrict);
    }

    if (_stubs.containsKey(_invocationLax)) {
      final stub = _stubs[_invocationLax]!;
      if (!stub._calls.any((call) => call._invocation == _invocationStrict)) {
        stub._calls.add(_CallPair(invocation));
      }
      return stub.result(_invocationLax);
    }

    final positionalArgs = List<Object?>.of(invocation.positionalArguments);
    final namedArgs = Map<Symbol, Object?>.of(invocation.namedArguments);
    final invocationMatch = _stubs.keys.firstWhere(
      (_invocation) {
        if (_invocation.memberName != invocation.memberName) return false;
        final positionalArgsMatch = _listEquals<Object?>(
          _invocation.positionalArguments.toList(),
          positionalArgs,
        );
        final namedArgsMatch = _mapEquals<Symbol, Object?>(
          _invocation.namedArguments,
          namedArgs,
        );
        return positionalArgsMatch && namedArgsMatch;
      },
      orElse: () => _Invocation.empty,
    );

    if (invocationMatch != _Invocation.empty) {
      final stub = _stubs[invocationMatch]!;
      if (!stub._calls.any((call) => call._invocation == _invocationStrict)) {
        stub._calls.add(_CallPair(invocation));
      }
      return stub.result(invocationMatch);
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
    if (entry.value._calls.isEmpty) {
      var argString = '';
      final hasArgs = entry.key.namedArguments.isNotEmpty ||
          entry.key.positionalArguments.isNotEmpty;
      if (hasArgs) {
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
const any = _ArgMatcher.any();

/// Argument matcher which matches any argument and captures that argument
/// for further inspection/assertions.
///
/// ```dart
/// final calculator = MockCalculator();
///
/// when(calculator).calls(#sum).thenReturn(0);
///
/// expect(calculator.sum(42, 1), equals(42));
///
/// final captured = verify(calculator).calls(#sum)
///   .withArgs(named: {#x: captureAny, #y: captureAny}).captured;
///
/// expect(captured.last, equals([42, 1]));
/// ```
const captureAny = _ArgMatcher.captureAny();

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
  return _ArgMatcher.anyThat(wrapMatcher(predicate));
}

/// Argument matcher which captures any argument which matches against
/// the provided [predicate].
/// The predicate can be an object instance or a [Matcher].
///
/// ```dart
/// final calculator = MockCalculator();
/// final isEven = isA<int>().having((x) => x % 2 == 0, 'even', true);
///
/// when(calculator).calls(#sum).thenReturn(42);
///
/// expect(calculator.sum(42, 1), equals(42));
///
/// final captured = verify(calculator).calls(#sum)
///   .withArgs(named: {#x: captureAnyThat(isEven), #y: 1}).captured;
///
/// expect(captured.last, equals([42]));
/// ```
Object captureAnyThat(dynamic predicate) {
  return _ArgMatcher.captureAnyThat(wrapMatcher(predicate));
}

class _ArgMatcher {
  const _ArgMatcher._(this._anything, this._capture, this._matcher);
  const _ArgMatcher.any() : this._(true, false, null);
  const _ArgMatcher.captureAny() : this._(true, true, null);
  const _ArgMatcher.captureAnyThat(Matcher matcher)
      : this._(false, true, matcher);
  const _ArgMatcher.anyThat(Matcher matcher) : this._(false, false, matcher);

  final bool _anything;
  final bool _capture;
  final Matcher? _matcher;

  bool matches(dynamic value) {
    if (_anything) return true;
    if (_matcher == null) return false;
    return _matcher!.matches(value, <dynamic, dynamic>{});
  }
}

bool _isArgCapture(dynamic e) => e is _ArgMatcher && e._capture;

class _Invocation {
  const _Invocation._({
    required this.memberName,
    this.positionalArguments = const [],
    this.namedArguments = const {},
  });

  factory _Invocation({
    required Symbol memberName,
    Iterable<Object?>? positionalArguments,
    Map<Symbol, Object?>? namedArguments,
  }) {
    return _Invocation._(
      memberName: memberName,
      positionalArguments: positionalArguments ?? <Object?>[],
      namedArguments: namedArguments ?? <Symbol, Object?>{},
    );
  }

  factory _Invocation.fromInvocation(Invocation invocation) {
    final positionalArgs = List<Object?>.of(invocation.positionalArguments);
    final namedArgs = Map<Symbol, Object?>.of(invocation.namedArguments);
    return _Invocation._(
      memberName: invocation.memberName,
      positionalArguments: positionalArgs,
      namedArguments: namedArgs,
    );
  }

  final Symbol memberName;
  final Iterable<Object?> positionalArguments;
  final Map<Symbol, Object?> namedArguments;

  static const empty = _Invocation._(memberName: Symbol(''));

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

class _CallPair {
  _CallPair(this.invocation);

  final Invocation invocation;
  _Invocation get _invocation => _Invocation.fromInvocation(invocation);
  int _callCount = 0;
  int get callCount => _callCount;
}

class _Stub {
  _Stub(this._result);

  final Object? Function(Invocation) _result;
  final _calls = <_CallPair>{};

  _CallPair? getCall(_Invocation invocation) {
    _CallPair? fallback;
    for (final call in _calls) {
      if (call._invocation == invocation) return call;
      if (_Invocation(memberName: call._invocation.memberName) == invocation) {
        fallback = call;
      }
    }
    return fallback;
  }

  Object? result(_Invocation invocation) {
    final call = getCall(invocation)!;
    call._callCount++;
    return _result(call.invocation);
  }
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

  List<dynamic> _captureArgs(
    List<Object?> positionalArguments,
    Map<Symbol, Object?> namedArguments,
    Invocation invocation,
  ) {
    final captured = <dynamic>[];
    for (var i = 0; i < positionalArguments.length; i++) {
      final dynamic arg = positionalArguments[i];
      final dynamic invocationArg = invocation.positionalArguments[i];
      if (_isArgCapture(arg) && (arg as _ArgMatcher).matches(invocationArg)) {
        captured.add(invocationArg);
      }
    }
    for (final entry in namedArguments.entries) {
      final arg = entry.value;
      final dynamic invocationArg = invocation.namedArguments[entry.key];
      if (_isArgCapture(arg) && (arg as _ArgMatcher).matches(invocationArg)) {
        captured.add(invocationArg);
      }
    }
    return captured;
  }

  List<dynamic> get captured {
    _Stub? stub;
    final _captured = <dynamic>[];

    if (_positionalArguments == null && _namedArguments == null) {
      return _captured;
    }
    final hasPositionalArgCapture =
        _positionalArguments?.any(_isArgCapture) ?? false;
    final hasNamedArgCapture =
        _namedArguments?.values.any(_isArgCapture) ?? false;

    if (!hasPositionalArgCapture && !hasNamedArgCapture) return _captured;

    final entry = _object._stubs.entries.firstWhere(
      (entry) {
        final invocation = entry.value.getCall(_invocation);
        return invocation != null;
      },
      orElse: () => MapEntry(_Invocation.empty, _Stub((_) => null)),
    );
    stub = entry.key != _Invocation.empty
        ? entry.value
        : _object._stubs[_Invocation(memberName: _memberName)];
    if (stub != null) {
      for (final call in stub._calls) {
        _captured.add(
          _captureArgs(
            _positionalArguments != null ? List.of(_positionalArguments!) : [],
            _namedArguments != null
                ? Map.of(_namedArguments!)
                : <Symbol, Object?>{},
            call.invocation,
          ),
        );
      }
    }

    return _captured;
  }

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
          for (final call in stub._calls) {
            actualCallCount += call.callCount;
          }
        }
      }
    }
    // Strict Invocation Verification
    else {
      final entry = _object._stubs.entries.firstWhere(
        (entry) {
          final invocation = entry.value.getCall(_invocation);
          return invocation != null;
        },
        orElse: () => MapEntry(_Invocation.empty, _Stub((_) => null)),
      );
      stub = entry.key != _Invocation.empty
          ? entry.value
          : _object._stubs[_Invocation(memberName: _memberName)];
      if (stub != null) {
        final call = stub.getCall(entry.key);
        actualCallCount += call?.callCount ?? 0;
      }
    }

    var argString = '';
    if (stub != null && stub._calls.any((call) => call.invocation.isMethod)) {
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

  void thenReturn([Object? result]) {
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
  if (b == null) return false;
  if (identical(a, b)) return true;
  a = List.of(a)..removeWhere((e) => e == null);
  b = List.of(b)..removeWhere((b) => b == null);
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index += 1) {
    if (!_isMatch(a[index], b[index])) return false;
  }
  return true;
}

bool _mapEquals<T, U>(Map<T, U>? a, Map<T, U>? b) {
  if (a == null) return b == null;
  if (b == null) return false;
  if (identical(a, b)) return true;
  a = Map.of(a)..removeWhere((key, value) => value == null);
  b = Map.of(b)..removeWhere((key, value) => value == null);
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    if (!_isMatch(a[key], b[key])) return false;
  }
  return true;
}

bool _isMatch(dynamic a, dynamic b) {
  if (identical(a, b)) return true;
  if (a == any || b == any) return true;
  if (a is _ArgMatcher) return a.matches(b);
  if (b is _ArgMatcher) return b.matches(a);
  if (a is Map && b is Map) return _mapEquals<dynamic, dynamic>(a, b);
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
