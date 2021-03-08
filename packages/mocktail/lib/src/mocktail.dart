import 'dart:async';

import 'package:collection/collection.dart';
import 'package:matcher/matcher.dart';
import 'package:mocktail/mocktail.dart';
// ignore: deprecated_member_use
import 'package:test_api/test_api.dart';

part '_arg_matcher.dart';
part '_invocation_matcher.dart';
part '_is_invocation.dart';
part '_real_call.dart';
part '_register_matcher.dart';
part '_time_stamp_provider.dart';

_WhenCall? _whenCall;
_UntilCall? _untilCall;
var _whenInProgress = false;
bool _untilCalledInProgress = false;
var _verificationInProgress = false;

final _timer = _TimeStampProvider();
final _capturedArgs = <dynamic>[];
final _storedArgs = <ArgMatcher>[];
final _storedNamedArgs = <String, ArgMatcher>{};
final _verifyCalls = <_VerifyCall>[];

/// Opt-into [Mock] throwing [NoSuchMethodError] for unimplemented methods.
///
/// The default behavior when not using this is to always return `null`.
void throwOnMissingStub(
  Mock mock, {
  void Function(Invocation)? exceptionBuilder,
}) {
  exceptionBuilder ??= mock._noSuchMethod;
  mock._defaultResponse = () {
    return Expectation<dynamic>.allInvocations(exceptionBuilder!);
  };
}

/// Extend or mixin this class to mark the implementation as a [Mock].
///
/// A mocked class implements all fields and methods with a default
/// implementation that does not throw a [NoSuchMethodError], and may be further
/// customized at runtime to define how it may behave using [when].
///
/// __Example use__:
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
///   // Create a new mocked Cat at runtime.
///   final cat = MockCat();
///
///   // When 'getSound' is called, return 'Woof'
///   when(() => cat.getSound(any())).thenReturn('Woof');
///
///   // Try making a Cat sound...
///   print(cat.getSound('foo')); // Prints 'Woof'
/// }
/// ```
/// A class which `extends Mock` should not have any directly implemented
/// overridden fields or methods. These fields would not be usable as a [Mock]
/// with [verify] or [when]. To implement a subset of an interface manually use
/// [Fake] instead.
///
/// **WARNING**: [Mock] uses [noSuchMethod](goo.gl/r3IQUH), which is a _form_ of
/// runtime reflection, and causes sub-standard code to be generated. As such,
/// [Mock] should strictly _not_ be used in any production code, especially if
/// used within the context of Dart for Web (dart2js, DDC) and Dart for Mobile
/// (Flutter).
class Mock {
  static Null _answerNull(dynamic _) => null;
  static const _nullResponse = Expectation<Null>.allInvocations(_answerNull);

  final _invocationStreamController = StreamController<Invocation>.broadcast();

  final _responses = <Expectation<dynamic>>[];
  final _realCalls = <RealCall>[];
  _ReturnsCannedResponse _defaultResponse = () => _nullResponse;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    invocation = _useMatchedInvocationIfSet(invocation);
    if (_whenInProgress) {
      _whenCall = _WhenCall(this, invocation);
      return null;
    } else if (_verificationInProgress) {
      _verifyCalls.add(_VerifyCall(this, invocation));
      return null;
    } else if (_untilCalledInProgress) {
      _untilCall = _UntilCall(this, invocation);
      return null;
    } else {
      _realCalls.add(RealCall(this, invocation));
      _invocationStreamController.add(invocation);
      final cannedResponse = _responses.lastWhere(
        (response) {
          return response.call.matches(invocation, <dynamic, dynamic>{});
        },
        orElse: _defaultResponse,
      );
      return cannedResponse.response(invocation);
    }
  }

  @override
  int get hashCode => 0;

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  String toString() => runtimeType.toString();

  dynamic _noSuchMethod(Invocation invocation) {
    throw MissingStubError(invocation);
  }

  void _setExpected(Expectation<dynamic> cannedResponse) {
    _responses.add(cannedResponse);
  }

  String _realCallsToString([Iterable<RealCall>? realCalls]) {
    var stringRepresentations =
        (realCalls ?? _realCalls).map((call) => call.toString());
    if (stringRepresentations.any((s) => s.contains('\n'))) {
      // As each call contains newlines, put each on its own line, for better
      // readability.
      return stringRepresentations.join(',\n');
    } else {
      // A compact String should be perfect.
      return stringRepresentations.join(', ');
    }
  }

  String _unverifiedCallsToString() =>
      _realCallsToString(_realCalls.where((call) => !call.verified));
}

