import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class Foo {
  int get intValue => 0;
  Map<String, String> get mapValue => {'foo': 'bar'};
  Future<int> asyncValue() => Future.value(1);
  Future<int> asyncValueWithPositionalArg(int x) => Future.value(x);
  Future<int> asyncValueWithPositionalArgs(int x, int y) => Future.value(x + y);
  Future<int> asyncValueWithNamedArg({required int x}) => Future.value(x);
  Future<int> asyncValueWithNamedArgs({required int x, required int y}) =>
      Future.value(x + y);
  Future<int> asyncValueWithNamedAndPositionalArgs(int x, {required int y}) =>
      Future.value(x + y);
  Stream<int> get streamValue => Stream.value(0);
  int increment(int x) => x + 1;
  int addOne(int x) => x + 1;
  void voidFunction() {}
  void voidWithOptionalPositionalArg([int? x]) {}
  void voidWithOptionalNamedArg({int? x}) {}
  void voidWithDefaultPositionalArg([int x = 0]) {}
  void voidWithDefaultNamedArg({int x = 0}) {}
  void voidWithPositionalAndOptionalNamedArg(int x, {int? y}) {}
}

class Bar {
  const Bar(this.foo);
  final Foo foo;
}

class Baz<T> {
  void add(T element) {}
}

class MockFoo extends Mock implements Foo {}

class MockBar extends Mock implements Bar {}

class MockBaz<T> extends Mock implements Baz<T> {
  static const _unimplemented = Object();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    try {
      final dynamic result = super.noSuchMethod(invocation);
      return result;
    } on NoSuchMethodError {
      final dynamic result = _noSuchMethod(invocation);
      if (result == _unimplemented) rethrow;
      return result;
    }
  }

  dynamic _noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #add:
        return (T element) {}(invocation.positionalArguments.first as T);
      default:
        return _unimplemented;
    }
  }
}

