import 'package:mocktail/src/mocktail.dart';
import 'package:test/test.dart';

void main() {
  const stub = Stub();

  group('$isInvocation', () {
    test('positional arguments', () {
      stub.say('Hello');
      final call1 = Stub.lastInvocation;
      stub.say('Hello');
      final call2 = Stub.lastInvocation;
      stub.say('Guten Tag');
      final call3 = Stub.lastInvocation;
      shouldPass(call1, isInvocation(call2));
      shouldFail(
        call1,
        isInvocation(call3),
        "Expected: say('Guten Tag') "
        "Actual: <Instance of '${call3.runtimeType}'> "
        "Which: Does not match say('Hello')",
      );
    });

    test('positional arguments (arg matcher)', () {
      stub.say('Hello');
      final call1 = Stub.lastInvocation;
      shouldPass(
        isInvocation(call1).matches(
          Invocation.method(#say, [const ArgMatcher(anything, '', false)]),
          <dynamic, dynamic>{},
        ),
        isTrue,
      );
    });

    test('named arguments', () {
      stub.eat('Chicken', alsoDrink: true);
      final call1 = Stub.lastInvocation;
      stub.eat('Chicken', alsoDrink: true);
      final call2 = Stub.lastInvocation;
      stub.eat('Chicken', alsoDrink: false);
      final call3 = Stub.lastInvocation;
      shouldPass(call1, isInvocation(call2));
      shouldFail(
        call1,
        isInvocation(call3),
        "Expected: eat('Chicken', 'alsoDrink: false') "
        "Actual: <Instance of '${call3.runtimeType}'> "
        "Which: Does not match eat('Chicken', 'alsoDrink: true')",
      );
    });

    test('type arguments', () {
      stub.calculate<int>();
      final call1 = Stub.lastInvocation;
      stub.calculate<int>();
      final call2 = Stub.lastInvocation;
      stub.calculate();
      final call3 = Stub.lastInvocation;
      shouldPass(call1, isInvocation(call2));

      shouldFail(
        call1,
        isInvocation(call3),
        'Expected: calculate<Type:<num>>() '
        "Actual: <Instance of '${call3.runtimeType}'> "
        // ignore: missing_whitespace_between_adjacent_strings
        'Which: Does not match calculate'
        '<Type:<int>>()',
      );
    });

    test('optional arguments', () {
      stub.lie(true);
      final call1 = Stub.lastInvocation;
      stub.lie(true);
      final call2 = Stub.lastInvocation;
      stub.lie(false);
      final call3 = Stub.lastInvocation;
      shouldPass(call1, isInvocation(call2));
      shouldFail(
        call1,
        isInvocation(call3),
        'Expected: lie(<false>) '
        "Actual: <Instance of '${call3.runtimeType}'> "
        'Which: Does not match lie(<true>)',
      );
    });

    test('getter', () {
      stub.value;
      final call1 = Stub.lastInvocation;
      stub.value;
      final call2 = Stub.lastInvocation;
      stub.value = true;
      final call3 = Stub.lastInvocation;
      shouldPass(call1, isInvocation(call2));
      shouldFail(
        call1,
        isInvocation(call3),
        // RegExp needed because of https://github.com/dart-lang/sdk/issues/33565
        RegExp('Expected: set value=? <true> '
            "Actual: <Instance of '${call3.runtimeType}'> "
            'Which: Does not match get value'),
      );
    });

    test('setter', () {
      stub.value = true;
      final call1 = Stub.lastInvocation;
      stub.value = true;
      final call2 = Stub.lastInvocation;
      stub.value = false;
      final call3 = Stub.lastInvocation;
      shouldPass(call1, isInvocation(call2));
      shouldFail(
        call1,
        isInvocation(call3),
        // RegExp needed because of https://github.com/dart-lang/sdk/issues/33565
        RegExp('Expected: set value=? <false> '
            "Actual: <Instance of '${call3.runtimeType}'> "
            'Which: Does not match set value=? <true>'),
      );
    });

    test('describeMismatch', () {
      stub.value = false;
      final matcher = isInvocation(Stub.lastInvocation);
      final description = MockDescription();
      when(() => description.add(any())).thenReturn(description);
      matcher.describeMismatch(
        Object(),
        description,
        <dynamic, dynamic>{},
        false,
      );
      verify(() => description.add('Is not an Invocation')).called(1);
    });
  });
}

abstract class Interface {
  bool? get value;
  set value(bool? value);
  void say(String text);
  void eat(String food, {bool? alsoDrink});
  // ignore: avoid_positional_boolean_parameters
  void lie([bool? facingDown]);
  void fly({int? miles});
  void calculate<A extends num>();
  bool? property;
}

class MockDescription extends Mock implements Description {}

/// An example of a class that captures Invocation objects.
///
/// Any call always returns an [Invocation].
class Stub implements Interface {
  const Stub();

  static late Invocation lastInvocation;

  @override
  void noSuchMethod(Invocation invocation) {
    lastInvocation = invocation;
  }
}

// Inspired by shouldFail() from package:test, which doesn't expose it to users.
void shouldFail(dynamic value, Matcher matcher, dynamic expected) {
  const reason = 'Expected to fail.';
  try {
    expect(value, matcher);
    fail(reason);
  } on TestFailure catch (e) {
    final dynamic matcher = expected is String
        ? equalsIgnoringWhitespace(expected)
        : expected is RegExp
            ? contains(expected)
            : expected;
    expect(collapseWhitespace(e.message ?? ''), matcher, reason: reason);
  }
}

void shouldPass(dynamic value, Matcher matcher) {
  expect(value, matcher);
}
