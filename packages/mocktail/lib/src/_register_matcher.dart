part of 'mocktail.dart';

Type _typeof<T>() => T;

Map<Type, Object?> _createInitialFallbackValues() {
  final result = <Type, Object?>{};

  void createValue<T>(T value) {
    result[T] = value;
  }

  createValue<bool>(false);
  createValue<int>(42);
  createValue<double>(42);
  createValue<num>(42);
  createValue<String>('42');
  createValue<Object>('42');
  createValue<dynamic>('42');

  return result;
}

List<Object?> _genericFallbackValues = [
  const <Never>[],
  const <Never, Never>{},
  const <Never>{},
];

final _fallbackValues = _createInitialFallbackValues();

T _getFallbackValue<T>() {
  final value = _fallbackValues[T] ??
      _genericFallbackValues.firstWhereOrNull((element) => element is T);
  if (value is! T) {
    throw StateError('''
A test tried to use `any` or `captureAny` on a parameter of type `$T`, but
registerFallbackValue was not previously called to register a fallback value for `$T`

To fix, do:

```
void main() {
  setUpAll(() {
    registerFallbackValue<$T>($T());
  });
}
```

If you cannot easily create an instance of $T, consider defining a `Fake`:

```
class ${T}Fake extends Fake implements $T {}

void main() {
  setUpAll(() {
    registerFallbackValue<$T>(${T}Fake());
  });
}
```
''');
  }
  return value;
}

/// Allows [any] and [captureAny] to be used on parameters of type [T].
///
/// If [matchExactType] is set to true the fallback is only used for parameters
/// of exact type [T]. Otherwise it is used wherever possible.
/// Fallbacks registered with [matchExactType] set to true always take
/// precedence. Then, the first possible value registered with [matchExactType]
/// set to false is used.
///
///  It is necessary for tests to call  [registerFallbackValue] before using
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
void registerFallbackValue<T>(T value, {bool matchExactType = false}) {
  if (matchExactType) {
    _fallbackValues[T] = value;
  } else {
    _genericFallbackValues.add(value);
  }
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
/// non-null, stores that into the positional stored arguments list; otherwise
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
