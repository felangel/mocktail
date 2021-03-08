part of 'mocktail.dart';

/// {@template arg_matcher}
/// An argument matcher which is used to implement `any`, `captureAny`, etc.
/// {@endtemplate}
class ArgMatcher<T> {
  /// {@macro arg_matcher}
  const ArgMatcher(this.matcher, this._fallbackValue, this._capture);

  /// The [Matcher] instance.
  final Matcher matcher;

  /// Whether to capture the arg.
  final bool _capture;

  /// Fallback value for null safety
  final T _fallbackValue;

  @override
  String toString() => '$ArgMatcher {$matcher: $_capture}';
}
