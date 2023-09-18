import 'dart:collection';

import 'package:backend/backend.dart';

Map<Position, Position> generate(int radius, int rings) {
  final ret = <Position, Position>{};

  for (int ring = 1; ring <= rings; ring++) {
    ret.addAll(generateRing(radius, ring));
  }

  return ret;
}

Map<Position, Position> generateRing(int radius, int ring) {
  final ret = LinkedHashMap<Position, Position>();
  final dia = radius * 2 + 1;
  final rp1 = radius + 1;

  int a = ring * dia;
  int c = -(a - ring * radius);
  int b = -(a + c);
  var base = [a, b, c];
  var indices = [0, 1, 2];

  for (int s = 0; s < 6; s++) {
    for (int j = 0; j < ring; j++) {
      var cur = base.toList();
      final mI = indices.indexOf(0);
      final nI = indices.indexOf(1);
      final oI = indices.indexOf(2);
      final mS = base[mI].isNegative? -1: 1;
      cur[mI] = (base[mI].abs() - rp1 * j) * mS;
      cur[oI] = (base[oI].abs() + radius * j) * -mS;
      cur[nI] = -(cur[mI] + cur[oI]);

      final res = [0, 0, 0];
      res[mI] = (ring - j) * mS;
      res[oI] = ring * -mS;
      res[nI] = -(res[mI] + res[oI]);

      final k = Position(q: cur[0], r: cur[1]);
      final v = Position(q: res[0], r: res[1]);
      // print('$k => $v');
      ret[k] = v;
    }
    base = negLeftShift(base);
    indices = leftShift(indices);
  }

  return ret;
}

List<int> leftShift(List<int> l) => [l[1], l[2], l[0]];

List<int> rightShift(List<int> l) => [l[2], l[0], l[1]];

List<int> negLeftShift(List<int> l) => [-l[1], -l[2], -l[0]];
