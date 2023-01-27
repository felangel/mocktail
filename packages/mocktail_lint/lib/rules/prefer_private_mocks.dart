import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';

@visibleForTesting
const mocktailUri = 'package:mocktail/src/mocktail.dart';

class PreferPrivateMocks extends DartLintRule {
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

  @override
  List<Fix> getFixes() => [_PreferPrivateMocksFix()];
}

class _PreferPrivateMocksFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addClassDeclaration((ClassDeclaration node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Make Mock private.',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        final element = node.declaredElement;
        if (element == null) return;

        builder.addSimpleInsertion(element.nameOffset, '_');
      });
    });
  }
}
