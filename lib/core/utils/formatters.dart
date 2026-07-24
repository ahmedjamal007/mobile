import 'package:intl/intl.dart';

/// Shared display formatting so dates/prices look identical everywhere.
class Formatters {
  Formatters._();

  static final _date = DateFormat('EEE, d MMM yyyy');
  static final _time = DateFormat('h:mm a');
  static final _dateTime = DateFormat('d MMM yyyy · h:mm a');

  static String date(DateTime? dt) => dt == null ? '—' : _date.format(dt);
  static String time(DateTime? dt) => dt == null ? '—' : _time.format(dt);
  static String dateTime(DateTime? dt) =>
      dt == null ? '—' : _dateTime.format(dt);

  /// Sudanese Pound. Adjust symbol/locale once the backend confirms currency.
  static String money(num? value) {
    if (value == null) return '—';
    final f = NumberFormat.currency(symbol: 'SDG ', decimalDigits: 0);
    return f.format(value);
  }

  /// Human "2h ago" style for notification timestamps.
  static String relative(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _date.format(dt);
  }
}
