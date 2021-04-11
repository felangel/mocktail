import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  final mock = MyMock();

  tearDown(resetMocktailState);

  test('mocktail comes with pre-registered types', () {
    when(() => mock<bool>(any())).thenReturn('OK');
    when(() => mock<int>(any())).thenReturn('OK');
    when(() => mock<double>(any())).thenReturn('OK');
    when(() => mock<num>(any())).thenReturn('OK');
    when(() => mock<String>(any())).thenReturn('OK');
    when(() => mock<Object>(any())).thenReturn('OK');
    when(() => mock<dynamic>(any<dynamic>())).thenReturn('OK');
    when(() => mock<Map<String, dynamic>>(any())).thenReturn('OK');
    when(() => mock<Map<String, Object>>(any())).thenReturn('OK');
    when(() => mock<Map<String, Object?>>(any())).thenReturn('OK');
    when(() => mock<Map<String?, dynamic>>(any())).thenReturn('OK');
    when(() => mock<Map<String?, Object>>(any())).thenReturn('OK');
    when(() => mock<Map<String?, Object?>>(any())).thenReturn('OK');
    when(() => mock<Map<ComplexObject, ComplexObject>>(any())).thenReturn('OK');
    when(() => mock<Map<ComplexObject, ComplexObject?>>(any()))
        .thenReturn('OK');
    when(() => mock<Map<ComplexObject?, ComplexObject?>>(any()))
        .thenReturn('OK');
    when(() => mock<List<int>>(any())).thenReturn('OK');
    when(() => mock<List<int?>>(any())).thenReturn('OK');
    when(() => mock<List<double>>(any())).thenReturn('OK');
    when(() => mock<List<double?>>(any())).thenReturn('OK');
    when(() => mock<List<num>>(any())).thenReturn('OK');
    when(() => mock<List<num?>>(any())).thenReturn('OK');
    when(() => mock<List<String>>(any())).thenReturn('OK');
    when(() => mock<List<String?>>(any())).thenReturn('OK');
    when(() => mock<List<Object>>(any())).thenReturn('OK');
    when(() => mock<List<Object?>>(any())).thenReturn('OK');
    when(() => mock<List<bool>>(any())).thenReturn('OK');
    when(() => mock<List<bool?>>(any())).thenReturn('OK');
    when(() => mock<List<dynamic>>(any())).thenReturn('OK');
    when(() => mock<List<ComplexObject>>(any())).thenReturn('OK');
    when(() => mock<List<ComplexObject?>>(any())).thenReturn('OK');
    when(() => mock<Set<int>>(any())).thenReturn('OK');
    when(() => mock<Set<int?>>(any())).thenReturn('OK');
    when(() => mock<Set<double>>(any())).thenReturn('OK');
    when(() => mock<Set<double?>>(any())).thenReturn('OK');
    when(() => mock<Set<num>>(any())).thenReturn('OK');
    when(() => mock<Set<num?>>(any())).thenReturn('OK');
    when(() => mock<Set<String>>(any())).thenReturn('OK');
    when(() => mock<Set<String?>>(any())).thenReturn('OK');
    when(() => mock<Set<Object>>(any())).thenReturn('OK');
    when(() => mock<Set<Object?>>(any())).thenReturn('OK');
    when(() => mock<Set<bool>>(any())).thenReturn('OK');
    when(() => mock<Set<bool?>>(any())).thenReturn('OK');
    when(() => mock<Set<dynamic>>(any())).thenReturn('OK');
    when(() => mock<Set<ComplexObject>>(any())).thenReturn('OK');
    when(() => mock<Set<ComplexObject?>>(any())).thenReturn('OK');
    when(() => mock<VoidCallback>(any())).thenReturn('OK');
    when(() => mock<ValueCallback>(any())).thenReturn('OK');
    when(() => mock<ReturningCallback>(any())).thenReturn('OK');

    expect(mock<bool>(false), 'OK');
    expect(mock<int>(42), 'OK');
    expect(mock<double>(42), 'OK');
    expect(mock<num>(42), 'OK');
    expect(mock<String>('42'), 'OK');
    expect(mock<Object>(42), 'OK');
    expect(mock<dynamic>(42), 'OK');
    expect(mock<Map<String, dynamic>>(<String, dynamic>{}), 'OK');
    expect(mock<Map<String, Object>>({}), 'OK');
    expect(mock<Map<String, Object?>>({}), 'OK');
    expect(mock<Map<String?, dynamic>>(<String?, dynamic>{}), 'OK');
    expect(mock<Map<String?, Object>>({}), 'OK');
    expect(mock<Map<String?, Object?>>({}), 'OK');
    expect(mock<List<int>>([]), 'OK');
    expect(mock<List<int?>>([]), 'OK');
    expect(mock<List<double>>([]), 'OK');
    expect(mock<List<double?>>([]), 'OK');
    expect(mock<List<num>>([]), 'OK');
    expect(mock<List<num?>>([]), 'OK');
    expect(mock<List<String>>([]), 'OK');
    expect(mock<List<String?>>([]), 'OK');
    expect(mock<List<Object>>([]), 'OK');
    expect(mock<List<Object?>>([]), 'OK');
    expect(mock<List<bool>>([]), 'OK');
    expect(mock<List<bool?>>([]), 'OK');
    expect(mock<List<dynamic>>(<dynamic>[]), 'OK');
    expect(mock<Set<int>>({}), 'OK');
    expect(mock<Set<int?>>({}), 'OK');
    expect(mock<Set<double>>({}), 'OK');
    expect(mock<Set<double?>>({}), 'OK');
    expect(mock<Set<num>>({}), 'OK');
    expect(mock<Set<num?>>({}), 'OK');
    expect(mock<Set<String>>({}), 'OK');
    expect(mock<Set<String?>>({}), 'OK');
    expect(mock<Set<Object>>({}), 'OK');
    expect(mock<Set<Object?>>({}), 'OK');
    expect(mock<Set<bool>>({}), 'OK');
    expect(mock<Set<bool?>>({}), 'OK');
    expect(mock<Set<dynamic>>(<dynamic>{}), 'OK');
    expect(mock<VoidCallback>(() {}), 'OK');
    expect(mock<ValueCallback>((ComplexObject obj) {}), 'OK');
    expect(
      mock<ReturningCallback>((ComplexObject obj, int n, String bar) => obj),
      'OK',
    );
  });

  test('the pre-registered fallback callback throws when called', () {
    when(
      () => expect(
        any<Function>(),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            '''
A test tried to call mocktail's internal dummy callback.
This dummy callback is only meant to be passed around, but never called.''',
          ),
        ),
      ),
    );
  });

  test(
      'when the type is nullable, '
      'matchers should work even if the type was not registered', () {
    when(() => mock<ComplexObject?>(any())).thenReturn('OK');

    expect(mock<ComplexObject?>(ComplexObject()), 'OK');
  });

  test('when a type is not registered, throws an error', () {
    expect(
      () => when(() => mock<UnregisteredObject>(any())),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', '''
A test tried to use `any` or `captureAny` on a parameter of type `UnregisteredObject`, but
registerFallbackValue was not previously called to register a fallback value for `UnregisteredObject`.

To fix, do:

```
void main() {
  setUpAll(() {
    registerFallbackValue(/* create a dummy instance of `UnregisteredObject` */);
  });
}
```

This instance of `UnregisteredObject` will only be passed around, but never be interacted with.
Therefore, if `UnregisteredObject` is a function, it does not have to return a valid object and
could throw unconditionally.
If you cannot easily create an instance of `UnregisteredObject`, consider defining a `Fake`:

```
class MyTypeFake extends Fake implements MyType {}

void main() {
  setUpAll(() {
    registerFallbackValue(MyTypeFake());
  });
}
```

Fallbacks are required because mocktail has to know of a valid `UnregisteredObject` to prevent
TypeErrors from being thrown in Dart's sound null safe mode, while still
providing a convenient syntax.
'''),
      ),
    );
  });

  test('throws an error when matcher used outside context of when/verify/until',
      () {
    expect(
      () => mock<ManuallyRegisteredObject>(any()),
      throwsArgumentError,
    );
  });

  group('registerFallbackValue with matchExactType set to false', () {
    test('allows matchers to work with this type', () {
      registerFallbackValue<ManuallyRegisteredObject>(
        ManuallyRegisteredObject(),
      );

      when(() => mock<ManuallyRegisteredObject>(any())).thenReturn('OK');

      expect(mock<ManuallyRegisteredObject>(ManuallyRegisteredObject()), 'OK');
    });

    test('allows matchers to work with supertypes', () {
      registerFallbackValue<ManuallyRegisteredSubclass>(
        ManuallyRegisteredSubclass(),
      );

      when(() => mock<AllowedSuperclass>(any())).thenReturn('OK');

      expect(mock<AllowedSuperclass>(AllowedSuperclass()), 'OK');
    });
  });

  test('registered types are preserved accross reset', () {
    registerFallbackValue<ManuallyRegisteredObject>(ManuallyRegisteredObject());

    resetMocktailState();

    when(() => mock<ManuallyRegisteredObject>(any())).thenReturn('OK');

    expect(mock<ManuallyRegisteredObject>(ManuallyRegisteredObject()), 'OK');
  });
}

class MyMock extends Mock {
  String call<T>(T value);
}

class ComplexObject {}

class ManuallyRegisteredObject {}

class AllowedSuperclass {}

class ManuallyRegisteredSubclass extends AllowedSuperclass {}

class NotAllowedSuperclass {}

class ManuallyRegisteredExactSubclass extends NotAllowedSuperclass {}

class ExactlyRegisteredClass {}

class UnregisteredObject {}

typedef VoidCallback = void Function();

typedef ValueCallback = void Function(ComplexObject obj);

typedef ReturningCallback = ComplexObject Function(
  ComplexObject obj,
  int n,
  String foo,
);

typedef UnregisteredCallback = ComplexObject Function({
  ComplexObject obj,
  int n,
  String foo,
});
