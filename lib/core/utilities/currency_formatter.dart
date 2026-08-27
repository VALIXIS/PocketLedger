import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatCents(int cents, String currencyCode) {
    final doubleAmount = cents / 100.0;
    // Map common currency codes to ensure correct formatting
    try {
      final format = NumberFormat.simpleCurrency(name: currencyCode);
      return format.format(doubleAmount);
    } catch (_) {
      // Fallback in case of invalid locale or currency code
      final format = NumberFormat.currency(symbol: currencyCode);
      return format.format(doubleAmount);
    }
  }

  static String formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
}
