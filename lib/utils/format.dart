/// Small formatting helpers (no external dependencies).

String money(double value) {
  final String s = value.round().abs().toString();
  final StringBuffer buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    buf.write(s[i]);
    final int remaining = s.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buf.write(',');
  }
  final String sign = value < 0 ? '-' : '';
  return '$sign ETB $buf';
}

String hourLabel(int hour) {
  final int h = hour % 24;
  final String am = h < 12 ? 'AM' : 'PM';
  int base = h % 12;
  if (base == 0) base = 12;
  return '$base$am';
}

String clockLabel(DateTime t) {
  final String mm = t.minute.toString().padLeft(2, '0');
  return '${hourLabel(t.hour)}:$mm';
}

String shortDate(DateTime t) {
  return '${t.day}/${t.month}/${t.year}';
}
