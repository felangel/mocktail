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
when(cat).calls(#sound).thenReturn('meow');

// Verify no interactions have occurred.
verify(cat).called(#sound).never();

// Interact with the mock cat instance.
cat.sound();

// Verify the interaction occurred.
verify(cat).called(#sound).once();

// Interact with the mock instance again.
cat.sound();

// Verify the interaction occurred twice.
verify(cat).called(#sound).times(2);
```

## Additional Usage

```dart
// Stub a method before interacting with the mock.
when(cat).calls(#sound).thenReturn('purrr!');
expect(cat.sound(), 'purrr!');

// You can interact with the mock multiple times.
expect(cat.sound(), 'purrr!');

// You can change the stub.
when(cat).calls(#sound).thenReturn('meow');
expect(cat.sound(), 'meow');

// You can stub getters.
when(cat).calls(#lives).thenReturn(10);
expect(cat.lives, 10);

// You can stub a method for specific arguments.
when(cat).calls(#likes).withArgs(
  positional: ['fish'],
  named: {#isHungry: false},
).thenReturn(true);
expect(cat.likes('fish'), isTrue);

// You can verify the interaction for specific arguments.
verify(cat).called(#likes).withArgs(
  positional: ['fish'],
  named: {#isHungry: false},
).times(1);

// You can stub a method using argument matchers: `any` or `anyThat`.
when(cat).calls(#likes).withArgs(
  positional: [any],
  named: {#isHungry: anyThat(isFalse)},
).thenReturn(true);
expect(cat.likes('fish'), isTrue);

// You can stub a method to throw.
when(cat).calls(#sound).thenThrow(Exception('oops'));
expect(() => cat.sound(), throwsA(isA<Exception>()));

// You can calculate stubs dynamically.
final sounds = ['purrr', 'meow'];
when(cat).calls(#sound).thenAnswer((_) => sounds.removeAt(0));
expect(cat.sound(), 'purrr');
expect(cat.sound(), 'meow');

// You can capture any argument.
when(cat).calls(#likes).thenReturn(true);
expect(cat.likes('fish'), isTrue);
final captured = verify(cat).called(#likes)
  .withArgs(positional: [captureAny]).captured;
expect(captured.last, equals(['fish']));

// You can capture a specific argument based on a matcher.
when(cat).calls(#likes).thenReturn(true);
expect(cat.likes('fish'), isTrue);
expect(cat.likes('dog food'), isTrue);
final captured = verify(cat).called(#likes)
  .withArgs(positional: [captureAnyThat(startsWith('d'))]).captured;
expect(captured.last, equals(['dog food']));
```

## Resetting Mocks

```dart
reset(cat); // Reset stubs and interactions
```
