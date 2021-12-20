import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class Food {}

class Chicken extends Food {}

class Tuna extends Food {}

// A Real Cat class
class Cat {
  String sound() => 'meow!';
  bool likes(String food, {bool isHungry = false}) => false;
  void eat<T extends Food>(T food) {}
  final int lives = 9;
}

// A Mock Cat class
class MockCat extends Mock implements Cat {}

void main() {
  group('Cat', () {
    setUpAll(() {
      // Register fallback values when using
      // `any` or `captureAny` with custom objects.
      registerFallbackValue(Chicken());
      registerFallbackValue(Tuna());
    });

    late Cat cat;

    setUp(() {
      cat = MockCat();
    });

    test('example', () {
      // Stub a method before interacting with the mock.
      when(() => cat.sound()).thenReturn('purr');

      // Interact with the mock.
      expect(cat.sound(), 'purr');

      // Verify the interaction.
      verify(() => cat.sound()).called(1);

      // Stub a method with parameters
      when(
        () => cat.likes('fish', isHungry: any(named: 'isHungry')),
      ).thenReturn(true);
      expect(cat.likes('fish', isHungry: true), isTrue);

      // Verify the interaction.
      verify(() => cat.likes('fish', isHungry: true)).called(1);

      // Interact with the mock.
      cat
        ..eat(Chicken())
        ..eat(Tuna());

      // Verify the interaction with specific type arguments.
      verify(() => cat.eat<Chicken>(any())).called(1);
      verify(() => cat.eat<Tuna>(any())).called(1);
      verifyNever(() => cat.eat<Food>(any()));
    });
  });
}
