import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mocktail_lint/rules/rules.dart';
import 'package:test/test.dart';

class _MockCustomLintResolver extends Mock implements CustomLintResolver {}

class _MockErrorReporter extends Mock implements ErrorReporter {}

class _MockCustomLintContext extends Mock implements CustomLintContext {}

class _MockLintRuleNodeRegistry extends Mock implements LintRuleNodeRegistry {}

class _MockClassDeclaration extends Mock implements ClassDeclaration {}

class _MockClassElement extends Mock implements ClassElement {}

class _MockInterfaceType extends Mock implements InterfaceType {}

class _MockInterfaceElement extends Mock implements InterfaceElement {}

class _MockSource extends Mock implements Source {}

class _MockUri extends Mock implements Uri {
  @override
  String toString() => path;
}

typedef _ClassDeclarationListener = void Function(ClassDeclaration node);

void main() {
  late CustomLintResolver resolver;
  late ErrorReporter reporter;
  late CustomLintContext context;
  late LintRuleNodeRegistry registry;

  setUp(() {
    registerFallbackValue((ClassDeclaration node) {});

    resolver = _MockCustomLintResolver();
    reporter = _MockErrorReporter();
    context = _MockCustomLintContext();
    registry = _MockLintRuleNodeRegistry();
    when(() => context.registry).thenReturn(registry);
  });

  test(
      'reportErrorForNode called when '
      '$ClassDeclaration is public and subclass of $Mock', () {
    final lint = PreferPrivateMocks();

    late _ClassDeclarationListener listener;
    when(() => registry.addClassDeclaration(any())).thenAnswer((invocation) {
      listener =
          invocation.positionalArguments.first as _ClassDeclarationListener;
    });
    lint.run(resolver, reporter, context);

    final ClassDeclaration classDeclaration = _MockClassDeclaration();
    final ClassElement classElement = _MockClassElement();
    when(() => classDeclaration.declaredElement).thenReturn(classElement);
    when(() => classElement.name).thenReturn('PublicName');

    final InterfaceType interfaceType = _MockInterfaceType();
    final InterfaceElement interfaceElement = _MockInterfaceElement();
    when(() => classElement.allSupertypes).thenReturn([interfaceType]);
    when(() => interfaceType.element).thenReturn(interfaceElement);
    when(() => interfaceElement.name).thenReturn('$Mock');

    final Source source = _MockSource();
    final Uri uri = _MockUri();
    when(() => interfaceElement.source).thenReturn(source);
    when(() => source.uri).thenReturn(uri);
    when(() => uri.path).thenReturn(mocktailUri);

    listener(classDeclaration);

    verify(() => reporter.reportErrorForNode(lint.code, classDeclaration))
        .called(1);
  });
}
