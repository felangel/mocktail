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
}

class Bar {
  const Bar(this.foo);
  final Foo foo;
}

class MockFoo extends Mock implements Foo {}

class MockBar extends Mock implements Bar {}

void main() {
  group('Foo', () {
    late Foo foo;

    setUp(() {
      foo = MockFoo();
    });

    tearDown(() {
      verifyMocks(foo);
    });

    test('verify called 0 times (value)', () {
      verify(foo).calls('intValue').times(0);
    });

    test('when value (int)', () {
      when(foo).calls('intValue').thenReturn(10);
      expect(foo.intValue, 10);
      verify(foo).calls('intValue').times(1);
    });

    test('when value (map)', () {
      when(foo).calls('mapValue').thenReturn({'hello': 'world'});
      expect(foo.mapValue, {'hello': 'world'});
    });

    test('when asyncValue', () async {
      when(foo).calls('asyncValue').thenAnswer((_) async => 10);
      expect(await foo.asyncValue(), 10);
    });

    test('when asyncValueWithPositionalArg (any)', () async {
      when(foo)
          .calls('asyncValueWithPositionalArg')
          .thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithPositionalArg(1), 10);
      verify(foo).calls('asyncValueWithPositionalArg').times(1);
    });

    test('when asyncValueWithPositionalArg (explicit)', () async {
      when(foo)
          .calls('asyncValueWithPositionalArg')
          .thenAnswer((_) async => 10);
      when(foo)
          .calls('asyncValueWithPositionalArg')
          .withArgs(positional: [1]).thenAnswer((_) async => 42);
      expect(await foo.asyncValueWithPositionalArg(1), 42);
      expect(await foo.asyncValueWithPositionalArg(2), 10);
      verify(foo).calls('asyncValueWithPositionalArg').times(2);
      verify(foo)
          .calls('asyncValueWithPositionalArg')
          .withArgs(positional: [1]).times(1);
      verify(foo)
          .calls('asyncValueWithPositionalArg')
          .withArgs(positional: [2]).times(1);
    });

    test('when asyncValueWithPositionalArgs (any)', () async {
      when(foo)
          .calls('asyncValueWithPositionalArgs')
          .thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithPositionalArgs(1, 2), 10);
      verify(foo).calls('asyncValueWithPositionalArgs').times(1);
      verify(foo)
          .calls('asyncValueWithPositionalArgs')
          .withArgs(positional: [1, 2]).times(1);
    });

    test('when asyncValueWithPositionalArgs (explicit)', () async {
      when(foo)
          .calls('asyncValueWithPositionalArgs')
          .thenAnswer((_) async => 10);
      when(foo)
          .calls('asyncValueWithPositionalArgs')
          .withArgs(positional: [1, 2]).thenAnswer((_) async => 42);
      expect(await foo.asyncValueWithPositionalArgs(1, 2), 42);
      expect(await foo.asyncValueWithPositionalArgs(2, 4), 10);
      verify(foo).calls('asyncValueWithPositionalArgs').times(2);
      verify(foo)
          .calls('asyncValueWithPositionalArgs')
          .withArgs(positional: [1, 2]).times(1);
      verify(foo)
          .calls('asyncValueWithPositionalArgs')
          .withArgs(positional: [2, 4]).times(1);
    });

    test('when asyncValueWithNamedArg (any)', () async {
      when(foo).calls('asyncValueWithNamedArg').thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedArg(x: 1), 10);
      verify(foo).calls('asyncValueWithNamedArg').times(1);
      verify(foo)
          .calls('asyncValueWithNamedArg')
          .withArgs(named: {'x': 1}).times(1);
    });

    test('when asyncValueWithNamedArg (explicit)', () async {
      when(foo).calls('asyncValueWithNamedArg').thenAnswer((_) async => 10);
      when(foo)
          .calls('asyncValueWithNamedArg')
          .withArgs(named: {'x': 1}).thenAnswer((_) async => 42);
      expect(await foo.asyncValueWithNamedArg(x: 1), 42);
      expect(await foo.asyncValueWithNamedArg(x: 2), 10);
      verify(foo).calls('asyncValueWithNamedArg').times(2);
      verify(foo)
          .calls('asyncValueWithNamedArg')
          .withArgs(named: {'x': 1}).times(1);
      verify(foo)
          .calls('asyncValueWithNamedArg')
          .withArgs(named: {'x': 2}).times(1);
    });

    test('when asyncValueWithNamedArgs (any)', () async {
      when(foo).calls('asyncValueWithNamedArgs').thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedArgs(x: 1, y: 2), 10);
      verify(foo).calls('asyncValueWithNamedArgs').times(1);
      verify(foo)
          .calls('asyncValueWithNamedArgs')
          .withArgs(named: {'x': 1, 'y': 2}).times(1);
    });

    test('when asyncValueWithNamedArgs (explicit)', () async {
      when(foo).calls('asyncValueWithNamedArgs').thenAnswer((_) async => 10);
      when(foo)
          .calls('asyncValueWithNamedArgs')
          .withArgs(named: {'x': 1, 'y': 2}).thenAnswer((_) async => 42);
      expect(await foo.asyncValueWithNamedArgs(x: 1, y: 2), 42);
      expect(await foo.asyncValueWithNamedArgs(x: 2, y: 4), 10);
      verify(foo).calls('asyncValueWithNamedArgs').times(2);
      verify(foo)
          .calls('asyncValueWithNamedArgs')
          .withArgs(named: {'x': 1, 'y': 2}).times(1);
      verify(foo)
          .calls('asyncValueWithNamedArgs')
          .withArgs(named: {'x': 2, 'y': 4}).times(1);
    });

    test('when asyncValueWithNamedAndPositionalArgs (any)', () async {
      when(foo)
          .calls('asyncValueWithNamedAndPositionalArgs')
          .thenAnswer((_) async => 10);
      expect(await foo.asyncValueWithNamedAndPositionalArgs(1, y: 2), 10);
      verify(foo).calls('asyncValueWithNamedAndPositionalArgs').times(1);
      verify(foo)
          .calls('asyncValueWithNamedAndPositionalArgs')
          .withArgs(positional: [1], named: {'y': 2}).times(1);
    });

    test('when asyncValueWithNamedAndPositionalArgs (explicit)', () async {
      when(foo)
          .calls('asyncValueWithNamedAndPositionalArgs')
          .thenAnswer((_) async => 10);
      when(foo).calls('asyncValueWithNamedAndPositionalArgs').withArgs(
          positional: [1], named: {'y': 2}).thenAnswer((_) async => 42);
      expect(await foo.asyncValueWithNamedAndPositionalArgs(1, y: 2), 42);
      expect(await foo.asyncValueWithNamedAndPositionalArgs(2, y: 4), 10);
      verify(foo).calls('asyncValueWithNamedAndPositionalArgs').times(2);
      verify(foo)
          .calls('asyncValueWithNamedAndPositionalArgs')
          .withArgs(positional: [1], named: {'y': 2}).times(1);
      verify(foo)
          .calls('asyncValueWithNamedAndPositionalArgs')
          .withArgs(positional: [2], named: {'y': 4}).times(1);
    });

    test('when streamValue', () {
      when(foo).calls('streamValue').thenAnswer((_) => Stream.value(42));
      expectLater(
        foo.streamValue,
        emitsInOrder(<Matcher>[equals(42), emitsDone]),
      );
      verify(foo).calls('streamValue').times(1);
    });

    test('throws Exception when thenThrow is used to stub the mock', () {
      final exception = Exception('oops');
      when(foo).calls('streamValue').thenThrow(exception);
      expect(() => foo.streamValue, throwsA(exception));
    });

    test(
        'throws MocktailFailure when verifyMocks is called '
        'and not all mocks were used', () {
      runZonedGuarded(() {
        when(foo).calls('intValue').thenReturn(10);
        verifyMocks(foo);
        fail('should throw');
      }, (error, _) {
        expect(
          error,
          isA<MocktailFailure>().having(
            (f) => f.message,
            'message',
            'MockFoo.Symbol("intValue") => 10 was stubbed but never invoked',
          ),
        );
      });
      expect(foo.intValue, equals(10));
    });

    test(
        'throws MocktailFailure when verify call count is called '
        'with incorrect call count', () {
      runZonedGuarded(() {
        when(foo).calls('intValue').thenReturn(10);
        verify(foo).calls('intValue').times(1);
        fail('should throw');
      }, (error, _) {
        expect(
          error,
          isA<MocktailFailure>().having(
            (f) => f.message,
            'message',
            '''Expected MockFoo.intValue to be called 1 time(s) but actual call count was 0.''',
          ),
        );
      });
      expect(foo.intValue, equals(10));
      verify(foo).calls('intValue').times(1);
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
      when(foo).calls('intValue').thenReturn(42);
      when(bar).calls('foo').thenReturn(foo);
      expect(bar.foo.intValue, 42);
    });
  });
}
