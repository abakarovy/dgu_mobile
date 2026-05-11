import 'package:flutter_html/src/css_parser.dart';

void main() {
  final s = inlineCssToStyle(
    'font-family: "Comic Sans MS"; font-size: 28px;',
    null,
  );
  // ignore: avoid_print
  print('fontSize: ${s?.fontSize?.value} unit: ${s?.fontSize?.unit}');
  // ignore: avoid_print
  print('fontFamily: ${s?.fontFamily}');
}
