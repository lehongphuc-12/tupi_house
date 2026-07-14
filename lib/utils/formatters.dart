String formatVnd(double price) {
  final s = price.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final posFromRight = s.length - i;
    buffer.write(s[i]);
    if (posFromRight > 1 && posFromRight % 3 == 1) buffer.write('.');
  }
  return '${buffer.toString()}đ';
}
