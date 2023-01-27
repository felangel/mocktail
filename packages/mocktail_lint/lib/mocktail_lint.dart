import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail_lint/rules/rules.dart';

PluginBase createPlugin() => _MocktailLint();

class _MocktailLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        PreferPrivateMocks(),
      ];
}
