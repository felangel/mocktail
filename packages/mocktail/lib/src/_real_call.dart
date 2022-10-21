part of 'mocktail.dart';

/// {@template real_call}
/// A real invocation on a mock.
/// {@endtemplate}
class RealCall {
  /// {@macro real_call}
  RealCall(this.mock, this.invocation) : timeStamp = _timer.now();

  /// The mock instance.
  final Mock mock;

  /// The invocation.
  final Invocation invocation;

  /// When the invocation occurred.
  final DateTime timeStamp;

  /// Whether it was verified.
  bool verified = false;

  @override
  String toString() {
    final verifiedText = verified ? '[VERIFIED] ' : '';
    return '$verifiedText$mock.${invocation.toPrettyString()}';
  }
}

/// {@template real_call_with_captured_args}
/// A simple struct for storing a [RealCall] and any [capturedArgs] stored
/// during `InvocationMatcher.match`.
/// {@endtemplate}
class RealCallWithCapturedArgs {
  /// {@macro real_call_with_captured_args}
  const RealCallWithCapturedArgs(this.realCall, this.capturedArgs);

  /// The [RealCall] instance.
  final RealCall realCall;

  /// Any captured arguments.
  final List<Object?> capturedArgs;
}

extension on Invocation {
  /// Returns a pretty String representing a method (or getter or setter) call
  /// including its arguments, separating elements with newlines when it should
  /// improve readability.
  String toPrettyString() {
    String argString;
    final args = positionalArguments.map((dynamic v) => '$v');
    if (args.any((arg) => arg.contains('\n'))) {
      // As one or more arg contains newlines, put each on its own line, and
      // indent each, for better readability.
      argString =
          '''\n${args.map((arg) => arg.splitMapJoin('\n', onNonMatch: (m) => '    $m')).join(',\n')}''';
    } else {
      // A compact String should be perfect.
      argString = args.join(', ');
    }
    if (namedArguments.isNotEmpty) {
      if (argString.isNotEmpty) argString += ', ';
      var namedArgs = namedArguments.keys
          .map((key) => '${_symbolToString(key)}: ${namedArguments[key]}');
      if (namedArgs.any((arg) => arg.contains('\n'))) {
        // As one or more arg contains newlines, put each on its own line, and
        // indent each, for better readability.
        namedArgs = namedArgs
            .map((arg) => arg.splitMapJoin('\n', onNonMatch: (m) => '    $m'));
        argString += '{\n${namedArgs.join(',\n')}}';
      } else {
        // A compact String should be perfect.
        argString += '{${namedArgs.join(', ')}}';
      }
    }

    var method = _symbolToString(memberName);
    if (isMethod) {
      var typeArgsString = '';
      if (typeArguments.isNotEmpty) {
        typeArgsString = '<${typeArguments.join(', ')}>';
      }

      method = '$method$typeArgsString($argString)';
    } else if (isGetter) {
      method = method;
    } else if (isSetter) {
      method = '$method=$argString';
    } else {
      throw StateError('Invocation should be getter, setter or a method call.');
    }

    return method;
  }
}

// Converts a [Symbol] to a meaningful [String].
String _symbolToString(Symbol symbol) => symbol.toString().split('"')[1];
