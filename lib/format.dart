import 'i18n.dart';

String num0(num v) {
  final n = v.round();
  final neg = n < 0;
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return neg ? '-$b' : b.toString();
}

String money(num v) => 'TZS ${num0(v)}';

/// Targets are rounded up to the next whole shilling.
String moneyUp(num v) => money(v.ceil());

String fmtDate(DateTime d) => '${d.day} ${monthShort(d.month)} ${d.year}';

String shortDate(DateTime d) => '${d.day} ${monthShort(d.month)}';

/// Short form for tiles: 15k, 1.2M.
String compact(num v) {
  final a = v.abs();
  String out;
  if (a >= 1000000) {
    final m = a / 1000000;
    out = '${m >= 10 ? m.toStringAsFixed(0) : m.toStringAsFixed(1)}M';
  } else if (a >= 1000) {
    final k = a / 1000;
    out = '${k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}k';
  } else {
    out = a.round().toString();
  }
  out = out.replaceAll('.0M', 'M').replaceAll('.0k', 'k');
  return v < 0 ? '-$out' : out;
}
