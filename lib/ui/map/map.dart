import 'dart:math';

import 'package:backend/backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapeditor/main.dart';
import 'package:mapeditor/ui/hex_widget/hex_widget.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:mapeditor/util/generate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({Key? key}) : super(key: key);

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with AfterInit {
  HexSize tileSize = HexSize(82);
  Point<double> viewportSize = const Point(0, 0);
  Position center = const Position();
  _MoveData? _moveData;
  int index = 0;
  final focusNode = FocusNode();
  int provinceRadius = 2;

  @override
  void afterInit() {
    final prefs = context.findAncestorStateOfType<MyHomePageState>()!.prefs;
    /*for (final key in prefs.getKeys()) {
      print(key);
      if(key.startsWith('map')) {
        prefs.setInt('2.$key', prefs.getInt(key)!);
        prefs.remove(key);
      }
    }*/
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _build);
  }

  Widget _build(BuildContext context, BoxConstraints constraints) {
    final maxRings = max<int>(
        (constraints.maxWidth.toInt() / tileSize.width).ceil(),
        (constraints.maxHeight / tileSize.height).ceil());

    viewportSize = Point(constraints.maxWidth, constraints.maxHeight);

    final children = <Widget>[];
    for (int i = 0; i < maxRings; i++) {
      final ring = center.getSpiralRing(i);
      for (final pos in ring) {
        final diff = pos - center;
        double left = (viewportSize.x / 2) - (tileSize.width / 2);
        left += diff.q * tileSize.horizontalDistance +
            diff.r * (tileSize.width / 2);

        double top = (viewportSize.y / 2) - (tileSize.height / 2);
        top += diff.r * tileSize.verticalDistance;

        children.add(Positioned(
            left: left,
            top: top,
            width: tileSize.width,
            height: tileSize.height,
            child: HexTile(pos, tileSize, provinceRadius, index)));
      }
    }

    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (value) {
        if (value.physicalKey.usbHidUsage >=
                PhysicalKeyboardKey.numpad1.usbHidUsage &&
            value.physicalKey.usbHidUsage <=
                PhysicalKeyboardKey.numpad9.usbHidUsage) {
          setState(() {
            provinceRadius = value.physicalKey.usbHidUsage -
                PhysicalKeyboardKey.numpad1.usbHidUsage +
                1;
          });
          return;
        }
        if (value.logicalKey.keyId >= 48 || value.logicalKey.keyId <= 57) {
          int v = value.logicalKey.keyId - 48;
          setState(() {
            index = v % colors.length;
          });
        }
      },
      child: XGestureDetector(
        child: Container(
          color: Colors.black,
          child: Stack(
            children: children,
          ),
        ),
        onScrollEvent: (event) {
          if (event.scrollDelta.dy.isNegative) {
            setState(() {
              tileSize = HexSize(tileSize.height * 1.1);
            });
          } else {
            setState(() {
              tileSize = HexSize(tileSize.height * 0.9);
            });
          }
        },
        onMoveStart: (MoveEvent event) {
          _moveData = _MoveData(startCenter: center, startPos: event.localPos);
        },
        onMoveUpdate: (MoveEvent event) {
          final change =
              event.localPos.toPoint() - _moveData!.startPos.toPoint();
          final posDiff = Position.fromPoint(change, tileSize);
          final newCenter = _moveData!.startCenter - posDiff;
          // print('$change $posDiff $center $newCenter');
          if (newCenter != center) {
            setState(() {
              center = newCenter;
            });
          }
        },
        onMoveEnd: (MoveEvent event) {
          final change =
              event.localPos.toPoint() - _moveData!.startPos.toPoint();
          final posDiff = Position.fromPoint(change, tileSize);
          final newCenter = _moveData!.startCenter - posDiff;
          if (newCenter != center) {
            setState(() {
              center = newCenter;
            });
          }
          _moveData = null;
        },
      ),
    );
  }
}

class _MoveData {
  Position startCenter;

  Offset startPos;

  _MoveData({required this.startCenter, required this.startPos});
}

class HexTile extends StatefulWidget {
  final Position pos;

  final HexSize size;

  final int selIndex;

  final int provinceRadius;

  const HexTile(this.pos, this.size, this.provinceRadius, this.selIndex,
      {Key? key})
      : super(key: key);

  @override
  State<HexTile> createState() => _HexTileState();
}

class _HexTileState extends State<HexTile> with AfterInit {
  Position get pos => widget.pos;

  HexSize get size => widget.size;

  int get provinceRadius => widget.provinceRadius;

  late final SharedPreferences prefs;

  @override
  void afterInit() {
    prefs = context.findAncestorStateOfType<MyHomePageState>()!.prefs;
  }