/// {@template missing_stub_error}
/// An error which is thrown when no stub is found which matches the arguments
/// of a real method call on a mock object.
/// {@endtemplate}
class MissingStubError extends Error {
  /// {@macro missing_stub_error}
  MissingStubError(this.invocation);

  /// The current invocation instance.
  final Invocation invocation;

  @override
  String toString() =>
      "MissingStubError: '${_symbolToString(invocation.memberName)}'\n"
      'No stub was found which matches the arguments of this method call:\n'
      '${invocation.toPrettyString()}\n\n'
      "Add a stub for this method using Mocktail's 'when' API.";
}

typedef _ReturnsCannedResponse = Expectation<dynamic> Function();

/// Create a stub method response.
///
/// Call a method on a mock object within the call to `when`, and call a
/// canned response method on the result. For example:
///
/// ```dart
/// when(() => cat.eatFood("fish")).thenReturn(true);
/// ```
///
/// Mocktail will store the fake call to `cat.eatFood`, and pair the exact
/// arguments given with the response. When `cat.eatFood` is called outside a
/// `when` or `verify` context (a call "for real"), Mocktail will respond with
/// the stored canned response, if it can match the mock method parameters.
///
/// The response generators include `thenReturn`, `thenAnswer`, and `thenThrow`.
///
/// See the README for more information.
When<T> Function<T>(T Function() x) get when {
  if (_whenCall != null) {
    throw StateError('Cannot call `when` within a stub response');
  }
  _whenInProgress = true;
  return <T>(T Function() _) {
    try {
      _();
    } catch (_) {
      if (_ is! TypeError) rethrow;
    }
    _whenInProgress = false;
    return When<T>();
  };
}

/// Result of [when] which enables methods to be stubbed via
/// - [thenReturn]
/// - [thenThrow]
/// - [thenAnswer]
class When<T> {
  /// Store a canned response for this method stub.
  ///
  /// Note: [expected] cannot be a Future or Stream, due to Zone considerations.
  /// To return a Future or Stream from a method stub, use [thenAnswer].
  void thenReturn(T expected) {
    if (expected is Future) {
      throw ArgumentError(
        '`thenReturn` should not be used to return a Future. '
        'Instead, use `thenAnswer((_) => future)`.',
      );
    }
    if (expected is Stream) {
      throw ArgumentError(
        '`thenReturn` should not be used to return a Stream. '
        'Instead, use `thenAnswer((_) => stream)`.',
      );
    }
    return _completeWhen((_) => expected);
  }

  /// Store an exception to throw when this method stub is called.
  void thenThrow(Object throwable) {
    return _completeWhen((Invocation _) {
      // ignore: only_throw_errors
      throw throwable;
    });
  }

  /// Store a function which is called when this method stub is called.
  ///
  /// The function will be called, and the return value will be returned.
  void thenAnswer(Answer<T> answer) {
    return _completeWhen(answer);
  }

  void _completeWhen(Answer<T> answer) {
    if (_whenCall == null) {
      throw StateError(
        'No method stub was called from within `when()`. Was a real method '
        'called, or perhaps an extension method?',
      );
    }
    _whenCall!._setExpected<T>(answer);
    _whenCall = null;
    _whenInProgress = false;
  }
}

class _WhenCall {
  _WhenCall(this.mock, this.whenInvocation);

