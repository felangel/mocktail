# 🍹 mocktail

[![Pub](https://img.shields.io/pub/v/mocktail.svg)](https://pub.dev/packages/mocktail)
[![build](https://github.com/felangel/mocktail/workflows/build/badge.svg)](https://github.com/felangel/mocktail/actions)
[![coverage](https://raw.githubusercontent.com/felangel/mocktail/main/coverage_badge.svg)](https://github.com/felangel/mocktail/actions)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

---

Mock library for Dart inspired by [mockito](https://pub.dev/packages/mockito).

Mocktail focuses on providing a familiar, simple API for creating mocks in Dart (with null-safety) without the need for manual mocks or code generation.

## Creating a Mock

```dart
import 'package:mocktail/mocktail.dart';

// A Real Cat class
class Cat {
  String sound() => 'meow!';
  bool likes(String food, {bool isHungry = false}) => false;
  final int lives = 9;
}

// A Mock Cat class
class MockCat extends Mock implements Cat {}

void main() {
  // Create a Mock Cat instance
  final cat = MockCat();
}
```

## Stub and Verify Behavior

The `MockCat` instance can then be used to stub and verify calls.

```dart
// Stub the `sound` method.
when(() => cat.sound()).thenReturn('meow');

// Verify no interactions have occurred.
verifyNever(() => cat.sound());

// Interact with the mock cat instance.
cat.sound();

// Verify the interaction occurred.
verify(() => cat.sound()).called(1);

// Interact with the mock instance again.
cat.sound();

// Verify the interaction occurred twice.
verify(() => cat.sound()).called(1);
```

## Additional Usage

```dart
// Stub a method before interacting with the mock.
when(() => cat.sound()).thenReturn('purrr!');
expect(cat.sound(), 'purrr!');

// You can interact with the mock multiple times.
expect(cat.sound(), 'purrr!');

// You can change the stub.
when(() => cat.sound()).thenReturn('meow!');
expect(cat.sound(), 'meow');

// You can stub getters.
when(() => cat.lives).thenReturn(10);
expect(cat.lives, 10);

// You can stub a method for specific arguments.
when(() => cat.likes('fish', isHungry: false)).thenReturn(true);
expect(cat.likes('fish', isHungry: false), isTrue);

// You can verify the interaction for specific arguments.
verify(() => cat.likes('fish', isHungry: false)).called(1);

// You can stub a method using argument matchers: `any`.
when(() => cat.likes(any(), isHungry: any(named: 'isHungry', that: isFalse)).thenReturn(true);
expect(cat.likes('fish', isHungry: false), isTrue);

// You can stub a method to throw.
when(() => cat.sound()).thenThrow(Exception('oops'));
expect(() => cat.sound(), throwsA(isA<Exception>()));

// You can calculate stubs dynamically.
final sounds = ['purrr', 'meow'];
when(() => cat.sound()).thenAnswer((_) => sounds.removeAt(0));
expect(cat.sound(), 'purrr');
expect(cat.sound(), 'meow');

// You can capture any argument.
when(() => cat.likes('fish')).thenReturn(true);
expect(cat.likes('fish'), isTrue);
final captured = verify(() => cat.likes(captureAny())).captured;
expect(captured.last, equals(['fish']));

// You can capture a specific argument based on a matcher.
when(() => cat.likes(any())).thenReturn(true);
expect(cat.likes('fish'), isTrue);
expect(cat.likes('dog food'), isTrue);
final captured = verify(() => cat.likes(captureAny(that: startsWith('d')))).captured;
expect(captured.last, equals(['dog food']));
```

## Resetting Mocks

```dart
reset(cat); // Reset stubs and interactions
```

## How it works

Mocktail uses closures to handle catching `TypeError` instances which would otherwise propagate and cause test failures when stubbing/verifying non-nullable return types. Check out [#24](https://github.com/felangel/mocktail/issues/24) for more information.

In order to support argument matchers such as `any` and `captureAny` mocktail has to register default fallback values to return when the argument matchers are used. Out of the box, it automatically handles all primitive types, however, when using argument matchers in place of custom types developers must use `registerFallbackValue` to provide a default return value. It is only required to call `registerFallbackValue` once per type so it is recommended to place all `registerFallbackValue` calls within `setUpAll`.

```dart
class Food {...}

class Cat {
  bool likes(Food food) {...}
}

...

class MockCat extends Mock implements Cat {}

class FakeFood extends Fake implements Food {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFood());
  });

  test('...', () {
    final cat = MockCat();
    when(() => cat.likes(any()).thenReturn(true);
    ...
  });
}
```

## Common Issues

#### Why am I getting an invalid_implementation_override error when trying to Fake certain classes like ThemeData and ColorScheme?

[Relevant Issue](https://github.com/felangel/mocktail/issues/59)

This is likely due to differences in the function signature of `toString` for the class and can be resolved
using a mixin as demonstrated below:

```dart
mixin DiagnosticableToStringMixin on Object {
  @override
  String toString({DiagonsticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}

class FakeThemeData extends Fake
  with DiagnosticableToStringMixin
  implements ThemeData {}
```

#### Why can't I stub/verify extension methods?

[Relevant Issue](https://github.com/felangel/mocktail/issues/58)

Extension methods cannot be stubbed/verified as extension methods are treated like static methods meaning that calls go directly to the extension without caring about the instance. As a result, stubs and verify calls to extensions always result in an invocation of the real extension method.

In summary, avoid exposing extension methods as part of the public interface for your classes and limit extension methods to internal class logic.