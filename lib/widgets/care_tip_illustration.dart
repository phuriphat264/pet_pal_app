// Hand-drawn (CustomPainter) illustrations for the care tips section.
// Vector shapes only -- no photos/third-party assets -- so there's no
// licensing concern, unlike a downloaded stock image would carry.
import 'package:flutter/material.dart';

enum CareTipIllustrationType { food, water, exercise }

class CareTipIllustration extends StatelessWidget {
  final CareTipIllustrationType type;
  final double size;

  const CareTipIllustration({super.key, required this.type, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _painterFor(type)),
    );
  }

  CustomPainter _painterFor(CareTipIllustrationType type) {
    switch (type) {
      case CareTipIllustrationType.food:
        return _FoodBowlPainter();
      case CareTipIllustrationType.water:
        return _WaterBowlPainter();
      case CareTipIllustrationType.exercise:
        return _WalkingDogPainter();
    }
  }
}

Path _bowlPath(double w, double h) => Path()
  ..moveTo(w * 0.14, h * 0.42)
  ..quadraticBezierTo(w * 0.10, h * 0.80, w * 0.30, h * 0.90)
  ..quadraticBezierTo(w * 0.50, h * 0.98, w * 0.70, h * 0.90)
  ..quadraticBezierTo(w * 0.90, h * 0.80, w * 0.86, h * 0.42)
  ..close();

class _FoodBowlPainter extends CustomPainter {
  static const _brown = Color(0xFF5C3D2E);
  static const _darkBrown = Color(0xFF3D2316);
  static const _cream = Color(0xFFF5EFE8);
  static const _amber = Color(0xFFE8A33D);
  static const _amberLight = Color(0xFFF3C97A);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawPath(_bowlPath(w, h), Paint()..color = _brown);

    final rimRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.40), width: w * 0.76, height: h * 0.24);
    canvas.drawOval(rimRect, Paint()..color = _darkBrown);
    final rimInnerRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.385), width: w * 0.64, height: h * 0.18);
    canvas.drawOval(rimInnerRect, Paint()..color = _cream);

    final kibblePositions = [
      Offset(w * 0.40, h * 0.36),
      Offset(w * 0.52, h * 0.32),
      Offset(w * 0.62, h * 0.38),
      Offset(w * 0.46, h * 0.42),
      Offset(w * 0.58, h * 0.44),
    ];
    for (var i = 0; i < kibblePositions.length; i++) {
      canvas.drawCircle(kibblePositions[i], w * 0.045, Paint()..color = i.isEven ? _amber : _amberLight);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WaterBowlPainter extends CustomPainter {
  static const _brown = Color(0xFF5C3D2E);
  static const _darkBrown = Color(0xFF3D2316);
  static const _blue = Color(0xFF5B9BD5);
  static const _blueLight = Color(0xFFAFD4EE);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawPath(_bowlPath(w, h), Paint()..color = _brown);

    final rimRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.40), width: w * 0.76, height: h * 0.24);
    canvas.drawOval(rimRect, Paint()..color = _darkBrown);
    final waterRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.385), width: w * 0.64, height: h * 0.18);
    canvas.drawOval(waterRect, Paint()..color = _blueLight);

    final wavePaint = Paint()
      ..color = _blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    final wavePath = Path()
      ..moveTo(w * 0.30, h * 0.385)
      ..quadraticBezierTo(w * 0.40, h * 0.34, w * 0.50, h * 0.385)
      ..quadraticBezierTo(w * 0.60, h * 0.43, w * 0.70, h * 0.385);
    canvas.drawPath(wavePath, wavePaint);

    final dropPath = Path()
      ..moveTo(w * 0.74, h * 0.06)
      ..quadraticBezierTo(w * 0.62, h * 0.22, w * 0.74, h * 0.28)
      ..quadraticBezierTo(w * 0.86, h * 0.22, w * 0.74, h * 0.06)
      ..close();
    canvas.drawPath(dropPath, Paint()..color = _blue);
    canvas.drawCircle(Offset(w * 0.705, h * 0.16), w * 0.02, Paint()..color = Colors.white.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WalkingDogPainter extends CustomPainter {
  static const _brown = Color(0xFF5C3D2E);
  static const _darkBrown = Color(0xFF3D2316);
  static const _green = Color(0xFF8FBF7F);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final groundPaint = Paint()
      ..color = _green
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.06, h * 0.86), Offset(w * 0.94, h * 0.86), groundPaint);

    final legPaint = Paint()
      ..color = _darkBrown
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.34, h * 0.68), Offset(w * 0.28, h * 0.86), legPaint);
    canvas.drawLine(Offset(w * 0.46, h * 0.70), Offset(w * 0.52, h * 0.86), legPaint);
    canvas.drawLine(Offset(w * 0.62, h * 0.68), Offset(w * 0.56, h * 0.86), legPaint);
    canvas.drawLine(Offset(w * 0.70, h * 0.70), Offset(w * 0.76, h * 0.86), legPaint);

    final dogPaint = Paint()..color = _brown;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.30, h * 0.42, w * 0.44, h * 0.30),
      Radius.circular(w * 0.16),
    );
    canvas.drawRRect(bodyRect, dogPaint);

    final tailPath = Path()
      ..moveTo(w * 0.72, h * 0.48)
      ..quadraticBezierTo(w * 0.86, h * 0.38, w * 0.84, h * 0.22);
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = _brown
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(Offset(w * 0.28, h * 0.40), w * 0.14, dogPaint);

    final earPath = Path()
      ..moveTo(w * 0.22, h * 0.30)
      ..lineTo(w * 0.16, h * 0.16)
      ..lineTo(w * 0.28, h * 0.26)
      ..close();
    canvas.drawPath(earPath, Paint()..color = _darkBrown);

    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.16, h * 0.42), width: w * 0.14, height: h * 0.10), dogPaint);
    canvas.drawCircle(Offset(w * 0.26, h * 0.37), w * 0.014, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.11, h * 0.42), w * 0.018, Paint()..color = _darkBrown);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
