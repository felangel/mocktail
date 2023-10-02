/// A fake is an object that can be used as a drop-in replacement for another
/// object in tests. Unlike a mock, it does not have any expectations about how
/// it is used, and it does not record how it is used. It simply has a
/// `noSuchMethod` implementation that does not throw a
/// [NoSuchMethodError], but instead throws an [UnimplementedError]
/// with the name of the invoked method.
///
/// Fields and methods that are exercised by the code
/// under test should be manually overridden in the implementing class.
///
/// A fake does not have any support for verification or defining behavior from
/// the test so it cannot be used as a mock.
abstract class Fake {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(invocation.memberName.toString().split('"')[1]);
  }
}
