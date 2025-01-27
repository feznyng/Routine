enum ConditionType { 
  todo,
  nfc,
  location,
  exercise,
}

abstract class Condition {
  DateTime? _lastCompleted;

  bool complete() {
    if (verify()) {
      _lastCompleted = DateTime.now();
      return true;
    }

    return false;
  }
  

  bool verify();

  bool isComplete(int startTime, int endTime) {
    if (_lastCompleted == null) {
      return false;
    }

    final int lastCompletedTimestamp = _lastCompleted!.hour * 60 + _lastCompleted!.minute;
    return lastCompletedTimestamp >= startTime && lastCompletedTimestamp <= endTime;
  }
}