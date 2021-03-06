part of 'mocktail.dart';

class _TimeStampProvider {
  int _now = 0;
  DateTime now() {
    var candidate = DateTime.now();
    if (candidate.millisecondsSinceEpoch <= _now) {
      candidate = DateTime.fromMillisecondsSinceEpoch(_now + 1);
    }
    _now = candidate.millisecondsSinceEpoch;
    return candidate;
  }
}
