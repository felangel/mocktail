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

    test('...', () {
      when(() => cat.sound()).thenReturn('purr');
      when(() => cat.likes('fish')).thenReturn(true);

      expect(cat.sound(), equals('purr'));
      expect(cat.likes('fish'), isTrue);

      verifyInOrder([() => cat.sound(), () => cat.likes('fish')]);
      verifyNoMoreInteractions(cat);
    });

    test('example', () {
      // Stub a method before interacting with the mock.
      when(() => cat.sound()).thenReturn('purr');

      // Interact with the mock.
      expect(cat.sound(), 'purr');

      // Verify the interaction.
      verify(() => cat.sound()).called(1);

      // Stub a method with parameters
      when(() => cat.likes('fish', isHungry: false)).thenReturn(true);
      expect(cat.likes('fish'), isTrue);

      // // Verify the interaction.
      verify(() => cat.likes('fish', isHungry: false)).called(1);
    });
  });
}
