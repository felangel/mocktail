import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// This object is a utility for checking whether a Dart variable is assignable
/// to a given class.
///
/// In this example, the class checked is `ProviderBase` from `package:riverpod`.
const _providerBaseChecker = TypeChecker.fromName(
  'ProviderBase',
  packageName: 'riverpod',
);

/// This is the entrypoint of our plugin.
/// All plugins must specify a `createPlugin` function in their `lib/<package_name>.dart` file
PluginBase createPlugin() => _RiverpodLint();

/// The class listing all the [LintRule]s and [Assist]s defined by our plugin.
class _RiverpodLint extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        PreferFinalProviders(),
      ];

  @override
  List<Assist> getAssists() => [_ConvertToStreamProvider()];
}

/// A custom lint rule.
/// In our case, we want a lint rule which analyzes a Dart file. Therefore we
/// subclass [DartLintRule].
///
/// For emitting lints on non-Dart files, subclass [LintRule].
class PreferFinalProviders extends DartLintRule {
  PreferFinalProviders() : super(code: _code);

  /// Metadata about the lint define. This is the code which will show-up in the IDE,
  /// and its description..
  static const _code = LintCode(
    name: 'riverpod_final_provider',
    problemMessage: 'Providers should be declared using the `final` keyword.',
  );

  /// The core logic for our custom lint rule.
  /// In our case, it will search over all variables defined in a Dart file and
  /// search for the ones that implement a specific type (see [__providerBaseChecker]).
  @override
  void run(
    // This object contains metadata about the analyzed file
    CustomLintResolver resolver,
    // ErrorReporter is for submitting lints. It contains utilities to specify
    // where the lint should show-up.
    ErrorReporter reporter,
    // This contains various utilities, including tools for inspecting the content
    // of Dart files in an efficient manner.
    CustomLintContext context,
  ) {
    // Using this function, we search for [VariableDeclaration] reference the
    // analyzed Dart file.
    context.registry.addVariableDeclaration((node) {
      final element = node.declaredElement;
      if (element == null ||
          element.isFinal ||
          // We check that the variable is a Riverpod provider
          !_providerBaseChecker.isAssignableFromType(element.type)) {
        return;
      }

      // This emits our lint warning at the location of the variable.
      reporter.reportErrorForElement(code, element);
    });
  }

  /// [LintRule]s can optionally specify a list of quick-fixes.
  ///
  /// Fixes will show-up in the IDE when the cursor is above the warning. And it
  /// should contain a message explaining how the warning will be fixed.
  @override
  List<Fix> getFixes() => [_MakeProviderFinalFix()];
}

/// We define a quick fix for an issue.
///
/// Our quick fix wants to analyze Dart files, so we subclass [DartFix].
/// Fox quick-fixes on non-Dart files, see [Fix].
class _MakeProviderFinalFix extends DartFix {
  /// Similarly to [LintRule.run], [Fix.run] is the core logic of a fix.
  /// It will take care or proposing edits within a file.
  @override
  void run(
    CustomLintResolver resolver,
    // Similar to ErrorReporter, ChangeReporter is an object used for submitting
    // edits within a Dart file.
    ChangeReporter reporter,
    CustomLintContext context,
    // This is the warning that was emitted by our [LintRule] and which we are
    // trying to fix.
    AnalysisError analysisError,
    // This is the other warnings in the same file defined by our [LintRule].
    // Useful in case we want to offer a "fix all" option.
    List<AnalysisError> others,
  ) {
    // Using similar logic as in "PreferFinalProviders", we inspect the Dart file
    // to search for variable declarations.
    context.registry.addVariableDeclarationList((node) {
      // We verify that the variable declaration is where our warning is located
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      // We define one edit, giving it a message which will show-up in the IDE.
      final changeBuilder = reporter.createChangeBuilder(
        message: 'Make provider final',
        // This represents how high-low should this qick-fix show-up in the list
        // of quick-fixes.
        priority: 1,
      );

      // Our edit will consist of editing a Dart file, so we invoke "addDartFileEdit".
      // The changeBuilder variable also has utilities for other types of files.
      changeBuilder.addDartFileEdit((builder) {
        final nodeKeyword = node.keyword;
        final nodeType = node.type;
        if (nodeKeyword != null) {
          // Replace "var x = ..." into "final x = ...""

          // Using "builder", we can emit changes to a file.
          // In this case, addSimpleReplacement is used to overrite a selection
          // with a new content.
          builder.addSimpleReplacement(
            SourceRange(nodeKeyword.offset, nodeKeyword.length),
            'final',
          );
        } else if (nodeType != null) {
          // Replace "Type x = ..." into "final Type x = ..."

          // Once again we emit an edit to our file.
          // But this time, we add new content without replacing existing content.
          builder.addSimpleInsertion(nodeType.offset, 'final ');
        }
      });
    });
  }
}

/// Using the same principle as we've seen before, we can define an "assist".
///
/// The main difference between an [Assist] and a [Fix] is that a [Fix] is associated
/// with a problem. While an [Assist] is a change without an associated problem.
///
/// These are commonly known as "refactoring".
class _ConvertToStreamProvider extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addVariableDeclaration((node) {
      // Check that the visited node is under the cursor
      if (!target.intersects(node.sourceRange)) return;

      // verify that the visited node is a provider, to only show the assist on providers
      final element = node.declaredElement;
      if (element == null ||
          element.isFinal ||
          !_providerBaseChecker.isAssignableFromType(element.type)) {
        return;
      }

      final changeBuilder = reporter.createChangeBuilder(
        priority: 1,
        message: 'Convert to StreamProvider',
      );
      changeBuilder.addDartFileEdit((builder) {
        // TODO implement change to refactor the provider
      });
    });
  }
}
