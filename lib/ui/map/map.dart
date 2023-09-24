import 'dart:math';

import 'package:backend/backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapeditor/main.dart';
import 'package:mapeditor/ui/hex_widget/hex_widget.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:mapeditor/ui/map/measure_size.dart';
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
  int provinceRadius = 5;

  @override
  void afterInit() {
    final prefs = context.findAncestorStateOfType<MyHomePageState>()!.prefs;
  }

  List<Widget> _children = [];

  void _rebuild() {
    final int maxRings = max((viewportSize.x.toInt() / tileSize.width).ceil(),
        (viewportSize.y / tileSize.height).ceil());

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

    setState(() {
      _children = children;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MeasureSize(
      onChange: (value) {
        viewportSize = Point(value.width, value.height);
        _rebuild();
      },
      child: KeyboardListener(
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
              children: _children,
            ),
          ),
          onScrollEvent: (event) {
            HexSize size;
            if (event.scrollDelta.dy.isNegative) {
              size = HexSize(tileSize.height * 1.1);
            } else {
              size = HexSize(tileSize.height * 0.9);
            }
            if (!size.isEqual(tileSize)) {
              tileSize = size;
              _rebuild();
            }
          },
          onMoveStart: (MoveEvent event) {
            _moveData =
                _MoveData(startCenter: center, startPos: event.localPos);
          },
          onMoveUpdate: (MoveEvent event) {
            final change =
                event.localPos.toPoint() - _moveData!.startPos.toPoint();
            final posDiff = Position.fromPoint(change, tileSize);
            final newCenter = _moveData!.startCenter - posDiff;
            // print('$change $posDiff $center $newCenter');
            if (newCenter != center) {
              center = newCenter;
              _rebuild();
            }
          },
          onMoveEnd: (MoveEvent event) {
            final change =
                event.localPos.toPoint() - _moveData!.startPos.toPoint();
            final posDiff = Position.fromPoint(change, tileSize);
            final newCenter = _moveData!.startCenter - posDiff;
            if (newCenter != center) {
              center = newCenter;
              _rebuild();
            }
            _moveData = null;
          },
        ),
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
            Text('${pos.toProvinceAddress(provinceRadius).qrs}', style: ts),
          ],
        ),
      ),
    );
  }

  TextStyle get ts =>
      const TextStyle(fontSize: 10, overflow: TextOverflow.fade);
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
