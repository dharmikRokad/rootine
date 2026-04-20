DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String dateKey(DateTime date) {
  final normalized = normalizeDate(date);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '${normalized.year}-$month-$day';
}
