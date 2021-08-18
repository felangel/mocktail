import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _RealClass {
  String? methodWithoutArgs() => 'Real';
  String? methodWithNormalArgs(int? x) => 'Real';
  String? methodWithListArgs(List<int>? x) => 'Real';
  String? methodWithPositionalArgs(int? x, [int? y]) => 'Real';
  String? methodWithNamedArgs(int? x, {int? y}) => 'Real';
  String? methodWithTwoNamedArgs(int? x, {int? y, int? z}) => 'Real';
  String? methodWithObjArgs(_RealClass? x) => 'Real';
  String? methodWithTypeArgs<T>() => 'Real';
  String? methodWithDefaultTypeArg<T extends num>() => 'Real';
  String? typeParameterizedFn(List<int>? w, List<int>? x,
          [List<int>? y, List<int>? z]) =>
      'Real';
  String? typeParameterizedNamedFn(List<int>? w, List<int>? x,
          {List<int>? y, List<int>? z}) =>
      'Real';
  String? get getter => 'Real';
  set setter(String arg) {
    throw StateError('I must be mocked');
  }
}

class CallMethodsEvent {}

/// Listens on a stream and upon any event calls all methods in [_RealClass].
class _RealClassController {
  _RealClassController(
    this._realClass,
    StreamController<CallMethodsEvent> streamController,
  ) {
    streamController.stream.listen(_callAllMethods);
  }

  final _RealClass _realClass;

  Future<Null> _callAllMethods(dynamic _) async {
    _realClass
      ..methodWithoutArgs()
      ..methodWithNormalArgs(1)
      ..methodWithListArgs([1, 2])
      ..methodWithPositionalArgs(1, 2)
      ..methodWithNamedArgs(1, y: 2)
      ..methodWithTwoNamedArgs(1, y: 2, z: 3)
      ..methodWithObjArgs(_RealClass())
      ..methodWithTypeArgs<List<String>>()
      ..methodWithDefaultTypeArg()
      ..typeParameterizedFn([1, 2], [3, 4], [5, 6], [7, 8])
      ..typeParameterizedNamedFn([1, 2], [3, 4], y: [5, 6], z: [7, 8])
      ..getter
      ..setter = 'A';
  }
}

class _MockedClass extends Mock implements _RealClass {}

