import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class Foo<T> {
  String positionalParameter(int x) => 'Real';
  String namedParameter({required int x}) => 'Real';
  String get getter => 'Real';
  int operator +(int arg) => arg + 1;
  String parameterWithDefault([int x = 0]) => 'Real';
  String? nullableMethod(int x) => 'Real';
  String? get nullableGetter => 'Real';
  String methodWithBarArg(Bar bar) => 'result';
  set setter(int value) {}
  Future<void> returnsFutureVoid() => Future.value();
}

class FooSub extends Foo<int> {}

class Bar {}

class MockFoo<T> extends Mock implements Foo<T> {}

class MockFooSub extends Mock implements FooSub {}

void main() {
  group('for a generated mock,', () {
    late MockFoo<Object> foo;
    late FooSub fooSub;

    setUp(() {
      foo = MockFoo();
      fooSub = MockFooSub();
    });

    test('a method with a positional parameter can be stubbed', () {
      when(() => foo.positionalParameter(42)).thenReturn('Stubbed');
      expect(foo.positionalParameter(42), equals('Stubbed'));
    });

    test('a method with a named parameter can be stubbed', () {
      when(() => foo.namedParameter(x: 42)).thenReturn('Stubbed');
      expect(foo.namedParameter(x: 42), equals('Stubbed'));
    });

    test('a getter can be stubbed', () {
      when(() => foo.getter).thenReturn('Stubbed');
      expect(foo.getter, equals('Stubbed'));
    });

    test('an operator can be stubbed', () {
      when(() => foo + 1).thenReturn(0);
      expect(foo + 1, equals(0));
    });

    test('a method with a parameter with a default value can be stubbed', () {
      when(() => foo.parameterWithDefault(42)).thenReturn('Stubbed');
      expect(foo.parameterWithDefault(42), equals('Stubbed'));

      when(() => foo.parameterWithDefault()).thenReturn('Default');
      expect(foo.parameterWithDefault(), equals('Default'));
    });

    test('an inherited method can be stubbed', () {
      when(() => fooSub.positionalParameter(42)).thenReturn('Stubbed');
      expect(fooSub.positionalParameter(42), equals('Stubbed'));
    });

    test('a setter can be called without stubbing', () {
      expect(() => foo.setter = 7, returnsNormally);
    });

    test(
        'a method with a non-nullable positional parameter accepts an argument '
        'matcher while stubbing', () {
      when(() => foo.positionalParameter(any(of: 0))).thenReturn('Stubbed');
      expect(foo.positionalParameter(42), equals('Stubbed'));
    });

    test(
        'a method with a non-nullable named parameter accepts an argument '
        'matcher while stubbing', () {
      when(
        () => foo.namedParameter(x: any(of: 0, named: 'x')),
      ).thenReturn('Stubbed');
      expect(foo.namedParameter(x: 42), equals('Stubbed'));
    });

    test(
        'a method with a non-nullable parameter accepts an argument matcher '
        'while verifying', () {
      when(() => foo.positionalParameter(any(of: 0))).thenReturn('Stubbed');
      foo.positionalParameter(42);
      expect(
        () => verify(() => foo.positionalParameter(any(of: 0))),
        returnsNormally,
      );
    });

    test('a method with a non-nullable parameter can capture an argument', () {
      when(() => foo.positionalParameter(any(of: 0))).thenReturn('Stubbed');
      foo.positionalParameter(42);
      final captured = verify(
        () => foo.positionalParameter(captureAny(of: 0)),
      ).captured;
      expect(captured[0], equals(42));
    });

    test('an unstubbed method throws', () {
      throwOnMissingStub(foo);
      when(() => foo.namedParameter(x: 42)).thenReturn('Stubbed');
      expect(
        () => foo.namedParameter(x: 43),
        throwsA(
          const TypeMatcher<MissingStubError>().having(
            (e) => e.toString(),
            'toString()',
            contains('namedParameter({x: 43})'),
          ),
        ),
      );
    });

    test('an unstubbed getter throws', () {
      throwOnMissingStub(foo);
      expect(
        () => foo.getter,
        throwsA(
          const TypeMatcher<MissingStubError>().having(
            (e) => e.toString(),
            'toString()',
            contains('getter'),
          ),
        ),
      );
    });
  });
}
