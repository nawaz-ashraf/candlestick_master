class AppDateUtils {
  const AppDateUtils._();

  static String dateKey(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  static String todayKey() => dateKey(DateTime.now());

  static String yesterdayKey() {
    return dateKey(DateTime.now().subtract(const Duration(days: 1)));
  }
}
