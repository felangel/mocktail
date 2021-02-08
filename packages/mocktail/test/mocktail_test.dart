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

    tearDown(() {
      verifyMocks(foo);
    });

    test('verify supports matchers', () {
      verify(foo).called(#intValue).times(lessThan(1));
    });

    test('verify supports never', () {
      verify(foo).called(#intValue).never();
    });

    test('verify supports once', () {
      when(foo).calls(#intValue).thenReturn(10);
      expect(foo.intValue, 10);
      verify(foo).called(#intValue).once();
    });

    test('verify called 0 times (value)', () {
      verify(foo).called(#intValue).times(0);
    });

    test('when value (int)', () {
      when(foo).calls(#intValue).thenReturn(10);
      expect(foo.intValue, 10);
      verify(foo).called(#intValue).times(1);
    });

    test('when value (map)', () {
      when(foo).calls(#mapValue).thenReturn({'hello': 'world'});
      expect(foo.mapValue, {'hello': 'world'});
    });

    test('when asyncValue', () async {
      when(foo).calls(#asyncValue).thenAnswer((_) async => 10);
      expect(await foo.asyncValue(), 10);
    });

    test('when asyncValueWithPositionalArg (any)', () async {
      when(foo).calls(#asyncValueWithPositionalArg).thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithPositionalArg(1), 10);
      verify(foo).called(#asyncValueWithPositionalArg).times(1);
    });

    test('when asyncValueWithPositionalArg multiple times', () async {
      when(foo).calls(#asyncValueWithPositionalArg).thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithPositionalArg(1), 10);
      expect(await foo.asyncValueWithPositionalArg(1), 10);
      verify(foo)
          .called(#asyncValueWithPositionalArg)
          .withArgs(positional: [1]).times(2);
    });

    test('when asyncValueWithPositionalArg (custom matcher)', () async {
      final isEven = isA<int>().having((x) => x % 2 == 0, 'isEven', true);
      when(foo)
          .calls(#asyncValueWithPositionalArg)
          .withArgs(positional: [anyThat(isEven)]).thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithPositionalArg(2), 10);
      verify(foo).called(#asyncValueWithPositionalArg).times(1);
      verify(foo)
          .called(#asyncValueWithPositionalArg)
          .withArgs(positional: [anyThat(isEven)]).times(1);
    });

    test('when asyncValueWithPositionalArg (explicit)', () async {
      when(foo).calls(#asyncValueWithPositionalArg).thenAnswer((_) async => 10);
      when(foo)
          .calls(#asyncValueWithPositionalArg)
          .withArgs(positional: [1]).thenAnswer((_) async => 42);
      expect(await foo.asyncValueWithPositionalArg(1), 42);
      expect(await foo.asyncValueWithPositionalArg(2), 10);
      verify(foo).called(#asyncValueWithPositionalArg).times(2);
      verify(foo)
          .called(#asyncValueWithPositionalArg)
          .withArgs(positional: [1]).times(1);
      verify(foo)
          .called(#asyncValueWithPositionalArg)
          .withArgs(positional: [2]).times(1);
    });

    test('when asyncValueWithPositionalArgs (any)', () async {
      when(foo)
          .calls(#asyncValueWithPositionalArgs)
          .thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithPositionalArgs(1, 2), 10);
      verify(foo).called(#asyncValueWithPositionalArgs).times(1);
      verify(foo)
          .called(#asyncValueWithPositionalArgs)
          .withArgs(positional: [1, 2]).times(1);
    });

    test('when asyncValueWithPositionalArgs (1 any matcher)', () async {
      when(foo)
          .calls(#asyncValueWithPositionalArgs)
          .withArgs(positional: [any, 2]).thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithPositionalArgs(1, 2), 10);
      verify(foo).called(#asyncValueWithPositionalArgs).times(1);
      verify(foo)
          .called(#asyncValueWithPositionalArgs)
          .withArgs(positional: [1, 2]).times(1);
      verify(foo)
          .called(#asyncValueWithPositionalArgs)
          .withArgs(positional: [any, 2]).times(1);
      verify(foo)
          .called(#asyncValueWithPositionalArgs)
          .withArgs(positional: [any, any]).times(1);
    });

    test('when asyncValueWithPositionalArgs (2 any matchers)', () async {
      when(foo)
          .calls(#asyncValueWithPositionalArgs)
          .withArgs(positional: [any, any]).thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithPositionalArgs(1, 2), 10);
      verify(foo).called(#asyncValueWithPositionalArgs).times(1);
      verify(foo)
          .called(#asyncValueWithPositionalArgs)
          .withArgs(positional: [1, 2]).times(1);
      verify(foo)
          .called(#asyncValueWithPositionalArgs)
          .withArgs(positional: [any, any]).times(1);
    });

    test('when asyncValueWithPositionalArgs (explicit)', () async {
      when(foo)
          .calls(#asyncValueWithPositionalArgs)
          .thenAnswer((_) async => 10);
      when(foo)
          .calls(#asyncValueWithPositionalArgs)
          .withArgs(positional: [1, 2]).thenAnswer((_) async => 42);
      expect(await foo.asyncValueWithPositionalArgs(1, 2), 42);
      expect(await foo.asyncValueWithPositionalArgs(2, 4), 10);
      verify(foo).called(#asyncValueWithPositionalArgs).times(2);
      verify(foo)
          .called(#asyncValueWithPositionalArgs)
          .withArgs(positional: [1, 2]).times(1);
      verify(foo)
          .called(#asyncValueWithPositionalArgs)
          .withArgs(positional: [2, 4]).times(1);
    });

    test('when asyncValueWithNamedArg (any)', () async {
      when(foo).calls(#asyncValueWithNamedArg).thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedArg(x: 1), 10);
      verify(foo).called(#asyncValueWithNamedArg).times(1);
      verify(foo)
          .called(#asyncValueWithNamedArg)
          .withArgs(named: {#x: 1}).times(1);
    });

    test('when asyncValueWithNamedArg (custom matcher)', () async {
      final isOdd = isA<int>().having((x) => x % 2 == 0, 'isOdd', false);
      when(foo)
          .calls(#asyncValueWithNamedArg)
          .withArgs(named: {#x: anyThat(isOdd)}).thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedArg(x: 1), 10);
      verify(foo).called(#asyncValueWithNamedArg).times(1);
      verify(foo)
          .called(#asyncValueWithNamedArg)
          .withArgs(named: {#x: anyThat(isOdd)}).times(1);
    });

    test('when asyncValueWithNamedArg (explicit)', () async {
      when(foo).calls(#asyncValueWithNamedArg).thenAnswer((_) async => 10);
      when(foo)
          .calls(#asyncValueWithNamedArg)
          .withArgs(named: {#x: 1}).thenAnswer((_) async => 42);
      expect(await foo.asyncValueWithNamedArg(x: 1), 42);
      expect(await foo.asyncValueWithNamedArg(x: 2), 10);
      verify(foo).called(#asyncValueWithNamedArg).times(2);
      verify(foo)
          .called(#asyncValueWithNamedArg)
          .withArgs(named: {#x: 1}).times(1);
      verify(foo)
          .called(#asyncValueWithNamedArg)
          .withArgs(named: {#x: 2}).times(1);
    });

    test('when asyncValueWithNamedArgs (any)', () async {
      when(foo).calls(#asyncValueWithNamedArgs).thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedArgs(x: 1, y: 2), 10);
      verify(foo).called(#asyncValueWithNamedArgs).times(1);
      verify(foo)
          .called(#asyncValueWithNamedArgs)
          .withArgs(named: {#x: 1, #y: 2}).times(1);
    });

    test('when asyncValueWithNamedArgs (1 any matchers)', () async {
      when(foo)
          .calls(#asyncValueWithNamedArgs)
          .withArgs(named: {#x: any, #y: 2}).thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedArgs(x: 1, y: 2), 10);
      verify(foo).called(#asyncValueWithNamedArgs).times(1);
      verify(foo)
          .called(#asyncValueWithNamedArgs)
          .withArgs(named: {#x: 1, #y: 2}).times(1);
      verify(foo)
          .called(#asyncValueWithNamedArgs)
          .withArgs(named: {#x: any, #y: 2}).times(1);
      verify(foo)
          .called(#asyncValueWithNamedArgs)
          .withArgs(named: {#x: any, #y: any}).times(1);
    });

    test('when asyncValueWithNamedArgs (2 any matchers)', () async {
      when(foo)
          .calls(#asyncValueWithNamedArgs)
          .withArgs(named: {#x: any, #y: any}).thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedArgs(x: 1, y: 2), 10);
      verify(foo).called(#asyncValueWithNamedArgs).times(1);
      verify(foo)
          .called(#asyncValueWithNamedArgs)
          .withArgs(named: {#x: 1, #y: 2}).times(1);
      verify(foo)
          .called(#asyncValueWithNamedArgs)
          .withArgs(named: {#x: any, #y: any}).times(1);
    });

    test('when asyncValueWithNamedArgs (explicit)', () async {
      when(foo).calls(#asyncValueWithNamedArgs).thenAnswer((_) async => 10);
      when(foo)
          .calls(#asyncValueWithNamedArgs)
          .withArgs(named: {#x: 1, #y: 2}).thenAnswer((_) async => 42);
      expect(await foo.asyncValueWithNamedArgs(x: 1, y: 2), 42);
      expect(await foo.asyncValueWithNamedArgs(x: 2, y: 4), 10);
      verify(foo).called(#asyncValueWithNamedArgs).times(2);
      verify(foo)
          .called(#asyncValueWithNamedArgs)
          .withArgs(named: {#x: 1, #y: 2}).times(1);
      verify(foo)
          .called(#asyncValueWithNamedArgs)
          .withArgs(named: {#x: 2, #y: 4}).times(1);
    });

    test('when asyncValueWithNamedAndPositionalArgs (any)', () async {
      when(foo)
          .calls(#asyncValueWithNamedAndPositionalArgs)
          .thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedAndPositionalArgs(1, y: 2), 10);
      verify(foo).called(#asyncValueWithNamedAndPositionalArgs).times(1);
      verify(foo)
          .called(#asyncValueWithNamedAndPositionalArgs)
          .withArgs(positional: [1], named: {#y: 2}).times(1);
    });

    test('when asyncValueWithNamedAndPositionalArgs (explicit)', () async {
      when(foo)
          .calls(#asyncValueWithNamedAndPositionalArgs)
          .thenAnswer((_) async => 10);
      when(foo).calls(#asyncValueWithNamedAndPositionalArgs).withArgs(
          positional: [1], named: {#y: 2}).thenAnswer((_) async => 42);
      expect(await foo.asyncValueWithNamedAndPositionalArgs(1, y: 2), 42);
      expect(await foo.asyncValueWithNamedAndPositionalArgs(2, y: 4), 10);
      verify(foo).called(#asyncValueWithNamedAndPositionalArgs).times(2);
      verify(foo)
          .called(#asyncValueWithNamedAndPositionalArgs)
          .withArgs(positional: [1], named: {#y: 2}).times(1);
      verify(foo)
          .called(#asyncValueWithNamedAndPositionalArgs)
          .withArgs(positional: [2], named: {#y: 4}).times(1);
    });

    test('invocation contains correct arguments', () async {
      late Iterable<Object?> positionalArguments;
      late Map<Symbol, dynamic> namedArguments;
      when(foo)
          .calls(#asyncValueWithNamedAndPositionalArgs)
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
      when(foo)
          .calls(#asyncValueWithPositionalArgs)
          .thenReturn(Future.value(10));
      expect(await foo.asyncValueWithPositionalArgs(1, 2), 10);
      final captured = verify(foo)
          .called(#asyncValueWithPositionalArgs)
          .withArgs(positional: [captureAny, captureAny]).captured;
      expect(
        captured,
        equals([
          [1, 2]
        ]),
      );
    });

    test('captureAny captures any named argument', () async {
      when(foo).calls(#asyncValueWithNamedArgs).thenReturn(Future.value(10));
      expect(await foo.asyncValueWithNamedArgs(x: 1, y: 2), 10);
      final captured = verify(foo)
          .called(#asyncValueWithNamedArgs)
          .withArgs(named: {#x: captureAny, #y: captureAny}).captured;
      expect(
        captured,
        equals([
          [1, 2]
        ]),
      );
    });

    test('captureAny captures any positional and named argument', () async {
      when(foo)
          .calls(#asyncValueWithNamedAndPositionalArgs)
          .thenReturn(Future.value(10));
      expect(await foo.asyncValueWithNamedAndPositionalArgs(1, y: 2), 10);
      final captured = verify(foo)
          .called(#asyncValueWithNamedAndPositionalArgs)
          .withArgs(positional: [captureAny], named: {#y: captureAny}).captured;
      expect(
        captured,
        equals([
          [1, 2]
        ]),
      );
    });

    test('captureAny captures any positional and named argument (multiple)',
        () async {
      when(foo)
          .calls(#asyncValueWithNamedAndPositionalArgs)
          .thenReturn(Future.value(10));
      expect(await foo.asyncValueWithNamedAndPositionalArgs(1, y: 2), 10);
      expect(await foo.asyncValueWithNamedAndPositionalArgs(10, y: 42), 10);
      final captured = verify(foo)
          .called(#asyncValueWithNamedAndPositionalArgs)
          .withArgs(positional: [captureAny], named: {#y: captureAny}).captured;
      expect(
        captured,
        equals([
          [1, 2],
          [10, 42]
        ]),
      );
    });

    test('captureAnyThat captures positional and named argument (alternating)',
        () async {
      final isOdd = isA<int>().having((x) => x % 2 == 0, 'isOdd', false);
      final isEven = isA<int>().having((x) => x % 2 == 0, 'even', true);
      when(foo)
          .calls(#asyncValueWithNamedAndPositionalArgs)
          .thenReturn(Future.value(10));
      expect(await foo.asyncValueWithNamedAndPositionalArgs(1, y: 2), 10);
      expect(await foo.asyncValueWithNamedAndPositionalArgs(2, y: 3), 10);
      expect(await foo.asyncValueWithNamedAndPositionalArgs(3, y: 4), 10);
      final captured =
          verify(foo).called(#asyncValueWithNamedAndPositionalArgs).withArgs(
        positional: [captureAnyThat(isOdd)],
        named: {#y: captureAnyThat(isEven)},
      ).captured;
      expect(
        captured,
        equals([
          [1, 2],
          <int>[],
          [3, 4]
        ]),
      );
    });

    test('captureAnyThat captures positional and named argument (inverse)',
        () async {
      final isOdd = isA<int>().having((x) => x % 2 == 0, 'isOdd', false);
      final isEven = isA<int>().having((x) => x % 2 == 0, 'even', true);
      when(foo)
          .calls(#asyncValueWithNamedAndPositionalArgs)
          .thenReturn(Future.value(10));
      expect(await foo.asyncValueWithNamedAndPositionalArgs(1, y: 1), 10);
      expect(await foo.asyncValueWithNamedAndPositionalArgs(2, y: 2), 10);
      expect(await foo.asyncValueWithNamedAndPositionalArgs(3, y: 3), 10);
      final captured =
          verify(foo).called(#asyncValueWithNamedAndPositionalArgs).withArgs(
        positional: [captureAnyThat(isOdd)],
        named: {#y: captureAnyThat(isEven)},
      ).captured;
      expect(
        captured,
        equals([
          [1],
          [2],
          [3]
        ]),
      );
    });

    test('when streamValue', () {
      when(foo).calls(#streamValue).thenAnswer((_) => Stream.value(42));
      expectLater(
        foo.streamValue,
        emitsInOrder(<Matcher>[equals(42), emitsDone]),
      );
      verify(foo).called(#streamValue).times(1);
    });

    test('when voidFunction (explicit)', () {
      when(foo).calls(#voidFunction).thenReturn(null);
      expect(() => foo.voidFunction(), returnsNormally);
      verify(foo).called(#voidFunction).once();
    });

    test('when voidFunction (implicit)', () {
      when(foo).calls(#voidFunction).thenReturn();
      expect(() => foo.voidFunction(), returnsNormally);
      verify(foo).called(#voidFunction).once();
    });

    test('when voidWithPositionalAndOptionalNamedArg (default)', () {
      when(foo).calls(#voidWithPositionalAndOptionalNamedArg).thenReturn();
      expect(
          () => foo.voidWithPositionalAndOptionalNamedArg(10), returnsNormally);
      verify(foo).called(#voidWithPositionalAndOptionalNamedArg).once();
      verify(foo)
          .called(#voidWithPositionalAndOptionalNamedArg)
          .withArgs(positional: [10]).once();
    });

    test('when voidWithPositionalAndOptionalNamedArg (override)', () {
      when(foo).calls(#voidWithPositionalAndOptionalNamedArg).thenReturn();
      expect(() => foo.voidWithPositionalAndOptionalNamedArg(10, y: 42),
          returnsNormally);
      verify(foo).called(#voidWithPositionalAndOptionalNamedArg).once();
      verify(foo)
          .called(#voidWithPositionalAndOptionalNamedArg)
          .withArgs(positional: [10], named: {#y: 42}).once();
    });

    test('when voidWithOptionalPositionalArg (default)', () {
      when(foo).calls(#voidWithOptionalPositionalArg).thenReturn();
      expect(() => foo.voidWithOptionalPositionalArg(), returnsNormally);
      verify(foo).called(#voidWithOptionalPositionalArg).once();
    });

    test('when voidWithOptionalPositionalArg (override)', () {
      when(foo).calls(#voidWithOptionalPositionalArg).thenReturn();
      expect(() => foo.voidWithOptionalPositionalArg(10), returnsNormally);
      verify(foo).called(#voidWithOptionalPositionalArg).once();
      verify(foo)
          .called(#voidWithOptionalPositionalArg)
          .withArgs(positional: [10]).once();
    });

    test('when voidWithOptionalNamedArg (default)', () {
      when(foo).calls(#voidWithOptionalNamedArg).thenReturn();
      expect(() => foo.voidWithOptionalNamedArg(), returnsNormally);
      verify(foo).called(#voidWithOptionalNamedArg).once();
    });

    test('when voidWithOptionalNamedArg (override)', () {
      when(foo).calls(#voidWithOptionalNamedArg).thenReturn();
      expect(() => foo.voidWithOptionalNamedArg(x: 10), returnsNormally);
      verify(foo).called(#voidWithOptionalNamedArg).once();
      verify(foo)
          .called(#voidWithOptionalNamedArg)
          .withArgs(named: {#x: 10}).once();
    });

    test('when voidWithDefaultPositionalArg (default)', () {
      when(foo).calls(#voidWithDefaultPositionalArg).thenReturn();
      expect(() => foo.voidWithDefaultPositionalArg(), returnsNormally);
      verify(foo).called(#voidWithDefaultPositionalArg).once();
      verify(foo)
          .called(#voidWithDefaultPositionalArg)
          .withArgs(positional: [0]).once();
    });

    test('when voidWithDefaultPositionalArg (override)', () {
      when(foo).calls(#voidWithDefaultPositionalArg).thenReturn();
      expect(() => foo.voidWithDefaultPositionalArg(10), returnsNormally);
      verify(foo).called(#voidWithDefaultPositionalArg).once();
      verify(foo)
          .called(#voidWithDefaultPositionalArg)
          .withArgs(positional: [10]).once();
    });

    test('when voidWithDefaultNamedArg (default)', () {
      when(foo).calls(#voidWithDefaultNamedArg).thenReturn();
      expect(() => foo.voidWithDefaultNamedArg(), returnsNormally);
      verify(foo).called(#voidWithDefaultNamedArg).once();
      verify(foo)
          .called(#voidWithDefaultNamedArg)
          .withArgs(named: {#x: 0}).once();
    });

    test('when voidWithDefaultNamedArg (override)', () {
      when(foo).calls(#voidWithDefaultNamedArg).thenReturn();
      expect(() => foo.voidWithDefaultNamedArg(x: 10), returnsNormally);
      verify(foo).called(#voidWithDefaultNamedArg).once();
      verify(foo)
          .called(#voidWithDefaultNamedArg)
          .withArgs(named: {#x: 10}).once();
    });

    test('throws Exception when thenThrow is used to stub the mock', () {
      final exception = Exception('oops');
      when(foo).calls(#streamValue).thenThrow(exception);
      expect(() => foo.streamValue, throwsA(exception));
    });

    test(
        'throws MocktailFailure when verifyMocks is called '
        'and not all mocks were used (getter)', () {
      runZonedGuarded(() {
        when(foo).calls(#intValue).thenReturn(10);
        verifyMocks(foo);
        fail('should throw');
      }, (error, _) {
        expect(
          error,
          isA<MocktailFailure>().having(
            (f) => f.message,
            'message',
            'MockFoo.intValue => 10 was stubbed but never invoked.',
          ),
        );
      });
      expect(foo.intValue, equals(10));
    });

    test(
        'throws MocktailFailure when verifyMocks is called '
        'and not all mocks were used (method)', () {
      final expected = Future.value(42);
      runZonedGuarded(() async {
        when(foo)
            .calls(#asyncValueWithNamedAndPositionalArgs)
            .withArgs(positional: [1], named: {#y: 2}).thenReturn(expected);
        verifyMocks(foo);
        fail('should throw');
      }, (error, _) {
        expect(
          error,
          isA<MocktailFailure>().having(
            (f) => f.message,
            'message',
            '''MockFoo.asyncValueWithNamedAndPositionalArgs(1, y: 2) => Instance of 'Future<int>' was stubbed but never invoked.''',
          ),
        );
        expect(
          foo.asyncValueWithNamedAndPositionalArgs(1, y: 2),
          expected,
        );
      });
    });

    test(
        'throws MocktailFailure when verify call count is called '
        'with incorrect call count', () {
      runZonedGuarded(() {
        when(foo).calls(#intValue).thenReturn(10);
        verify(foo).called(#intValue).times(equals(1));
        fail('should throw');
      }, (error, _) {
        expect(
          error,
          isA<MocktailFailure>().having(
            (f) => f.message,
            'message',
            '''Expected MockFoo.intValue to be called <1> time(s) but actual call count was <0>.''',
          ),
        );
      });
      expect(foo.intValue, equals(10));
      verify(foo).called(#intValue).times(1);
    });

    test(
        'throws MocktailFailure when verify is called '
        'with with void function and no calls were made', () {
      runZonedGuarded(() async {
        when(foo).calls(#voidFunction).thenReturn(null);
        verify(foo).called(#voidFunction).once();
        fail('should throw');
      }, (error, _) {
        expect(
          error,
          isA<MocktailFailure>().having(
            (f) => f.message,
            'message',
            '''Expected MockFoo.voidFunction to be called <1> time(s) but actual call count was <0>.''',
          ),
        );
      });
      foo.voidFunction();
    });

    test(
        'throws MocktailFailure when verify is called '
        'with with asyncValueWithPositionalArg and no calls were made', () {
      runZonedGuarded(() async {
        when(foo)
            .calls(#asyncValueWithPositionalArg)
            .thenAnswer((_) async => 10);
        verify(foo)
            .called(#asyncValueWithPositionalArg)
            .withArgs(positional: [1]).once();
        fail('should throw');
      }, (error, _) {
        expect(
          error,
          isA<MocktailFailure>().having(
            (f) => f.message,
            'message',
            '''Expected MockFoo.asyncValueWithPositionalArg to be called <1> time(s) but actual call count was <0>.''',
          ),
        );
      });
      expectLater(
        foo.asyncValueWithPositionalArg(1),
        completes,
      );
    });

    test(
        'throws MocktailFailure when verify is called '
        'with incorrect positional args (lax)', () {
      runZonedGuarded(() async {
        when(foo)
            .calls(#asyncValueWithPositionalArg)
            .thenAnswer((_) async => 10);
        expect(await foo.asyncValueWithPositionalArg(2), 10);
        verify(foo)
            .called(#asyncValueWithPositionalArg)
            .withArgs(positional: [1]).times(1);
        fail('should throw');
      }, (error, _) {
        expect(
          error,
          isA<MocktailFailure>().having(
            (f) => f.message,
            'message',
            '''Expected MockFoo.asyncValueWithPositionalArg(1) to be called <1> time(s) but actual call count was <0>.''',
          ),
        );
      });
    });

    test(
        'throws MocktailFailure when verify is called '
        'with incorrect named arg (lax)', () {
      runZonedGuarded(() async {
        when(foo).calls(#asyncValueWithNamedArg).thenAnswer((_) async => 10);
        expect(await foo.asyncValueWithNamedArg(x: 2), 10);
        verify(foo)
            .called(#asyncValueWithNamedArg)
            .withArgs(named: {#x: 1}).times(1);
        fail('should throw');
      }, (error, _) {
        expect(
          error,
          isA<MocktailFailure>().having(
            (f) => f.message,
            'message',
            '''Expected MockFoo.asyncValueWithNamedArg(x: 1) to be called <1> time(s) but actual call count was <0>.''',
          ),
        );
      });
    });

    test(
        'throws MocktailFailure when verify is called '
        'with incorrect named args (lax)', () {
      runZonedGuarded(() async {
        when(foo).calls(#asyncValueWithNamedArgs).thenAnswer((_) async => 10);
        expect(await foo.asyncValueWithNamedArgs(x: 2, y: 3), 10);
        verify(foo)
            .called(#asyncValueWithNamedArgs)
            .withArgs(named: {#x: 1, #y: 1}).times(1);
        fail('should throw');
      }, (error, _) {
        expect(
          error,
          isA<MocktailFailure>().having(
            (f) => f.message,
            'message',
            '''Expected MockFoo.asyncValueWithNamedArgs(x: 1, y: 1) to be called <1> time(s) but actual call count was <0>.''',
          ),
        );
      });
    });

    test(
        'throws MocktailFailure when verify is called '
        'with incorrect positional and named args (lax)', () {
      runZonedGuarded(() async {
        when(foo)
            .calls(#asyncValueWithNamedAndPositionalArgs)
            .thenAnswer((_) async => 10);
        expect(await foo.asyncValueWithNamedAndPositionalArgs(1, y: 2), 10);
        verify(foo)
            .called(#asyncValueWithNamedAndPositionalArgs)
            .withArgs(positional: [2], named: {#y: 1}).times(1);
        fail('should throw');
      }, (error, _) {
        expect(
          error,
          isA<MocktailFailure>().having(
            (f) => f.message,
            'message',
            '''Expected MockFoo.asyncValueWithNamedAndPositionalArgs(2, y: 1) to be called <1> time(s) but actual call count was <0>.''',
          ),
        );
      });
    });

    test(
        'throws MocktailFailure when verify is called '
        'with incorrect args (strict)', () {
      final isEven = isA<int>().having((x) => x % 2 == 0, 'even', true);
      runZonedGuarded(() async {
        when(foo).calls(#asyncValueWithPositionalArg).withArgs(
          positional: [anyThat(isEven)],
        ).thenAnswer((_) async => 10);
        expect(await foo.asyncValueWithPositionalArg(2), 10);
        verify(foo)
            .called(#asyncValueWithPositionalArg)
            .withArgs(positional: [1]).times(1);
        fail('should throw');
      }, (error, _) {
        expect(
          error,
          isA<MocktailFailure>().having(
            (f) => f.message,
            'message',
            '''Expected MockFoo.asyncValueWithPositionalArg to be called <1> time(s) but actual call count was <0>.''',
          ),
        );
      });
    });

    test('throws noSuchMethod when no stub exists', () {
      expect(() => foo.intValue, throwsA(isA<NoSuchMethodError>()));
    });

    test('throws StateError if when is called on a real object', () {
      final realFoo = Foo();
      expect(() => when(realFoo), throwsA(isA<StateError>()));
    });

    test('throws StateError if verify is called on a real object', () {
      final realFoo = Foo();
      expect(() => verify(realFoo), throwsA(isA<StateError>()));
    });

    test('throws StateError if verifyMocks is called on a real object', () {
      final realFoo = Foo();
      expect(() => verifyMocks(realFoo), throwsA(isA<StateError>()));
    });

    test('throws StateError if reset is called on a real object', () {
      final realFoo = Foo();
      expect(() => reset(realFoo), throwsA(isA<StateError>()));
    });

    test(
        'throws NoSuchMethodError when arguments '
        'match but memberName does not', () {
      when(foo).calls(#increment).withArgs(positional: [41]).thenReturn(42);
      expect(foo.increment(41), equals(42));
      expect(() => foo.addOne(41), throwsNoSuchMethodError);
    });

    test('verify count strictly depends on member name and arguments', () {
      when(foo).calls(#increment).withArgs(positional: [41]).thenReturn(42);
      when(foo).calls(#increment).withArgs(positional: [42]).thenReturn(43);
      expect(foo.increment(41), equals(42));
      expect(foo.increment(42), equals(43));
      verify(foo).called(#increment).withArgs(positional: [41]).once();
      verify(foo).called(#increment).withArgs(positional: [42]).once();
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

    tearDown(() {
      verifyMocks(foo);
      verifyMocks(bar);
    });

    test('when foo (mocked dependency)', () {
      when(foo).calls(#intValue).thenReturn(42);
      when(bar).calls(#foo).thenReturn(foo);
      expect(bar.foo.intValue, 42);
    });
  });

  group('Baz', () {
    late Baz<String> baz;

    setUp(() {
      baz = MockBaz<String>();
    });

    tearDown(() {
      verifyMocks(baz);
    });

    test('verify count strictly depends on both member name and arguments', () {
      when(baz).calls(#add).thenReturn(null);

      const arg1 = 'A';
      const arg2 = 'B';
      const arg3 = 'C';

      baz.add(arg1);

      verify(baz).called(#add).withArgs(positional: [arg1]).once();

      baz.add(arg2);

      verify(baz).called(#add).withArgs(positional: [arg1]).once();
      verify(baz).called(#add).withArgs(positional: [arg2]).once();

      baz.add(arg3);

      verify(baz).called(#add).withArgs(positional: [arg1]).once();
      verify(baz).called(#add).withArgs(positional: [arg2]).once();
      verify(baz).called(#add).withArgs(positional: [arg3]).once();
    });

    test(
        'verify count strictly depends on both '
        'member name and arguments (multiple calls)', () {
      const arg1 = 'A';

      when(baz).calls(#add).thenReturn(null);
      verify(baz).called(#add).withArgs(positional: [arg1]).never();

      baz.add(arg1);
      verify(baz).called(#add).withArgs(positional: [arg1]).once();

      baz.add(arg1);
      verify(baz).called(#add).withArgs(positional: [arg1]).times(2);

      baz.add(arg1);
      verify(baz).called(#add).withArgs(positional: [arg1]).times(3);
    });
  });

  group('MocktailFailure', () {
    test('overrides toString', () {
      const message = 'example mocktail failure message';
      const expected = 'MocktailFailure: $message';
      expect(const MocktailFailure(message).toString(), expected);
    });
  });
}
