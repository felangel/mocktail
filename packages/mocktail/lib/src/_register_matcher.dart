part of 'mocktail.dart';

Type _typeof<T>() => T;

Never _fallbackCallback([
  Object? a1,
  Object? a2,
  Object? a3,
  Object? a4,
  Object? a5,
  Object? a6,
  Object? a7,
  Object? a8,
  Object? a9,
  Object? a10,
  Object? a11,
  Object? a12,
  Object? a13,
  Object? a14,
  Object? a15,
  Object? a16,
  Object? a17,
  Object? a18,
  Object? a19,
  Object? a20,
]) {
  throw UnsupportedError(
    '''
A test tried to call mocktail's internal dummy callback.
This dummy callback is only meant to be passed around, but never called.''',
  );
}

List<Object?> _fallbackValues = [
  false,
  42,
  42.0,
  '42',
  const <Never>[],
  const <Never, Never>{},
  const <Never>{},
  DateTime(42),
  _fallbackCallback,
];

T _getFallbackValue<T>() {
  final value = _fallbackValues.firstWhereOrNull((element) => element is T);
  if (value is! T) {
    throw StateError('''
A test tried to use `any` or `captureAny` on a parameter of type `$T`, but
registerFallbackValue was not previously called to register a fallback value for `$T`.

To fix, do:

```
void main() {
  setUpAll(() {
    registerFallbackValue(/* create a dummy instance of `$T` */);
  });
}
```

This instance of `$T` will only be passed around, but never be interacted with.
Therefore, if `$T` is a function, it does not have to return a valid object and
could throw unconditionally.
If you cannot easily create an instance of `$T`, consider defining a `Fake`:

```
class MyTypeFake extends Fake implements MyType {}

void main() {
  setUpAll(() {
    registerFallbackValue(MyTypeFake());
  });
}
```

Fallbacks are required because mocktail has to know of a valid `$T` to prevent
TypeErrors from being thrown in Dart's sound null safe mode, while still
providing a convenient syntax.
''');
  }
  return value;
}

/// Allows [any] and [captureAny] to be used on parameters of type [value].
///
/// It is necessary for tests to call [registerFallbackValue] before using
/// [any]/[captureAny] because otherwise it would not be possible to assign
/// [any]/[captureAny] as value to a non-nullable parameter.
///
/// Mocktail comes with already pre-registered values, for types such as [int],
/// [String] and more.
///
/// Once registered, a value cannot be unregistered, even when using
/// [resetMocktailState].
///
/// It is a good practice to create a function shared between all tests that
/// calls [registerFallbackValue] with various types used in the project.
void registerFallbackValue(dynamic value) => _fallbackValues.add(value);

/// If there are multiple custom objects that need to be registered with
/// [registerFallbackValue], then instead of calling [registerFallbackValue]
/// multiple times, we can use [registerMultipleFallbackValues] allowing us to
/// do something like
/// ```dart
/// setUpAll(() {
///   registerMultipleFallbackValues([FakeObj1(), FakeObj2(), FakeObj3()]);
/// });
/// ```
/// instead of
/// ```dart
/// setUpAll(() {
///   registerFallbackValue(FakeObj1());
///   registerFallbackValue(FakeObj2());
///   registerFallbackValue(FakeObj3());
/// });
/// ```
void registerMultipleFallbackValues(List<dynamic> values) {
  for (final value in values) registerFallbackValue(value);
}

/// An argument matcher that matches any argument passed in.
T any<T>({String? named, Matcher? that}) {
  return _registerMatcher(
    that ?? anything,
    capture: false,
    named: named,
    argumentMatcher: named != null ? 'anyNamed' : 'any',
  );
}

/// An argument matcher that captures any argument passed in.
T captureAny<T>({String? named, Matcher? that}) {
  return _registerMatcher(
    that ?? anything,
    capture: true,
    named: named,
    argumentMatcher: named != null ? 'anyNamed' : 'any',
  );
}

/// Registers [matcher] into the stored arguments collections.
///
/// Creates an [ArgMatcher] with [matcher] and [capture], then if [named] is
/// null, stores that into the positional stored arguments list; otherwise
/// stores it into the named stored arguments map, keyed on [named].
/// [argumentMatcher] is the name of the public API used to register [matcher],
/// for error messages.
T _registerMatcher<T>(
  Matcher matcher, {
  required bool capture,
  String? named,
  String? argumentMatcher,
}) {
  if (!_whenInProgress && !_untilCalledInProgress && !_verificationInProgress) {
    // It is not meaningful to store argument matchers outside of stubbing
    // (`when`), or verification (`verify` and `untilCalled`). Such argument
    // matchers will be processed later erroneously.
    _storedArgs.clear();
    _storedNamedArgs.clear();
    throw ArgumentError(
      'The "$argumentMatcher" argument matcher is used outside of method '
      '''stubbing (via `when`) or verification (via `verify` or `untilCalled`). '''
      'This is invalid, and results in bad behavior during the next stubbing '
      'or verification.',
    );
  }

  if (T == _typeof<T?>()) {
    // T is nullable, so we can safely return `null`
    final argMatcher = ArgMatcher(matcher, null, capture);
    if (named == null) {
      _storedArgs.add(argMatcher);
    } else {
      _storedNamedArgs[named] = argMatcher;
    }
    return null as T;
  }

  final fallbackValue = _getFallbackValue<T>();
  final argMatcher = ArgMatcher(matcher, fallbackValue, capture);
  if (named == null) {
    _storedArgs.add(argMatcher);
  } else {
    _storedNamedArgs[named] = argMatcher;
  }

  return fallbackValue;
}
