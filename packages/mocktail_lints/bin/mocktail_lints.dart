import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => _MocktailLint();

class _MocktailLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        PreferPrivateMocks(),
      ];
}

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
      final superclass = node.extendsClause?.superclass;
      if (element == null || superclass == null) return;

      final isPublicMock =
          superclass.name.name == 'Mock' && !element.name.startsWith('_');
      if (isPublicMock) {
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
        message: 'Make Mock final',
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