  final Mock mock;
  final Invocation whenInvocation;

  void _setExpected<T>(Answer<T> answer) {
    mock._setExpected(Expectation<T>(isInvocation(whenInvocation), answer));
  }
}

/// Returns a value dependent on the details of an [invocation].
typedef Answer<T> = T Function(Invocation invocation);

/// {@template expectation}
/// A captured method or property accessor -> a function that returns a value.
/// {@endtemplate}
class Expectation<T> {
  /// {@macro expectation}
  const Expectation(this.call, this.response);

  /// {@macro expectation}
  const Expectation.allInvocations(this.response)
      : call = const TypeMatcher<Invocation>();

  /// A captured method or property accessor.
  final Matcher call;

  /// Result function that should be invoked.
  final Answer<T> response;

  @override
  String toString() => '$Expectation {$call -> $response}';
}

/// Verify that a method on a mock object was called with the given arguments.
///
/// Call a method on a mock object within the call to `verify`. For example:
///
/// ```dart
/// cat.eatFood("chicken");
/// verify(() => cat.eatFood("fish"));
/// ```
///
/// Mocktail will fail the current test case if `cat.eatFood` hasn't been called
/// with `"fish"`. Optionally, call `called` on the result, to verify that the
/// method was called a certain number of times. For example:
///
/// ```dart
/// verify(() => cat.eatFood("fish")).called(2);
/// verify(() => cat.eatFood("fish")).called(greaterThan(3));
/// ```
///
/// Note: When mocktail verifies a method call, said call is then excluded from
/// further verifications. A single method call cannot be verified from multiple
/// calls to `verify`, or `verifyInOrder`. See more details in the FAQ.
///
/// Note: because of an unintended limitation, `verify(...).called(0);` will
/// not work as expected. Please use `verifyNever(...);` instead.
///
/// See also: [verifyNever], [verifyInOrder], [verifyZeroInteractions], and
/// [verifyNoMoreInteractions].
_Verify get verify => _makeVerify(false);

/// Verify that a method on a mock object was never called with the given
/// arguments.
///
/// Call a method on a mock object within a `verifyNever` call. For example:
///
/// ```dart
/// cat.eatFood("chicken");
/// verifyNever(() => cat.eatFood("fish"));
/// ```
///
/// Mocktail will pass the current test case, as `cat.eatFood` has not been
/// called with `"chicken"`.
_Verify get verifyNever => _makeVerify(true);

