String _twoDigits(int value) => value.toString().padLeft(2, '0');

String formatEventDateTime(DateTime value) {
  final local = value.toLocal();
  final dd = _twoDigits(local.day);
  final mm = _twoDigits(local.month);
  final hh = _twoDigits(local.hour);
  final min = _twoDigits(local.minute);

  return '$dd.$mm.${local.year} $hh:$min';
}

String formatEventTime(DateTime value) {
  final local = value.toLocal();
  return '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

bool isSameLocalCalendarDay(DateTime a, DateTime b) {
  final localA = a.toLocal();
  final localB = b.toLocal();

  return localA.year == localB.year &&
      localA.month == localB.month &&
      localA.day == localB.day;
}

String formatEventDateRange(DateTime startAt, DateTime endAt) {
  if (isSameLocalCalendarDay(startAt, endAt)) {
    // For same-day events, showing end time is enough and avoids redundant date text.
    return '${formatEventDateTime(startAt)} - ${formatEventTime(endAt)}';
  }

  return '${formatEventDateTime(startAt)} - ${formatEventDateTime(endAt)}';
}
