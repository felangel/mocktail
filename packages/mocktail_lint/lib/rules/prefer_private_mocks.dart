import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';

/// The URI of the mocktail package where the [Mock] class is defined.
///
/// Used to ensure that the lint only applies to mocks defined in mocktail.
@visibleForTesting
const mocktailUri = 'package:mocktail/src/mocktail.dart';

/// {@template mocktail_prefer_private_mocks}
/// A lint rule that enforces that mocks are declared private.
///
/// This is to ensure that mocks are not accidentally shared between test files,
/// since test files should remain isolated from each other (self-contained).
///
/// Do:
/// ```
/// class _MockDog extends Mock implementes Dog {}
/// ```
///
/// Don't:
/// ```
/// class MockDog extends Mock implementes Dog {}
/// ```
/// {@endtemplate}
class PreferPrivateMocks extends DartLintRule {
  /// {@macro mocktail_prefer_private_mocks}
  PreferPrivateMocks() : super(code: _code);

  static const _code = LintCode(
    name: 'mocktail_prefer_private_mocks',
    problemMessage:
        'Mocks should be declared private by using a leading underscore.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((ClassDeclaration node) {
      final element = node.declaredElement;
      if (element == null) return;

      final isMock = element.allSupertypes.any((interfaceType) =>
          interfaceType.element.name == '$Mock' &&
          interfaceType.element.source.uri.toString() == mocktailUri);
      final isPublic = !element.name.startsWith('_');
      if (isMock && isPublic) {
        reporter.reportErrorForNode(_code, node);
      }
    });
  }
}