/// Verifies that a list of methods on a mock object have been called with the
/// given arguments. For example:
///
/// ```dart
/// verifyInOrder([
///   () => cat.eatFood("Milk"),
///   () => cat.sound(),
///   () => cat.eatFood(any),
/// ]);
/// ```
///
/// This verifies that `eatFood` was called with `"Milk"`, `sound` was called
/// with no arguments, and `eatFood` was then called with some argument.
///
/// Returns a list of verification results, one for each call which was
/// verified.
///
/// For example, if [verifyInOrder] is given these calls to verify:
///
/// ```dart
/// final verification = verifyInOrder([
///   () => cat.eatFood(captureAny),
///   () => cat.chew(),
///   () => cat.eatFood(captureAny),
/// ]);
/// ```
///
/// then `verification` is a list which contains a `captured` getter which
/// returns three lists:
///
/// 1. a list containing the argument passed to `eatFood` in the first
///    verified `eatFood` call,
/// 2. an empty list, as nothing was captured in the verified `chew` call,
/// 3. a list containing the argument passed to `eatFood` in the second
///    verified `eatFood` call.
///
/// Note: [verifyInOrder] only verifies that each call was made in the order
/// given, but not that those were the only calls. In the example above, if
/// other calls were made to `eatFood` or `sound` between the three given
/// calls, or before or after them, the verification will still succeed.
List<VerificationResult> Function<T>(
  List<T Function()> recordedInvocations,
) get verifyInOrder {
  if (_verifyCalls.isNotEmpty) {
    throw StateError(_verifyCalls.join());
  }
  _verificationInProgress = true;
  return <T>(List<T Function()> _) {
    for (final invocation in _) {
      if (invocation is Function) {
        try {
          invocation();
        } catch (_) {
          if (_ is! TypeError) rethrow;
        }
      }
    }

    _verificationInProgress = false;
    final verificationResults = <VerificationResult>[];
    final tmpVerifyCalls = List<_VerifyCall>.from(_verifyCalls);
    var time = DateTime.fromMillisecondsSinceEpoch(0);
    _verifyCalls.clear();
    final matchedCalls = <RealCall>[];
    for (final verifyCall in tmpVerifyCalls) {
      try {
        final matched = verifyCall._findAfter(time);
        matchedCalls.add(matched.realCall);
        verificationResults.add(VerificationResult._(1, matched.capturedArgs));
        time = matched.realCall.timeStamp;
      } on StateError {
        final mocks = tmpVerifyCalls.map((vc) => vc.mock).toSet();
        final allInvocations = mocks
            .expand((m) => m._realCalls)
            .toList(growable: false)
              ..sort((inv1, inv2) => inv1.timeStamp.compareTo(inv2.timeStamp));
        var otherCalls = '';
        if (allInvocations.isNotEmpty) {
          otherCalls = " All calls: ${allInvocations.join(", ")}";
        }
        fail(
          'Matching call #${tmpVerifyCalls.indexOf(verifyCall)} '
          'not found.$otherCalls',
        );
      }
    }
    for (var call in matchedCalls) {
      call.verified = true;
    }
    return verificationResults;
  };
}

/// Ensure no redundant invocations occur.
void verifyNoMoreInteractions(dynamic mock) {
  if (mock is Mock) {
    final unverified = mock._realCalls.where((inv) => !inv.verified).toList();
    if (unverified.isNotEmpty) {
      fail('No more calls expected, but following found: ${unverified.join()}');
    }
  } else {
    _throwMockArgumentError('verifyNoMoreInteractions', mock);
  }
}

/// Ensure interactions never happened on a [mock].
void verifyZeroInteractions(dynamic mock) {
  if (mock is Mock) {
    if (mock._realCalls.isNotEmpty) {
      fail(
        '''No interaction expected, but following found: ${mock._realCalls.join()}''',
      );
    }
  } else {
    _throwMockArgumentError('verifyZeroInteractions', mock);
  }
}

/// {@template list_of_verification_result}
/// Returns the list of argument lists which were captured within
/// [verifyInOrder].
/// {@endtemplate}
extension ListOfVerificationResult on List<VerificationResult> {
  /// {@macro list_of_verification_result}
  List<List<dynamic>> get captured => [...map((result) => result.captured)];
}

void _throwMockArgumentError(String method, dynamic nonMockInstance) {
  if (nonMockInstance == null) {
    throw ArgumentError('$method was called with a null argument');
  }
  throw ArgumentError('$method must only be given a Mock object');
}

_Verify _makeVerify(bool never) {
  if (_verifyCalls.isNotEmpty) {
    var message = 'Verification appears to be in progress.';
    if (_verifyCalls.length == 1) {
      message =
          '$message One verify call has been stored: ${_verifyCalls.single}';
    } else {
      message =
          '$message ${_verifyCalls.length} verify calls have been stored. '
          '[${_verifyCalls.first}, ..., ${_verifyCalls.last}]';
    }
    throw StateError(message);
  }
  if (_verificationInProgress) {
    fail(
      'There is already a verification in progress, '
      'check if it was not called with a verify argument(s)',
    );
  }
  _verificationInProgress = true;
  return <T>(T Function() mock) {
    try {
      mock();
    } catch (_) {
      if (_ is! TypeError) rethrow;
    }
    _verificationInProgress = false;
    if (_verifyCalls.length == 1) {
      var verifyCall = _verifyCalls.removeLast();
      var result = VerificationResult._(verifyCall.matchingInvocations.length,
          verifyCall.matchingCapturedArgs);
      verifyCall._checkWith(never);
      return result;
    } else {
      fail('Used on a non-mocktail object');
    }
  };
}

