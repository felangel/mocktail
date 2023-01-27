import 'dart:io';
import 'package:custom_lint/custom_lint.dart';

Future<void> main() async {
  await customLint(workingDirectory: Directory.current.parent);
}
