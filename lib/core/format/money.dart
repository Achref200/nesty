/// Formats monetary amounts for the Tunisian market.
///
/// Nestly prices are in Tunisian dinars (DT / TND). Amounts are shown as whole
/// dinars with space-grouped thousands, e.g. `1 900 DT`.
String formatDinars(double amount) {
  final digits = amount.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  final sign = amount < 0 ? '-' : '';
  return '$sign${buffer.toString()} DT';
}
