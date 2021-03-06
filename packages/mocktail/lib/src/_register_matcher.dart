part of 'mocktail.dart';

/// An argument matcher that matches any argument passed in.
T any<T>({required T of, String? named, Matcher? that}) {
  return _registerMatcher(
    that ?? anything,
    of,
    false,
    named: named,
    argumentMatcher: named != null ? 'anyNamed' : 'any',
  );
}

/// An argument matcher that captures any argument passed in.
T captureAny<T>({required T of, String? named, Matcher? that}) {
  return _registerMatcher(
    that ?? anything,
    of,
    true,
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
  Matcher matcher,
  T defaultValue,
  bool capture, {
  String? named,
  String? argumentMatcher,
}) {
  if (!_whenInProgress && !_untilCalledInProgress && !_verificationInProgress) {
    // It is not meaningful to store argument matchers outside of stubbing
    // (`when`), or verification (`verify` and `untilCalled`). Such argument
    // matchers will be processed later erroneously.
    _storedArgs.clear();
    _storedNamedArgs.clear();
    _numMatchers = 0;
    throw ArgumentError(
        'The "$argumentMatcher" argument matcher is used outside of method '
        '''stubbing (via `when`) or verification (via `verify` or `untilCalled`). '''
        'This is invalid, and results in bad behavior during the next stubbing '
        'or verification.');
  }
  _numMatchers++;
  final argMatcher = ArgMatcher(matcher, capture);
  if (named == null) {
    _storedArgs.add(argMatcher);
  } else {
    _storedNamedArgs[named] = argMatcher;
  }
  return defaultValue;
}
