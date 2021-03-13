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

    expect(mock<bool>(false), 'OK');
    expect(mock<int>(42), 'OK');
    expect(mock<double>(42), 'OK');
    expect(mock<num>(42), 'OK');
    expect(mock<String>('42'), 'OK');
    expect(mock<Object>(42), 'OK');
    expect(mock<dynamic>(42), 'OK');
    expect(mock<Map<String, dynamic>>(<String, dynamic>{}), 'OK');
    expect(mock<Map<String, Object>>({}), 'OK');
    expect(mock<Map<String, Object>>({}), 'OK');
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
registerFallbackValue was not previously called to register a fallback value for `UnregisteredObject`

To fix, do:

```
void main() {
  setUpAll(() {
    registerFallbackValue<UnregisteredObject>(UnregisteredObject());
  });
}
```

If you cannot easily create an instance of UnregisteredObject, consider defining a `Fake`:

```
class UnregisteredObjectFake extends Fake implements UnregisteredObject {}

void main() {
  setUpAll(() {
    registerFallbackValue<UnregisteredObject>(UnregisteredObjectFake());
  });
}
```
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

  test('calling registerFallbackValue allows matchers to work with this type',
      () {
    registerFallbackValue<ManuallyRegisteredObject>(ManuallyRegisteredObject());

    when(() => mock<ManuallyRegisteredObject>(any())).thenReturn('OK');

    expect(mock<ManuallyRegisteredObject>(ManuallyRegisteredObject()), 'OK');
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

class UnregisteredObject {}
