import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  group(Fake, () {
    late _MyClass instance;

    setUp(() {
      instance = _MyFakeClass();
    });

    test('method invocation', () {
      expect(() => instance.f(), throwsUnimplementedError);
    });
    test('getter', () {
      expect(() => instance.x, throwsUnimplementedError);
    });
    test('setter', () {
      expect(() => instance.x = 0, throwsUnimplementedError);
    });
    test('operator', () {
      expect(() => instance + 1, throwsUnimplementedError);
    });
  });
}

class _MyClass {
  void f() {}

  int get x => 0;

  set x(int value) {}

  int operator +(int other) => 0;
}

class _MyFakeClass extends Fake implements _MyClass {}
