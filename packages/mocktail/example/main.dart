import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// A Real Cat class
class Cat {
  String sound() => 'meow!';
  bool likes(String food, {bool isHungry = false}) => false;
  final int lives = 9;
}

// A Mock Cat class
class MockCat extends Mock implements Cat {}

void main() {
  group('Cat', () {
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

      // // Verify the interaction.
      verify(() => cat.likes('fish', isHungry: true)).called(1);
    });
  });
}
