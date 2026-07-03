import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _RealClass {
  String? methodWithStringArgs(String? x) => 'Real';
  String? methodWithTwoStringArgs(String? x, String? y) => 'Real';
  String? methodWithNamedStringArgs({String? x}) => 'Real';
  String? methodWithListArgs(List<int>? x) => 'Real';
  String? methodWithMapArgs(Map<String, int>? x) => 'Real';
  String? methodWithNormalArgs(int? x) => 'Real';
  String? otherMethodWithStringArgs(String? x) => 'Real';
}

class _MockedClass extends Mock implements _RealClass {}

String failureMessageOf(void Function() expectedToFail) {
  try {
    expectedToFail();
  } on TestFailure catch (e) {
    return e.message ?? '';
  }
  fail('It was expected to fail!');
}

void main() {
  late _MockedClass mock;

  const longString =
      'Your next step is to upload the app bundle to the Play Store: '
      'build/app/outputs/bundle/release/app-release.aab';

  setUp(() {
    mock = _MockedClass();
  });

  tearDown(resetMocktailState);

  group('verify argument diffs', () {
    test('describes the diff when a long string argument mismatches', () {
      mock.methodWithStringArgs(longString.replaceFirst('bundle', 'bundel'));
      final message = failureMessageOf(
        () => verify(() => mock.methodWithStringArgs(longString)),
      );
      expect(message, contains('No matching calls.'));
      expect(
        message,
        contains('Closest matching call: methodWithStringArgs'),
      );
      expect(message, contains('positional argument #0'));
      expect(message, contains('Differ at offset'));
    });

    test('describes the diff when a multiline string argument mismatches', () {
      mock.methodWithStringArgs('first\nsecond');
      final message = failureMessageOf(
        () => verify(() => mock.methodWithStringArgs('first\nsecund')),
      );
      expect(
        message,
        contains('Closest matching call: methodWithStringArgs'),
      );
      expect(message, contains('Differ at offset'));
    });

    test('describes the diff for a mismatched named string argument', () {
      mock.methodWithNamedStringArgs(
        x: longString.replaceFirst('bundle', 'bundel'),
      );
      final message = failureMessageOf(
        () => verify(() => mock.methodWithNamedStringArgs(x: longString)),
      );
      expect(
        message,
        contains('Closest matching call: methodWithNamedStringArgs'),
      );
      expect(message, contains("named argument 'x'"));
      expect(message, contains('Differ at offset'));
    });

    test('describes the mismatched location for a large list argument', () {
      mock.methodWithListArgs([1, 2, 3, 4, 5, 6, 7]);
      final message = failureMessageOf(
        () => verify(() => mock.methodWithListArgs([1, 2, 3, 9, 5, 6, 7])),
      );
      expect(
        message,
        contains('Closest matching call: methodWithListArgs'),
      );
      expect(message, contains('at location [3]'));
    });

    test('describes the mismatched location for a large map argument', () {
      mock.methodWithMapArgs(
        {'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5, 'f': 6},
      );
      final message = failureMessageOf(
        () => verify(
          () => mock.methodWithMapArgs(
            {'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5, 'f': 9},
          ),
        ),
      );
      expect(
        message,
        contains('Closest matching call: methodWithMapArgs'),
      );
      expect(message, contains("at location ['f']"));
    });

    test('only describes the arguments that mismatch', () {
      mock.methodWithTwoStringArgs('$longString a', 'same');
      final message = failureMessageOf(
        () => verify(
          () => mock.methodWithTwoStringArgs('$longString b', 'same'),
        ),
      );
      expect(message, contains('positional argument #0'));
      expect(message, isNot(contains('positional argument #1')));
    });

    test('describes the closest call when multiple calls mismatch', () {
      mock
        ..methodWithTwoStringArgs('$longString a', 'different')
        ..methodWithTwoStringArgs('$longString a', 'same');
      final message = failureMessageOf(
        () => verify(
          () => mock.methodWithTwoStringArgs('$longString b', 'same'),
        ),
      );
      expect(message, contains('positional argument #0'));
      expect(message, isNot(contains('positional argument #1')));
    });

    test('keeps the short form for small values', () {
      mock.methodWithNormalArgs(17);
      final message = failureMessageOf(
        () => verify(() => mock.methodWithNormalArgs(18)),
      );
      expect(message, contains('No matching calls.'));
      expect(message, isNot(contains('Closest matching call')));
    });

    test('keeps the short form for short strings', () {
      mock.methodWithStringArgs('foo');
      final message = failureMessageOf(
        () => verify(() => mock.methodWithStringArgs('bar')),
      );
      expect(message, isNot(contains('Closest matching call')));
    });

    test('keeps the short form for small collections', () {
      mock.methodWithListArgs([42]);
      final message = failureMessageOf(
        () => verify(() => mock.methodWithListArgs([43])),
      );
      expect(message, isNot(contains('Closest matching call')));
    });

    test('does not describe calls to a different member', () {
      mock.otherMethodWithStringArgs(longString);
      final message = failureMessageOf(
        () => verify(() => mock.methodWithStringArgs(longString)),
      );
      expect(message, contains('No matching calls.'));
      expect(message, isNot(contains('Closest matching call')));
    });

    test('describes the diff for a matcher argument with a long actual', () {
      mock.methodWithStringArgs(longString.replaceFirst('bundle', 'bundel'));
      final message = failureMessageOf(
        () => verify(
          () => mock.methodWithStringArgs(any(that: equals(longString))),
        ),
      );
      expect(
        message,
        contains('Closest matching call: methodWithStringArgs'),
      );
      expect(message, contains('Differ at offset'));
    });
  });
}
