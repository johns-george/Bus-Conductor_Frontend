import 'package:intl/intl.dart';

class DateFormatting {
  const DateFormatting._();

  static final DateFormat _dayMonth = DateFormat('EEE, d MMM');
  static final DateFormat _monthShort = DateFormat('d MMM');
  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _weekday = DateFormat('EEEE');

  static String travelDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 0 && diff < 7) return _weekday.format(date);
    return _dayMonth.format(date);
  }

  static String shortDate(DateTime date) => _monthShort.format(date);
  static String time(DateTime date) => _time.format(date);

  static String relativeTime(DateTime date, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final diff = date.difference(now);
    final abs = diff.abs();
    if (abs.inMinutes < 1) return 'just now';
    if (abs.inMinutes < 60) {
      final m = abs.inMinutes;
      return diff.isNegative ? '$m min ago' : 'in $m min';
    }
    if (abs.inHours < 24) {
      final h = abs.inHours;
      return diff.isNegative ? '$h hr ago' : 'in $h hr';
    }
    return _dayMonth.format(date);
  }

  static String durationShort(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}
