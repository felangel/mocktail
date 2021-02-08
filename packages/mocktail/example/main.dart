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
      when(cat).calls(#sound).thenReturn('purr');

      // Interact with the mock.
      expect(cat.sound(), 'purr');

      // Verify the interaction.
      verify(cat).called(#sound).once();

      // Stub a method with parameters
      when(cat).calls(#likes).withArgs(
        positional: ['fish'],
        named: {#isHungry: false},
      ).thenReturn(true);
      expect(cat.likes('fish'), isTrue);

      // Verify the interaction.
      verify(cat).called(#likes).withArgs(
        positional: ['fish'],
        named: {#isHungry: false},
      ).once();
    });
  });
}
