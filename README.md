# mocktail

[![Pub](https://img.shields.io/pub/v/mocktail.svg)](https://pub.dev/packages/mocktail)
[![build](https://github.com/felangel/mocktail/workflows/build/badge.svg)](https://github.com/felangel/mocktail/actions)
[![coverage](https://raw.githubusercontent.com/felangel/mocktail/main/coverage_badge.svg)](https://github.com/felangel/mocktail/actions)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

---

Mock library for Dart inspired by [mockito](https://pub.dev/packages/mockito).

`Mocktail` focuses on providing a familiar, simple API for creating mocks in Dart (with null-safety) without the need for manual mocks or code generation.

## Creating a Mock

```dart
import 'package:mocktail/mocktail.dart';

// A Real Cat class
class Cat {
  String sound() => 'meow!';
  int lives = 9;
}

// A Mock Cat class
class MockCat extends Mock implements Cat {}

void main() {
  // Create a Mock Cat instance
  final cat = MockCat();
}
```

## Verifying Behavior

The `MockCat` instance can then be used to stub and verify calls.

```dart
// Interact with the mock cat
cat.sound();

// Verify the interaction occurred.
verify(cat).calls('sound').times(1);
```

## Stubbing

```dart
// Stub a method before interacting with the mock.
when(cat).calls('sound').thenReturn('purrr!');
expect(cat.sound(), 'purrr!');

// You can interact with the mock multiple times.
expect(cat.sound(), 'purrr!');

// You can change the stub.
when(cat).calls('sound').thenReturn('meow');
expect(cat.sound(), 'meow');

// You can stub getters.
when(cat).calls('lives').thenReturn(10);
expect(cat.lives, 10);

// You can stub a method to throw.
when(cat).calls('sound').thenThrow(Exception('oops'));
expect(() => cat.sound(), throwsA(isA<Exception>()));

// You can calculate stubs dynamically.
final sounds = ['purrr', 'meow'];
when(cat).calls('sound').thenAnswer((_) => sounds.removeAt(0));
expect(cat.sound(), 'purrr');
expect(cat.sound(), 'meow');
```

## Resetting Mocks

```dart
// Reset stubs and interactions
reset(cat);
```
