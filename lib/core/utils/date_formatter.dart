import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String format(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  static String formatWithTime(DateTime date) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(date);

  static String formatShort(DateTime date) => DateFormat('dd/MM/yy').format(date);

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return format(date);
  }
}
