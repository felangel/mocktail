import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class Foo {
  String? returnsNullableString() => 'Hello';

  String returnsNonNullableString() => 'Hello';
}

class MockFoo extends Mock implements Foo {}

void main() {
  late MockFoo mock;

  setUp(() {
    mock = MockFoo();
  });

  tearDown(resetMocktailState);

  group('Using nSM out of the box,', () {
    test('nSM returns the dummy value during method stubbing', () {
      // Trigger method stubbing.
      final whenCall = when;
      final stubbedResponse = mock.returnsNullableString();
      expect(stubbedResponse, equals(null));
      whenCall(() => stubbedResponse).thenReturn('A');
    });

    test('nSM returns the dummy value during method call verification', () {
      when(() => mock.returnsNullableString()).thenReturn('A');

      // Make a real call.
      final realResponse = mock.returnsNullableString();
      expect(realResponse, equals('A'));

      // Trigger method call verification.
      final verifyCall = verify;
      final verificationResponse = mock.returnsNullableString();
      expect(verificationResponse, equals(null));
      verifyCall(() => verificationResponse);
    });

    test(
        'nSM returns the dummy value during method call verification, using '
        'verifyNever', () {
      // Trigger method call verification.
      final verifyNeverCall = verifyNever;
      final verificationResponse = mock.returnsNullableString();
      expect(verificationResponse, equals(null));
      verifyNeverCall(() => verificationResponse);
    });
  });
}
