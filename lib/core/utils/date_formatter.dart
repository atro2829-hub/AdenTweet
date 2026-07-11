import 'package:timeago/timeago.dart' as timeago;

class DateFormatter {
  DateFormatter._();

  static void init() {
    timeago.setLocaleMessages('ar', timeago.ArMessages());
  }

  /// Formats a [DateTime] to a relative time string (e.g. "3 minutes ago").
  static String formatRelative(DateTime date, {String locale = 'en'}) {
    return timeago.format(date, locale: locale);
  }

  /// Formats a [DateTime] to a short date string (e.g. "Jan 15, 2024").
  static String formatShortDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Formats a [DateTime] to a time string (e.g. "2:30 PM").
  static String formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Returns "· hh:mm MM dd, yyyy" format used in tweet detail views.
  static String formatFull(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '$hour:$minute $period · ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}