typedef _Verify = VerificationResult Function<T>(
  T Function() matchingInvocations,
);

/// Information about a stub call verification.
///
/// This class is most useful to users in two ways:
///
/// * verifying call count, via [called],
/// * collecting captured arguments, via [captured].
class VerificationResult {
  VerificationResult._(this.callCount, this._captured);

  final List<dynamic> _captured;

  /// List of all arguments captured in real calls.
  ///
  /// This list will include any captured default arguments and has no
  /// structure differentiating the arguments of one call from another. Given
  /// the following class:
  ///
  /// ```dart
  /// class C {
  ///   String methodWithPositionalArgs(int x, [int y]) => '';
  ///   String methodWithTwoNamedArgs(int x, {int y, int z}) => '';
  /// }
  /// ```
  ///
  /// the following stub calls will result in the following captured arguments:
  ///
  /// ```dart
  /// mock.methodWithPositionalArgs(1);
  /// mock.methodWithPositionalArgs(2, 3);
  /// var captured = verify(
  ///   () => mock.methodWithPositionalArgs(
  ///     captureAny(), captureAny(),
  ///    )
  /// ).captured;
  /// print(captured); // Prints "[1, null, 2, 3]"
  ///
  /// mock.methodWithTwoNamedArgs(1, y: 42, z: 43);
  /// mock.methodWithTwoNamedArgs(1, y: 44, z: 45);
  /// var captured = verify(
  ///     () => mock.methodWithTwoNamedArgs(
  ///       any(),
  ///       y: captureAny(named: 'y'),
  ///       z: captureAny(named: 'z'),
  ///     ),
  /// ).captured;
  /// print(captured); // Prints "[42, 43, 44, 45]"
  /// ```
  // ignore: unnecessary_getters_setters
  List<dynamic> get captured => _captured;

  /// The number of calls matched in this verification.
  int callCount;

  /// Assert that the number of calls matches [matcher].
  ///
  /// Examples:
  ///
  /// * `verify(mock.m()).called(1)` asserts that `m()` is called exactly once.
  /// * `verify(mock.m()).called(greaterThan(2))` asserts that `m()` is called
  ///   more than two times.
  ///
  /// To assert that a method was called zero times, use [verifyNever].
  void called(dynamic matcher) {
    expect(
      callCount,
      wrapMatcher(matcher),
      reason: 'Unexpected number of calls',
    );
  }
}

class _UntilCall {
  _UntilCall(this._mock, Invocation invocation)
      : _invocationMatcher = InvocationMatcher(invocation);
  final InvocationMatcher _invocationMatcher;
  final Mock _mock;

  bool _matchesInvocation(RealCall realCall) =>
      _invocationMatcher.matches(realCall.invocation);

  List<RealCall> get _realCalls => _mock._realCalls;

  Future<Invocation> get invocationFuture {
    if (_realCalls.any(_matchesInvocation)) {
      return Future.value(_realCalls.firstWhere(_matchesInvocation).invocation);
    }

    return _mock._invocationStreamController.stream
        .firstWhere(_invocationMatcher.matches);
  }
}

/// Print all collected invocations of any mock methods of [mocks].
void logInvocations(List<Mock> mocks) {
  mocks.expand((m) => m._realCalls).toList(growable: false)
    ..sort((inv1, inv2) => inv1.timeStamp.compareTo(inv2.timeStamp))
    ..forEach((inv) {
      print(inv.toString());
    });
}