  int get index {
    final key = '$provinceRadius.map.${pos.id}';
    return prefs.getInt(key) ?? 0;
  }

  @override
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          prefs.setInt('$provinceRadius.map.${pos.id}', widget.selIndex);
        });
      },
      onSecondaryTap: () {
        setState(() {
          prefs.setInt('$provinceRadius.map.${pos.id}', widget.selIndex);
        });
      },
      child: HexagonWidget(
        width: size.width,
        height: size.height,
        color: colors[index % colors.length],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${pos.qrs}', style: ts),
            /*if (local.q != 0 || local.r != 0)
              Text(local.id, style: ts.copyWith(fontWeight: FontWeight.bold))
            else
              Text('-', style: ts),*/
            if (mappings.containsKey(pos))
              Text(mappings[pos]!.qrs,
                  style: ts.copyWith(fontWeight: FontWeight.bold))
            else
              Text('-', style: ts),
            // Text('${pos.distanceFromOriginFloat} ${pos.sum}', style: ts),
            Text('${pos.rotate30.qrs}', style: ts),
            // Text('${pos.toLocal(2)}', style: ts),
          ],
        ),
      ),
    );
  }

  TextStyle get ts => const TextStyle(fontSize: 10, overflow: TextOverflow.fade);
}

final colors = [
  Colors.white,
  Colors.blue,
  Colors.orange,
  Colors.redAccent,
  Colors.lightGreenAccent,
  Colors.purpleAccent,
  Colors.limeAccent,
  Colors.grey,
];

final mappings = generate(2, 15);

extension on Position {
  Position get rotate30 {
    if(this == Position(q: -10, r: 4)) {
      print('here');
    }

    final l = [q, r, s];
    final z = max(l[0].abs(), max(l[1].abs(), l[2].abs()));
    int mIndex;
    int nIndex;
    int oIndex;
    if (l[0] == 0) {
      mIndex = 1;
      nIndex = 2;
      oIndex = 0;
    } else if (l[1] == 0) {
      mIndex = 2;
      nIndex = 0;
      oIndex = 1;
    } else if (l[2] == 0) {
      mIndex = 0;
      nIndex = 1;
      oIndex = 2;
    } else {
      mIndex = l.indexWhere((e) => e.abs() == z);
      nIndex = (mIndex + 1) % 3;
      oIndex = (mIndex + 2) % 3;
    }

    final nOld = l[nIndex];
    final shift = z ~/ 2;
    l[nIndex] += (l[nIndex].isNegative ? 1 : -1) * shift;
    if (nOld.isNegative == l[nIndex].isNegative) {
      l[oIndex] = -(l[mIndex] + l[nIndex]);
    } else {
      l[oIndex] = -l[mIndex];
      l[mIndex] = -(l[oIndex] + l[nIndex]);
    }

    return Position(q: l[0], r: l[1]);
  }

  Position toLocal(final int radius) {
    final dia = 2 * radius + 1;
    var q = rotate30.q / dia;
    if(q.isNegative) q = q.floorToDouble(); else q = q.ceilToDouble();
    var r = rotate30.r / dia;
    if(r.isNegative) r = r.floorToDouble(); else r = r.ceilToDouble();
    return Position(q: q.toInt(), r: r.toInt());
  }

  /*Position toLocal(final int radius) {
    final dia = 2 * radius + 1;
    final d = (distanceFromOriginFloat / dia).ceil();

    final radP1 = radius + 1;
    final dia2 = dia * 2;

    if (q == d || r == d || s == d) {
      // TODO
    }

    if (q % dia == 0 && r % radius == 0 && sum % dia2 == 0) {
      return Position(q: q ~/ dia, r: r ~/ radius);
    }
    /*if (q % radius == 0 && r % radP1 == 0 && sum % dia2 == 0) {
      return Position(q: (q / radius).ceil(), r: 0);
    }
    if (q % radP1 == 0 && r % dia == 0 && sum % dia2 == 0) {
      return Position(q: 0, r: r ~/ dia);
    }*/

    return Position();
  }*/

  int get sum => q.abs() + r.abs() + s.abs();
}

extension DoublePointExt on Point<double> {
  Point<int> toInt() => Point<int>(x.toInt(), y.toInt());
}

extension OffsetExt on Offset {
  Point<double> toPoint() => Point<double>(dx, dy);
}

class TileData {
  final Position position;

  int index = 0;

  TileData(this.position);
}

mixin AfterInit {
  bool _onlyOnce = false;

  void didChangeDependencies() {
    triggerAfterInit();
  }

  void triggerAfterInit() {
    if (_onlyOnce) return;

    afterInit();
    _onlyOnce = true;
  }

  void afterInit();
}
