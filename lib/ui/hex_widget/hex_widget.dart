import 'package:flutter/material.dart';
import 'painter.dart';

class HexagonBorder {
  final Color color;

  final double thickness;

  const HexagonBorder({required this.color, required this.thickness});

  @override
  bool operator ==(other) {
    return other is HexagonBorder &&
        color == other.color &&
        thickness == other.thickness;
  }
}

class HexagonWidget extends StatelessWidget {
  final double width;
  final double height;
  final double elevation;
  final Widget? child;
  final Color? color;
  final HexagonBorder? border;
  final bool clip;

  const HexagonWidget({
    Key? key,
    required this.width,
    required this.height,
    this.color,
    this.child,
    this.elevation = 0,
    this.border,
    this.clip = false,
  })  : assert(elevation >= 0),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget ch = child ?? Container();
    if (clip) {
      ch = ClipPath(
        clipper: HexagonClipper(),
        child: child,
      );
    }

    return Container(
      width: width,
      height: height,
      // color: Colors.red,
      child: CustomPaint(
        painter: HexagonPainter(
          color: color,
          border: border,
          elevation: elevation,
        ),
        child: ch,
      ),
    );

    /*
    ClipPath(
          clipper: HexagonClipper(),
          child: OverflowBox(
            alignment: Alignment.center,
            maxHeight: contentSize.height,
            maxWidth: contentSize.width,
            child: Align(
              alignment: Alignment.center,
              child: child,
            ),
          ),
        )
     */
  }
}

class HexagonPainter extends CustomPainter {
  HexagonPainter({this.color, this.elevation = 0, this.border});

  final double elevation;
  final Color? color;
  final HexagonBorder? border;

  final Paint _paint = Paint();
  Path? _path;

  @override
  void paint(Canvas canvas, Size size) {
    _paint.color = color ?? Colors.transparent;
    _paint.isAntiAlias = true;
    _paint.style = PaintingStyle.fill;

    _path = hexagonPath(size);
    if (elevation > 0) {
      canvas.drawShadow(_path!, Colors.black, elevation, false);
    }
    canvas.drawPath(_path!, _paint);

    if (border != null) {
      _paint.color = border!.color;
      _paint.strokeWidth = border!.thickness;
      _paint.style = PaintingStyle.stroke;
      canvas.drawPath(_path!, _paint);
    }
  }

  @override
  bool hitTest(Offset position) {
    return _path?.contains(position) ?? false;
  }

  @override
  bool shouldRepaint(HexagonPainter oldDelegate) {
    return oldDelegate.color != color || border != oldDelegate.border;
  }
}
