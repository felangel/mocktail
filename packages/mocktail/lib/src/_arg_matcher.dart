part of 'mocktail.dart';

/// {@template arg_matcher}
/// An argument matcher which is used to implement `any`, `captureAny`, etc.
/// {@endtemplate}
class ArgMatcher {
  /// {@macro arg_matcher}
  const ArgMatcher(this.matcher, this._capture);

  /// The [Matcher] instance.
  final Matcher matcher;

  /// Whether to capture the arg.
  final bool _capture;

  @override
  String toString() => '$ArgMatcher {$matcher: $_capture}';
}
