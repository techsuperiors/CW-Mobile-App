import 'package:intl/intl.dart';

class RequestGroupingUtils {
  static List<dynamic> groupByMonth<T>({
    required List<T> items,
    required DateTime Function(T item) dateSelector,
  }) {
    final result = <dynamic>[];
    String? lastMonth;

    for (final item in items) {
      final monthLabel = DateFormat('MMMM yyyy').format(dateSelector(item));
      if (monthLabel != lastMonth) {
        result.add(monthLabel);
        lastMonth = monthLabel;
      }
      result.add(item);
    }

    return result;
  }
}
