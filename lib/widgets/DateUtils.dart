class DateUtils {
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isDateRangeAvailable({
    required List<DateTime> unavailableDates,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final normalizedStart = normalizeDate(startDate);
    final normalizedEnd = normalizeDate(endDate);

    for (var date = normalizedStart;
    !date.isAfter(normalizedEnd);
    date = date.add(const Duration(days: 1))) {
      if (unavailableDates.any((unavailable) =>
      normalizeDate(unavailable) == date)) {
        return false;
      }
    }
    return true;
  }
}