/// Reset the state of Mocktail, typically for use between tests.
///
/// For example, when using the test package, mock methods may accumulate calls
/// in a `setUp` method, making it hard to verify method calls that were made
/// _during_ an individual test. Or, there may be unverified calls from previous
/// test cases that should not affect later test cases.
///
/// In these cases, [resetMocktailState] might be called at the end of `setUp`,
/// or in `tearDown`.
void resetMocktailState() {
  _whenInProgress = false;
  _untilCalledInProgress = false;
  _verificationInProgress = false;
  _whenCall = null;
  _untilCall = null;
  _verifyCalls.clear();
  _capturedArgs.clear();
  _storedArgs.clear();
  _storedNamedArgs.clear();
}

/// Clear stubs of, and collected interactions with [mock].
void reset(dynamic mock) {
  if (mock is Mock) {
    mock._realCalls.clear();
    mock._responses.clear();
  } else {
    _throwMockArgumentError('reset', mock);
  }
}

/// Clear the collected interactions with [mock].
void clearInteractions(dynamic mock) {
  if (mock is Mock) {
    mock._realCalls.clear();
  } else {
    _throwMockArgumentError('clearInteractions', mock);
  }
}

class _VerifyCall {
  _VerifyCall._(
    this.mock,
    this.verifyInvocation,
    this.matchingInvocations,
    this.matchingCapturedArgs,
  );

  factory _VerifyCall(Mock mock, Invocation verifyInvocation) {
    final expectedMatcher = InvocationMatcher(verifyInvocation);
    final matchingInvocations = <RealCallWithCapturedArgs>[];
    for (final realCall in mock._realCalls) {
      if (!realCall.verified && expectedMatcher.matches(realCall.invocation)) {
        matchingInvocations.add(
          RealCallWithCapturedArgs(realCall, [..._capturedArgs]),
        );
        _capturedArgs.clear();
      }
    }

    final matchingCapturedArgs = [
      for (final invocation in matchingInvocations) ...invocation.capturedArgs,
    ];

    return _VerifyCall._(
      mock,
      verifyInvocation,
      matchingInvocations,
      matchingCapturedArgs,
    );
  }

  final Mock mock;
  final Invocation verifyInvocation;
  final List<RealCallWithCapturedArgs> matchingInvocations;
  final List<Object?> matchingCapturedArgs;

  RealCallWithCapturedArgs _findAfter(DateTime time) {
    return matchingInvocations.firstWhere((invocation) =>
        !invocation.realCall.verified &&
        invocation.realCall.timeStamp.isAfter(time));
  }

  void _checkWith(bool never) {
    if (!never && matchingInvocations.isEmpty) {
      String message;
      if (mock._realCalls.isEmpty) {
        message = 'No matching calls (actually, no calls at all).';
      } else {
        var otherCalls = mock._realCallsToString();
        message = 'No matching calls. All calls: $otherCalls';
      }
      fail('$message\n'
          '(If you called `verify(...).called(0);`, please instead use '
          '`verifyNever(...);`.)');
    }
    if (never && matchingInvocations.isNotEmpty) {
      var calls = mock._unverifiedCallsToString();
      fail('Unexpected calls: $calls');
    }
    for (var invocation in matchingInvocations) {
      invocation.realCall.verified = true;
    }
  }

  @override
  String toString() =>
      'VerifyCall<mock: $mock, memberName: ${verifyInvocation.memberName}>';
}

/// Returns a future [Invocation] that will complete upon the first occurrence
/// of the given invocation.
///
/// Usage of this is as follows:
///
/// ```dart
/// cat.eatFood("fish");
/// await untilCalled(cat.chew());
/// ```
///
/// In the above example, the untilCalled(cat.chew()) will complete only when
/// that method is called. If the given invocation has already been called, the
/// future will return immediately.
Future<Invocation> Function<T>(T Function() _) get untilCalled {
  _untilCalledInProgress = true;
  return <T>(T Function() _) {
    try {
      _();
    } catch (_) {
      if (_ is! TypeError) rethrow;
    }
    _untilCalledInProgress = false;
    return _untilCall!.invocationFuture;
  };
}
