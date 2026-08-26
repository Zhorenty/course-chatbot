String formatRubFromKopecks(int kopecks) {
  final rub = kopecks / 100;
  if (kopecks % 100 == 0) {
    return '${rub.toStringAsFixed(0)} ₽';
  }
  return '${rub.toStringAsFixed(2)} ₽';
}

int rubToKopecks(int rub) => rub * 100;