void main() {
  group('Foo', () {
    late Foo foo;

    setUp(() {
      foo = MockFoo();
    });

    tearDown(resetMocktailState);

    test('verify supports matchers', () {
      when(() => foo.intValue).thenReturn(10);
      expect(foo.intValue, 10);
      verify(() => foo.intValue).called(equals(1));
    });

    test('verifyNever supported', () {
      verifyNever(() => foo.intValue);
    });

    test('when value (int)', () {
      when(() => foo.intValue).thenReturn(10);
      expect(foo.intValue, 10);
      verify(() => foo.intValue).called(1);
    });

    test('when value (map)', () {
      when(() => foo.mapValue).thenReturn({'hello': 'world'});
      expect(foo.mapValue, {'hello': 'world'});
    });

    test('when asyncValue', () async {
      when(() => foo.asyncValue()).thenAnswer((_) async => 10);
      expect(await foo.asyncValue(), 10);
    });

    test('when asyncValueWithPositionalArg (any)', () async {
      when(() => foo.asyncValueWithPositionalArg(any(type: 0))).thenAnswer(
        (_) async => 10,
      );
      expect(await foo.asyncValueWithPositionalArg(1), 10);
      verify(() => foo.asyncValueWithPositionalArg(1)).called(1);
    });

    test('when asyncValueWithPositionalArg multiple times', () async {
      when(() => foo.asyncValueWithPositionalArg(any(type: 0))).thenAnswer(
        (_) async => 10,
      );
      expect(await foo.asyncValueWithPositionalArg(1), 10);
      expect(await foo.asyncValueWithPositionalArg(1), 10);
      verify(() => foo.asyncValueWithPositionalArg(1)).called(2);
    });

    test('when asyncValueWithPositionalArg (custom matcher)', () async {
      final isEven = isA<int>().having((x) => x % 2 == 0, 'isEven', true);
      when(() => foo.asyncValueWithPositionalArg(any(that: isEven, type: 0)))
          .thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithPositionalArg(2), 10);
      verify(() => foo.asyncValueWithPositionalArg(2)).called(1);
    });

    test('when asyncValueWithPositionalArg (any)', () async {
      when(() => foo.asyncValueWithPositionalArg(any(type: 0)))
          .thenAnswer((_) async => 10);
      when(() => foo.asyncValueWithPositionalArg(1))
          .thenAnswer((_) async => 42);
      expect(await foo.asyncValueWithPositionalArg(1), 42);
      expect(await foo.asyncValueWithPositionalArg(2), 10);
      verify(() => foo.asyncValueWithPositionalArg(1)).called(1);
    });

    test('when asyncValueWithPositionalArgs (any)', () async {
      when(() => foo.asyncValueWithPositionalArgs(any(type: 0), any(type: 0)))
          .thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithPositionalArgs(1, 2), 10);
      verify(() => foo.asyncValueWithPositionalArgs(1, 2)).called(1);
    });

    test('when asyncValueWithPositionalArgs (1 any matcher)', () async {
      when(() => foo.asyncValueWithPositionalArgs(any(type: 0), 2))
          .thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithPositionalArgs(1, 2), 10);
      verify(() => foo.asyncValueWithPositionalArgs(1, 2)).called(1);
    });

    test('when asyncValueWithPositionalArgs (2 any matchers)', () async {
      when(() => foo.asyncValueWithPositionalArgs(any(type: 0), any(type: 0)))
          .thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithPositionalArgs(1, 2), 10);
      verify(() => foo.asyncValueWithPositionalArgs(1, 2)).called(1);
    });

    test('when asyncValueWithPositionalArgs (explicit)', () async {
      when(() => foo.asyncValueWithPositionalArgs(1, 2))
          .thenAnswer((_) async => 42);
      expect(await foo.asyncValueWithPositionalArgs(1, 2), 42);
      expect(await foo.asyncValueWithPositionalArgs(1, 2), 42);
      verify(() => foo.asyncValueWithPositionalArgs(1, 2)).called(2);
    });

    test('when asyncValueWithNamedArg (any)', () async {
      when(
        () => foo.asyncValueWithNamedArg(x: any(type: 0, named: 'x')),
      ).thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedArg(x: 1), 10);
      verify(() => foo.asyncValueWithNamedArg(x: 1)).called(1);
    });

    test('when asyncValueWithNamedArg (custom matcher)', () async {
      final isOdd = isA<int>().having((x) => x % 2 == 0, 'isOdd', false);
      when(
        () => foo.asyncValueWithNamedArg(
          x: any(type: 0, that: isOdd, named: 'x'),
        ),
      ).thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedArg(x: 1), 10);
      verify(() => foo.asyncValueWithNamedArg(x: 1)).called(1);
    });

    test('when asyncValueWithNamedArg', () async {
      when(() => foo.asyncValueWithNamedArg(x: 1)).thenAnswer((_) async => 42);
      expect(await foo.asyncValueWithNamedArg(x: 1), 42);
      verify(() => foo.asyncValueWithNamedArg(x: 1)).called(1);
    });

    test('when asyncValueWithNamedArgs', () async {
      when(() => foo.asyncValueWithNamedArgs(x: 1, y: 2))
          .thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedArgs(x: 1, y: 2), 10);
      verify(() => foo.asyncValueWithNamedArgs(x: 1, y: 2)).called(1);
    });

    test('when asyncValueWithNamedArgs (1 any matchers)', () async {
      when(() => foo.asyncValueWithNamedArgs(x: any(type: 0, named: 'x'), y: 2))
          .thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedArgs(x: 1, y: 2), 10);
      verify(() => foo.asyncValueWithNamedArgs(x: 1, y: 2)).called(1);
    });

    test('when asyncValueWithNamedArgs (2 any matchers)', () async {
      when(
        () => foo.asyncValueWithNamedArgs(
          x: any(type: 0, named: 'x'),
          y: any(type: 0, named: 'y'),
        ),
      ).thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedArgs(x: 1, y: 2), 10);
      verify(() => foo.asyncValueWithNamedArgs(x: 1, y: 2)).called(1);
    });

    test('when asyncValueWithNamedAndPositionalArgs (any)', () async {
      when(() => foo.asyncValueWithNamedAndPositionalArgs(1, y: 2))
          .thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedAndPositionalArgs(1, y: 2), 10);
      verify(() => foo.asyncValueWithNamedAndPositionalArgs(1, y: 2)).called(1);
    });

    test('invocation contains correct arguments', () async {
      late Iterable<Object?> positionalArguments;
      late Map<Symbol, dynamic> namedArguments;
      when(() => foo.asyncValueWithNamedAndPositionalArgs(1, y: 2))
          .thenAnswer((invocation) async {
        positionalArguments = invocation.positionalArguments;
        namedArguments = invocation.namedArguments;
        return 10;
      });
      expect(await foo.asyncValueWithNamedAndPositionalArgs(1, y: 2), 10);
      expect(positionalArguments, equals([1]));
      expect(namedArguments, equals({#y: 2}));
    });

    test('captureAny captures any positional argument', () async {
      when(() => foo.asyncValueWithPositionalArgs(1, 2))
          .thenAnswer((_) => Future.value(10));
      expect(await foo.asyncValueWithPositionalArgs(1, 2), 10);
      final captured = verify(() => foo.asyncValueWithPositionalArgs(
          captureAny(type: 0), captureAny(type: 0))).captured;
      expect(captured, equals([1, 2]));
    });

    test('captureAny captures any named argument', () async {
      when(() => foo.asyncValueWithNamedArgs(x: 1, y: 2))
          .thenAnswer((_) => Future.value(10));
      expect(await foo.asyncValueWithNamedArgs(x: 1, y: 2), 10);
      final captured = verify(
        () => foo.asyncValueWithNamedArgs(
          x: captureAny(type: 0, named: 'x'),
          y: captureAny(type: 0, named: 'y'),
        ),
      ).captured;
      expect(captured, equals([1, 2]));
    });

    test('captureAny captures any positional and named argument', () async {
      when(() => foo.asyncValueWithNamedAndPositionalArgs(1, y: 2))
          .thenAnswer((_) => Future.value(10));
      expect(await foo.asyncValueWithNamedAndPositionalArgs(1, y: 2), 10);
      final captured = verify(
        () => foo.asyncValueWithNamedAndPositionalArgs(
          captureAny(type: 0),
          y: captureAny(type: 0, named: 'y'),
        ),
      ).captured;
      expect(captured, equals([1, 2]));
    });

    test('captureAny captures any positional and named argument (multiple)',
        () async {
      when(
        () => foo.asyncValueWithNamedAndPositionalArgs(
          any(type: 0),
          y: any(type: 0, named: 'y'),
        ),
      ).thenAnswer((_) => Future.value(10));
      expect(await foo.asyncValueWithNamedAndPositionalArgs(1, y: 2), 10);
      expect(await foo.asyncValueWithNamedAndPositionalArgs(10, y: 42), 10);
      final captured = verify(
        () => foo.asyncValueWithNamedAndPositionalArgs(
          captureAny(type: 0),
          y: captureAny(type: 0, named: 'y'),
        ),
      ).captured;
      expect(
        captured,
        equals([1, 2, 10, 42]),
      );
    });

    test('when streamValue', () {
      when(() => foo.streamValue).thenAnswer((_) => Stream.value(42));
      expectLater(
        foo.streamValue,
        emitsInOrder(<Matcher>[equals(42), emitsDone]),
      );
      verify(() => foo.streamValue).called(1);
    });

    test('when voidFunction (explicit)', () {
      when(() => foo.voidFunction()).thenReturn(null);
      expect(() => foo.voidFunction(), returnsNormally);
      verify(() => foo.voidFunction()).called(1);
    });

    test('when voidWithPositionalAndOptionalNamedArg (default)', () {
      when(() => foo.voidWithPositionalAndOptionalNamedArg(10))
          .thenReturn(null);
      expect(
          () => foo.voidWithPositionalAndOptionalNamedArg(10), returnsNormally);
      verify(() => foo.voidWithPositionalAndOptionalNamedArg(10)).called(1);
    });

    test('when voidWithPositionalAndOptionalNamedArg (override)', () {
      when(() => foo.voidWithPositionalAndOptionalNamedArg(10, y: 42))
          .thenReturn(null);
      expect(
        () => foo.voidWithPositionalAndOptionalNamedArg(10, y: 42),
        returnsNormally,
      );
      verify(() => foo.voidWithPositionalAndOptionalNamedArg(10, y: 42))
          .called(1);
    });

    test('when voidWithOptionalPositionalArg (default)', () {
      when(() => foo.voidWithOptionalPositionalArg(any(type: 0)))
          .thenReturn(null);
      expect(() => foo.voidWithOptionalPositionalArg(1), returnsNormally);
      verify(() => foo.voidWithOptionalPositionalArg(1)).called(1);
    });

    test('when voidWithOptionalPositionalArg (override)', () {
      when(() => foo.voidWithOptionalPositionalArg(10)).thenReturn(null);
      expect(() => foo.voidWithOptionalPositionalArg(10), returnsNormally);
      verify(() => foo.voidWithOptionalPositionalArg(10)).called(1);
    });

    test('when voidWithOptionalNamedArg (default)', () {
      when(() => foo.voidWithOptionalNamedArg()).thenReturn(null);
      expect(() => foo.voidWithOptionalNamedArg(), returnsNormally);
      verify(() => foo.voidWithOptionalNamedArg()).called(1);
    });

    test('when voidWithOptionalNamedArg (override)', () {
      when(() => foo.voidWithOptionalNamedArg(x: 10)).thenReturn(null);
      expect(() => foo.voidWithOptionalNamedArg(x: 10), returnsNormally);
      verify(() => foo.voidWithOptionalNamedArg(x: 10)).called(1);
    });

    test('when voidWithDefaultPositionalArg (default)', () {
      when(() => foo.voidWithDefaultPositionalArg()).thenReturn(null);
      expect(() => foo.voidWithDefaultPositionalArg(), returnsNormally);
      verify(() => foo.voidWithDefaultPositionalArg()).called(1);
    });

    test('when voidWithDefaultPositionalArg (override)', () {
      when(() => foo.voidWithDefaultPositionalArg(10)).thenReturn(null);
      expect(() => foo.voidWithDefaultPositionalArg(10), returnsNormally);
      verify(() => foo.voidWithDefaultPositionalArg(10)).called(1);
    });

    test('when voidWithDefaultNamedArg (default)', () {
      when(() => foo.voidWithDefaultNamedArg()).thenReturn(null);
      expect(() => foo.voidWithDefaultNamedArg(), returnsNormally);
      verify(() => foo.voidWithDefaultNamedArg()).called(1);
    });

    test('when voidWithDefaultNamedArg (override)', () {
      when(() => foo.voidWithDefaultNamedArg(x: 10)).thenReturn(null);
      expect(() => foo.voidWithDefaultNamedArg(x: 10), returnsNormally);
      verify(() => foo.voidWithDefaultNamedArg(x: 10)).called(1);
    });

    test('throws Exception when thenThrow is used to stub the mock', () {
      final exception = Exception('oops');
      when(() => foo.streamValue).thenThrow(exception);
      expect(() => foo.streamValue, throwsA(exception));
    });

    test('throws TypeError when no stub exists', () {
      expect(() => foo.intValue, throwsA(isA<TypeError>()));
    });
  });

  group('Bar', () {
    late Foo foo;
    late Bar bar;

    setUp(() {
      foo = MockFoo();
      bar = MockBar();
      reset(foo);
      reset(bar);
    });

    tearDown(resetMocktailState);

    test('when foo (mocked dependency)', () {
      when(() => foo.intValue).thenReturn(42);
      when(() => bar.foo).thenReturn(foo);
      expect(bar.foo.intValue, 42);
    });
  });

  group('Baz', () {
    late Baz<String> baz;

    setUp(() {
      baz = MockBaz<String>();
    });

    tearDown(resetMocktailState);

    test('verify count strictly depends on both member name and arguments', () {
      when(() => baz.add(any(type: ''))).thenReturn(null);

      const arg1 = 'A';
      const arg2 = 'B';
      const arg3 = 'C';

      baz.add(arg1);

      verify(() => baz.add(arg1)).called(1);

      baz.add(arg2);

      verify(() => baz.add(arg2)).called(1);

      baz.add(arg3);

      verify(() => baz.add(arg3)).called(1);
    });

    test(
        'verify count strictly depends on both '
        'member name and arguments (multiple calls)', () {
      const arg1 = 'A';

      when(() => baz.add(any(type: ''))).thenReturn(null);

      verifyNever(() => baz.add(arg1));

      baz.add(arg1);

      verify(() => baz.add(arg1)).called(1);

      baz..add(arg1)..add(arg1);
      verify(() => baz.add(arg1)).called(2);

      baz..add(arg1)..add(arg1)..add(arg1);
      verify(() => baz.add(arg1)).called(3);
    });
  });
}
