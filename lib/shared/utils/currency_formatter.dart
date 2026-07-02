import 'package:intl/intl.dart';

final _formatter = NumberFormat.currency(
  locale: 'it_IT',
  symbol: '€',
  decimalDigits: 2,
);

String formatCurrency(num amount) {
  return _formatter.format(amount);
}

String formatCurrencyCompact(num amount) {
  if (amount.abs() >= 1000000) {
    return '€${(amount / 1000000).toStringAsFixed(1)}M';
  } else if (amount.abs() >= 1000) {
    return '€${(amount / 1000).toStringAsFixed(1)}K';
  }
  return _formatter.format(amount);
}
