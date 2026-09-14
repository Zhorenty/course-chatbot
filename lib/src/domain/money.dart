String formatRubFromKopecks(int kopecks) {
  final rub = kopecks / 100;
  if (kopecks % 100 == 0) {
    return '${rub.toStringAsFixed(0)} ₽';
  }
  return '${rub.toStringAsFixed(2)} ₽';
}

/// User-facing amount with a thousands separator: `15 000 ₽` or `15 000 руб.`
String formatRubSpaced(int kopecks, {String unit = '₽'}) {
  final negative = kopecks < 0;
  final abs = kopecks.abs();
  final rub = abs ~/ 100;
  final frac = abs % 100;
  final digits = rub.toString();
  final buf = StringBuffer();
  if (negative) {
    buf.write('−');
  }
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buf.write(' ');
    }
    buf.write(digits[i]);
  }
  if (frac != 0) {
    buf.write(',');
    buf.write(frac.toString().padLeft(2, '0'));
  }
  buf.write(' $unit');
  return buf.toString();
}

int rubToKopecks(int rub) => rub * 100;

/// Parses a kassa amount like `10000.00` without binary floating error.
int? parseRubStringToKopecks(String? raw) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  final negative = trimmed.startsWith('-');
  final unsigned = negative ? trimmed.substring(1) : trimmed;
  final parts = unsigned.split('.');
  if (parts.length > 2) {
    return null;
  }
  final rub = int.tryParse(parts[0]);
  if (rub == null) {
    return null;
  }
  var fraction = parts.length == 2 ? parts[1] : '00';
  if (fraction.isEmpty) {
    fraction = '00';
  }
  if (fraction.length == 1) {
    fraction = '${fraction}0';
  }
  if (fraction.length > 2) {
    fraction = fraction.substring(0, 2);
  }
  final kopecks = int.tryParse(fraction);
  if (kopecks == null) {
    return null;
  }
  final total = rub * 100 + kopecks;
  return negative ? -total : total;
}