void main() {
  late _MockedClass mock;

  setUp(() {
    mock = _MockedClass();
  });

  tearDown(resetMocktailState);

  group('untilCalled', () {
    var streamController = StreamController<CallMethodsEvent>.broadcast();

    group('on methods already called', () {
      test('waits for method without args', () async {
        mock.methodWithoutArgs();

        await untilCalled(() => mock.methodWithoutArgs());

        verify(() => mock.methodWithoutArgs()).called(1);
      });

      test('waits for method with normal args', () async {
        mock.methodWithNormalArgs(1);

        await untilCalled(() => mock.methodWithNormalArgs(any()));

        verify(() => mock.methodWithNormalArgs(any())).called(1);
      });

      test('waits for method with list args', () async {
        mock.methodWithListArgs([1]);

        await untilCalled(() => mock.methodWithListArgs(any()));

        verify(() => mock.methodWithListArgs(any())).called(1);
      });

      test('waits for method with positional args', () async {
        mock.methodWithPositionalArgs(1, 2);

        await untilCalled(() => mock.methodWithPositionalArgs(any(), any()));

        verify(() => mock.methodWithPositionalArgs(any(), any())).called(1);
      });

      test('waits for method with named args', () async {
        mock.methodWithNamedArgs(1, y: 2);

        await untilCalled(
          () => mock.methodWithNamedArgs(any(), y: any(named: 'y')),
        );

        verify(() => mock.methodWithNamedArgs(any(), y: any(named: 'y')))
            .called(1);
      });

      test('waits for method with two named args', () async {
        mock.methodWithTwoNamedArgs(1, y: 2, z: 3);

        await untilCalled(
          () => mock.methodWithTwoNamedArgs(
            any(),
            y: any(named: 'y'),
            z: any(named: 'z'),
          ),
        );

        verify(() => mock.methodWithTwoNamedArgs(
              any(),
              y: any(named: 'y'),
              z: any(named: 'z'),
            )).called(1);
      });

      test('waits for method with obj args', () async {
        mock.methodWithObjArgs(_RealClass());

        await untilCalled(() => mock.methodWithObjArgs(any()));

        verify(() => mock.methodWithObjArgs(any())).called(1);
      });

      test('waits for method with type args', () async {
        mock.methodWithTypeArgs<List<String>>();

        await untilCalled(() => mock.methodWithTypeArgs<List<String>>());

        verify(() => mock.methodWithTypeArgs<List<String>>()).called(1);
      });

      test('waits for method with default type args', () async {
        mock.methodWithDefaultTypeArg();

        await untilCalled(() => mock.methodWithDefaultTypeArg());

        verify(() => mock.methodWithDefaultTypeArg<num>()).called(1);
      });

      test('waits for function with positional parameters', () async {
        mock.typeParameterizedFn([1, 2], [3, 4], [5, 6], [7, 8]);

        await untilCalled(
            () => mock.typeParameterizedFn(any(), any(), any(), any()));

        verify(() => mock.typeParameterizedFn(any(), any(), any(), any()))
            .called(1);
      });

      test('waits for function with named parameters', () async {
        mock.typeParameterizedNamedFn([1, 2], [3, 4], y: [5, 6], z: [7, 8]);

        await untilCalled(() => mock.typeParameterizedNamedFn(
              any(),
              any(),
              y: any(named: 'y'),
              z: any(named: 'z'),
            ));

        verify(() => mock.typeParameterizedNamedFn(
              any(),
              any(),
              y: any(named: 'y'),
              z: any(named: 'z'),
            )).called(1);
      });

      test('waits for getter', () async {
        mock.getter;

        await untilCalled(() => mock.getter);

        verify(() => mock.getter).called(1);
      });

      test('waits for setter', () async {
        mock.setter = 'A';

        await untilCalled(() => mock.setter = 'A');

        verify(() => mock.setter = 'A').called(1);
      });
    });

    group('on methods not yet called', () {
      setUp(() {
        _RealClassController(mock, streamController);
      });

      test('waits for method without args', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(() => mock.methodWithoutArgs());

        await untilCalled(() => mock.methodWithoutArgs());

        verify(() => mock.methodWithoutArgs()).called(1);
      });

      test('waits for method with normal args', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(() => mock.methodWithNormalArgs(any()));

        await untilCalled(() => mock.methodWithNormalArgs(any()));

        verify(() => mock.methodWithNormalArgs(any())).called(1);
      });

      test('waits for method with list args', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(() => mock.methodWithListArgs(any()));

        await untilCalled(() => mock.methodWithListArgs(any()));

        verify(() => mock.methodWithListArgs(any())).called(1);
      });

      test('waits for method with positional args', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(() => mock.methodWithPositionalArgs(any(), any()));

        await untilCalled(() => mock.methodWithPositionalArgs(any(), any()));

        verify(() => mock.methodWithPositionalArgs(any(), any())).called(1);
      });

      test('waits for method with named args', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(() => mock.methodWithNamedArgs(any(), y: any(named: 'y')));

        await untilCalled(
          () => mock.methodWithNamedArgs(any(), y: any(named: 'y')),
        );

        verify(() => mock.methodWithNamedArgs(any(), y: any(named: 'y')))
            .called(1);
      });

      test('waits for method with two named args', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(() => mock.methodWithTwoNamedArgs(
              any(),
              y: any(named: 'y'),
              z: any(named: 'z'),
            ));

        await untilCalled(() => mock.methodWithTwoNamedArgs(
              any(),
              y: any(named: 'y'),
              z: any(named: 'z'),
            ));

        verify(() => mock.methodWithTwoNamedArgs(
              any(),
              y: any(named: 'y'),
              z: any(named: 'z'),
            )).called(1);
      });

      test('waits for method with obj args', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(() => mock.methodWithObjArgs(any()));

        await untilCalled(() => mock.methodWithObjArgs(any()));

        verify(() => mock.methodWithObjArgs(any())).called(1);
      });

      test('waits for method with type args', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(() => mock.methodWithTypeArgs<List<String>>());

        await untilCalled(() => mock.methodWithTypeArgs<List<String>>());

        verify(() => mock.methodWithTypeArgs<List<String>>()).called(1);
      });

      test('waits for method with default type args', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(() => mock.methodWithDefaultTypeArg());

        await untilCalled(() => mock.methodWithDefaultTypeArg());

        verify(() => mock.methodWithDefaultTypeArg()).called(1);
      });

      test('waits for function with positional parameters', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(() => mock.typeParameterizedFn(any(), any(), any(), any()));

        await untilCalled(
            () => mock.typeParameterizedFn(any(), any(), any(), any()));

        verify(() => mock.typeParameterizedFn(any(), any(), any(), any()))
            .called(1);
      });

      test('waits for function with named parameters', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(() => mock.typeParameterizedNamedFn(
              any(),
              any(),
              y: any(named: 'y'),
              z: any(named: 'z'),
            ));

        await untilCalled(() => mock.typeParameterizedNamedFn(
              any(),
              any(),
              y: any(named: 'y'),
              z: any(named: 'z'),
            ));

        verify(() => mock.typeParameterizedNamedFn(
              any(),
              any(),
              y: any(named: 'y'),
              z: any(named: 'z'),
            )).called(1);
      });

      test('waits for getter', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(() => mock.getter);

        await untilCalled(() => mock.getter);

        verify(() => mock.getter).called(1);
      });

      test('waits for setter', () async {
        streamController.add(CallMethodsEvent());
        verifyNever(() => mock.setter = 'A');

        await untilCalled(() => mock.setter = 'A');

        verify(() => mock.setter = 'A').called(1);
      });

      test('throws if exception occurs within lambda', () {
        expect(() => untilCalled(() => throw Exception('')), throwsException);
      });
    });
  });
}
