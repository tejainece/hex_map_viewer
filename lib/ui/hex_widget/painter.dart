import 'package:flutter/material.dart';

class HexagonClipper extends CustomClipper<Path> {
  HexagonClipper();

  @override
  Path getClip(Size size) {
    return hexagonPath(size);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

Path hexagonPath(Size size) {
  final h4 = size.height / 4;
  final w2 = size.width / 2;

  final ret = Path()
    ..moveTo(w2, 0) // top mid
    ..lineTo(0, h4) // left top
    ..lineTo(0, h4 * 3) // left bot
    ..lineTo(w2, size.height) // bot mid
    ..lineTo(size.width, h4 * 3) // right bot
    ..lineTo(size.width, h4) // right top
    ..lineTo(w2, 0) // top mid
    ..close();

  return ret;
}
