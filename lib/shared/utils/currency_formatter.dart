import 'package:intl/intl.dart';

final _formatter = NumberFormat.currency(
  locale: 'it_IT',
  symbol: '',
  decimalDigits: 2,
);

String formatCurrency(num amount) {
  final formatted = _formatter.format(amount.abs()).trim();
  final sign = amount < 0 ? '-' : '';
  return '$sign€$formatted';
}

String formatCurrencyCompact(num amount) {
  final sign = amount < 0 ? '-' : '';
  final abs = amount.abs();
  if (abs >= 1000000) {
    return '$sign€${(abs / 1000000).toStringAsFixed(1)}M';
  } else if (abs >= 1000) {
    return '$sign€${(abs / 1000).toStringAsFixed(1)}K';
  }
  return formatCurrency(amount);
}
