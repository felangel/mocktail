// ignore_for_file: avoid_setters_without_getters

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _RealClass {
  String? methodWithNormalArgs(int? x) => 'Real';
  String? methodWithListArgs(List<int>? x) => 'Real';
  String? methodWithPositionalArgs(int? x, [int? y]) => 'Real';
  String? methodWithTwoNamedArgs(int? x, {int? y, int? z}) => 'Real';
  set setter(String? arg) {
    throw StateError('I must be mocked');
  }
}

class _MockedClass extends Mock implements _RealClass {}

void main() {
  late _MockedClass mock;

  setUp(() {
    mock = _MockedClass();
  });

  tearDown(resetMocktailState);

  group('capture', () {
    test('captureAny should match anything', () {
      mock.methodWithNormalArgs(42);
      expect(
        verify(() => mock.methodWithNormalArgs(captureAny())).captured.single,
        equals(42),
      );
    });

    test('captureThat should match some things', () {
      mock
        ..methodWithNormalArgs(42)
        ..methodWithNormalArgs(44)
        ..methodWithNormalArgs(43)
        ..methodWithNormalArgs(45);
      expect(
        verify(() => mock.methodWithNormalArgs(captureAny(that: lessThan(44))))
            .captured,
        equals([42, 43]),
      );
    });

    test('should capture list arguments', () {
      mock.methodWithListArgs([42]);
      expect(
        verify(() => mock.methodWithListArgs(captureAny())).captured.single,
        equals([42]),
      );
    });

    test('should capture setter invocations', () {
      mock.setter = 'value';
      expect(
        verify(() => mock.setter = captureAny()).captured,
        equals(['value']),
      );
    });

    test('should capture multiple arguments', () {
      mock.methodWithPositionalArgs(1, 2);
      expect(
        verify(() => mock.methodWithPositionalArgs(captureAny(), captureAny()))
            .captured,
        equals([1, 2]),
      );
    });

    test('should capture with matching arguments', () {
      mock
        ..methodWithPositionalArgs(1)
        ..methodWithPositionalArgs(2, 3);
      expect(
        verify(() => mock.methodWithPositionalArgs(captureAny(), captureAny()))
            .captured,
        equals([1, null, 2, 3]),
      );
    });

    test('should capture multiple invocations', () {
      mock
        ..methodWithNormalArgs(1)
        ..methodWithNormalArgs(2);
      expect(
        verify(() => mock.methodWithNormalArgs(captureAny())).captured,
        equals([1, 2]),
      );
    });

    test('should capture invocations with named arguments', () {
      mock.methodWithTwoNamedArgs(1, y: 42, z: 43);
      expect(
        verify(
          () => mock.methodWithTwoNamedArgs(
            any(),
            y: captureAny(named: 'y'),
            z: captureAny(named: 'z'),
          ),
        ).captured,
        equals([42, 43]),
      );
    });

    test('should capture invocations with named arguments', () {
      mock
        ..methodWithTwoNamedArgs(1, y: 42, z: 43)
        ..methodWithTwoNamedArgs(1, y: 44, z: 45);
      expect(
        verify(
          () => mock.methodWithTwoNamedArgs(
            any(),
            y: captureAny(named: 'y'),
            z: captureAny(named: 'z'),
          ),
        ).captured,
        equals([42, 43, 44, 45]),
      );
    });

    test('should capture invocations with out-of-order named arguments', () {
      mock
        ..methodWithTwoNamedArgs(1, z: 42, y: 43)
        ..methodWithTwoNamedArgs(1, y: 44, z: 45);
      expect(
        verify(
          () => mock.methodWithTwoNamedArgs(
            any(),
            y: captureAny(named: 'y'),
            z: captureAny(named: 'z'),
          ),
        ).captured,
        equals([43, 42, 44, 45]),
      );
    });
  });
}
