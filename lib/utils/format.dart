String _two(int n) => n.toString().padLeft(2, '0');

/// Contoh: 14/11/2026 09:05
String formatDateTime(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';

/// Contoh: 8000 -> "Rp 8.000"
String formatRupiah(int value) {
  final s = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return 'Rp $buffer';
}
