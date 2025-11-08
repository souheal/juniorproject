import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Widget that renders a vibrant party scene with disco ball and group of people.
class PartyIllustration extends StatelessWidget {
  const PartyIllustration({super.key, this.size = const Size(320, 320)});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _PartyIllustrationPainter(),
      isComplex: true,
    );
  }
}

/// Widget that renders neon beams with dancing silhouettes.
class NeonDanceIllustration extends StatelessWidget {
  const NeonDanceIllustration({super.key, this.size = const Size(320, 320)});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _NeonDanceIllustrationPainter(),
      isComplex: true,
    );
  }
}

/// Widget that renders a connected mobile experience illustration.
class StayConnectedIllustration extends StatelessWidget {
  const StayConnectedIllustration({
    super.key,
    this.size = const Size(320, 320),
  });

  final Size size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _StayConnectedIllustrationPainter(),
      isComplex: true,
    );
  }
}

/// Widget that shows a large circular photo framed inside a rounded border.
class CirclePlaceholderIllustration extends StatelessWidget {
  const CirclePlaceholderIllustration({
    super.key,
    this.diameterFactor = 0.82,
  });

  final double diameterFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final availableWidth = constraints.maxWidth.isFinite &&
                constraints.maxWidth > 0
            ? constraints.maxWidth
            : screenWidth;
        final baseDiameter = availableWidth * diameterFactor;
        final circleDiameter = baseDiameter > 0 ? baseDiameter : availableWidth;
        final shadowHeight = circleDiameter * 0.14;

        return SizedBox(
          height: circleDiameter + shadowHeight * 0.6,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: circleDiameter,
                height: circleDiameter,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
              ),
              ClipOval(
                child: Image.asset(
                  'assets/images/ee.png',
                  width: circleDiameter,
                  height: circleDiameter,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget that renders overlapping arch and rounded shapes with accent dots.
class OverlappingShapesIllustration extends StatefulWidget {
  const OverlappingShapesIllustration({
    super.key,
    this.size = const Size(320, 320),
  });

  final Size size;

  @override
  State<OverlappingShapesIllustration> createState() =>
      _OverlappingShapesIllustrationState();
}

class _OverlappingShapesIllustrationState
    extends State<OverlappingShapesIllustration> {
  ui.Image? _primaryImage;
  ui.Image? _secondaryImage;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final primary =
          await _loadImage('assets/images/pexels-arts-1164985.jpg');
      final secondary =
          await _loadImage('assets/images/photo-1501281668745-f7f57925c3b4.jpeg');

      if (!mounted) {
        primary.dispose();
        secondary.dispose();
        return;
      }

      setState(() {
        _primaryImage = primary;
        _secondaryImage = secondary;
      });
    } catch (error) {
      debugPrint('Failed to load onboarding images: $error');
    }
  }

  Future<ui.Image> _loadImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void dispose() {
    _primaryImage?.dispose();
    _secondaryImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: widget.size,
      painter: _OverlappingShapesPainter(
        primaryImage: _primaryImage,
        secondaryImage: _secondaryImage,
      ),
      isComplex: true,
    );
  }
}

class _PartyIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final frameRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(24, 24, size.width - 48, size.height - 96),
      topLeft: const Radius.circular(40),
      topRight: const Radius.circular(40),
      bottomLeft: const Radius.circular(28),
      bottomRight: const Radius.circular(28),
    );

    final framePath = Path()..addRRect(frameRect);
    canvas.drawShadow(
      framePath,
      Colors.black.withValues(alpha: 0.12),
      24,
      false,
    );

    final framePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF392BFF), Color(0xFF9A4DFF), Color(0xFFFF5791)],
      ).createShader(frameRect.outerRect);
    canvas.drawRRect(frameRect, framePaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.white;
    canvas.drawRRect(frameRect.deflate(3), borderPaint);

    _paintPartyPeople(canvas, frameRect);
    _paintDiscoBall(canvas, frameRect);

    _paintFloatingDots(canvas, size);
  }

  void _paintPartyPeople(Canvas canvas, RRect frameRect) {
    final base = frameRect.outerRect;
    final crowdTop = base.top + base.height * 0.42;
    final crowdBottom = base.bottom - 24;
    final crowdRect = Rect.fromLTRB(
      base.left + 24,
      crowdTop,
      base.right - 24,
      crowdBottom,
    );

    final bodyPaints = [
      Paint()..color = const Color(0xFF66E0FF),
      Paint()..color = const Color(0xFFFFB64C),
      Paint()..color = const Color(0xFF9AFF79),
    ];

    for (var i = 0; i < 3; i++) {
      final personWidth = crowdRect.width / 3.4;
      final xOffset = crowdRect.left + i * (personWidth + 12);
      final personRect = Rect.fromLTWH(
        xOffset,
        crowdRect.top + (i == 1 ? 6 : 0),
        personWidth,
        crowdRect.height - (i == 1 ? 12 : 0),
      );

      final bodyPath = Path()
        ..moveTo(personRect.left + personRect.width * 0.2, personRect.bottom)
        ..quadraticBezierTo(
          personRect.left + personRect.width * 0.1,
          personRect.center.dy,
          personRect.center.dx,
          personRect.top + personRect.height * 0.35,
        )
        ..quadraticBezierTo(
          personRect.right - personRect.width * 0.1,
          personRect.center.dy,
          personRect.right - personRect.width * 0.2,
          personRect.bottom,
        )
        ..close();

      canvas.drawPath(bodyPath, bodyPaints[i]);

      final headCenter = Offset(
        personRect.center.dx,
        personRect.top + personRect.height * 0.2,
      );
      final headPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            bodyPaints[i].color.withValues(alpha: 0.8),
          ],
        ).createShader(Rect.fromCircle(center: headCenter, radius: 18));
      canvas.drawCircle(headCenter, 18, headPaint);

      final armPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      final armSpan = personRect.width * 0.75;
      canvas.drawLine(
        headCenter + Offset(-armSpan / 2, 16),
        headCenter + Offset(armSpan / 2, 0),
        armPaint,
      );
    }
  }

  void _paintDiscoBall(Canvas canvas, RRect frameRect) {
    final base = frameRect.outerRect;
    final center = Offset(base.center.dx, base.top + 68);

    final chainPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(center.dx, base.top),
      Offset(center.dx, center.dy - 36),
      chainPaint,
    );

    final discoBallRect = Rect.fromCircle(center: center, radius: 32);
    final discoPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFD1D1FF), Color(0xFF8C7BFF)],
      ).createShader(discoBallRect);
    canvas.drawCircle(center, 32, discoPaint);

    final gridPaint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final gridPath = Path();
    for (var i = -2; i <= 2; i++) {
      final angle = (math.pi / 6) * i;
      final dx = math.cos(angle) * 28;
      final dy = math.sin(angle) * 28;
      gridPath.moveTo(center.dx - dx, center.dy - dy);
      gridPath.lineTo(center.dx + dx, center.dy + dy);
    }
    for (var j = -1; j <= 1; j++) {
      final y = center.dy + j * 12;
      final span = math.sqrt(math.max(0, 32 * 32 - (12 * j) * (12 * j)));
      gridPath.moveTo(center.dx - span, y);
      gridPath.lineTo(center.dx + span, y);
    }
    canvas.drawPath(gridPath, gridPaint);
  }

  void _paintFloatingDots(Canvas canvas, Size size) {
    final dotPaints = [
      Paint()..color = const Color(0xFFFF8A65),
      Paint()..color = const Color(0xFF9575CD),
      Paint()..color = const Color(0xFFFF4D6D),
    ];

    final positions = [
      Offset(size.width * 0.18, size.height * 0.12),
      Offset(size.width * 0.82, size.height * 0.18),
      Offset(size.width * 0.12, size.height * 0.82),
      Offset(size.width * 0.88, size.height * 0.78),
    ];

    for (var i = 0; i < positions.length; i++) {
      final paint = dotPaints[i % dotPaints.length];
      final radius = i.isEven ? 12.0 : 18.0;
      final dotPaint = Paint()
        ..color = paint.color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(positions[i], radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NeonDanceIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final frameRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(20, 28, size.width - 40, size.height - 72),
      const Radius.circular(32),
    );

    final framePath = Path()..addRRect(frameRect);
    canvas.drawShadow(
      framePath,
      Colors.black.withValues(alpha: 0.12),
      24,
      false,
    );

    final backgroundPaintGradient = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3124FF), Color(0xFF5F2FFF), Color(0xFF8F2FFF)],
      ).createShader(frameRect.outerRect);
    canvas.drawRRect(frameRect, backgroundPaintGradient);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawRRect(frameRect.deflate(2.5), borderPaint);

    _paintNeonBeams(canvas, frameRect);
    _paintDanceSilhouettes(canvas, frameRect);
    _paintFloatingDots(canvas, size);
  }

  void _paintNeonBeams(Canvas canvas, RRect frameRect) {
    final beamPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x66D0A6FF), Color(0x00000000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(frameRect.outerRect);

    canvas.save();
    canvas.clipRRect(frameRect.deflate(12));

    final baseRect = frameRect.outerRect.deflate(16);
    for (var i = 0; i < 6; i++) {
      final x = baseRect.left + (i / 5) * baseRect.width;
      final path = Path()
        ..moveTo(x, baseRect.top)
        ..quadraticBezierTo(
          baseRect.center.dx,
          baseRect.top + baseRect.height * 0.45,
          baseRect.left + baseRect.width * (0.2 + i * 0.1),
          baseRect.bottom,
        );
      canvas.drawPath(path, beamPaint);
    }
    canvas.restore();
  }

  void _paintDanceSilhouettes(Canvas canvas, RRect frameRect) {
    final silhouettes = [
      _SilhouetteConfig(
        offset: const Offset(-50, 24),
        scale: 1.1,
        color: const Color(0xCC1C0F38),
      ),
      _SilhouetteConfig(
        offset: Offset.zero,
        scale: 1.2,
        color: const Color(0xCC250F3F),
      ),
      _SilhouetteConfig(
        offset: const Offset(46, 28),
        scale: 1.05,
        color: const Color(0xCC1C0F38),
      ),
    ];

    final baseRect = frameRect.outerRect.deflate(16);
    for (final config in silhouettes) {
      final path = _buildSilhouettePath(baseRect, config);
      final paint = Paint()
        ..color = config.color
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    }
  }

  Path _buildSilhouettePath(Rect rect, _SilhouetteConfig config) {
    final width = rect.width * 0.55;
    final height = rect.height * 0.55;
    final origin = Offset(
      rect.center.dx + config.offset.dx,
      rect.bottom - rect.height * 0.18 + config.offset.dy,
    );

    final path = Path();
    path.moveTo(origin.dx, origin.dy);
    path.relativeCubicTo(
      -width * 0.4 * config.scale,
      -height * 0.1 * config.scale,
      -width * 0.3 * config.scale,
      -height * 0.6 * config.scale,
      -width * 0.12 * config.scale,
      -height * 0.72 * config.scale,
    );
    path.relativeQuadraticBezierTo(
      width * 0.08 * config.scale,
      -height * 0.1 * config.scale,
      width * 0.25 * config.scale,
      -height * 0.1 * config.scale,
    );
    path.relativeQuadraticBezierTo(
      width * 0.25 * config.scale,
      height * 0.4 * config.scale,
      width * 0.34 * config.scale,
      height * 0.78 * config.scale,
    );
    path.relativeLineTo(
      -width * 0.08 * config.scale,
      height * 0.24 * config.scale,
    );
    path.relativeQuadraticBezierTo(
      -width * 0.2 * config.scale,
      -height * 0.14 * config.scale,
      -width * 0.39 * config.scale,
      -height * 0.1 * config.scale,
    );
    path.close();
    return path;
  }

  void _paintFloatingDots(Canvas canvas, Size size) {
    final dotPaints = [
      Paint()..color = const Color(0xFFFF8A65),
      Paint()..color = const Color(0xFF9575CD),
      Paint()..color = const Color(0xFFFF4D6D),
    ];

    final positions = [
      Offset(size.width * 0.2, size.height * 0.18),
      Offset(size.width * 0.85, size.height * 0.24),
      Offset(size.width * 0.16, size.height * 0.88),
      Offset(size.width * 0.78, size.height * 0.82),
      Offset(size.width * 0.5, size.height * 0.08),
    ];

    for (var i = 0; i < positions.length; i++) {
      final paint = dotPaints[i % dotPaints.length];
      final radius = 10.0 + (i % 3) * 6.0;
      final dotPaint = Paint()
        ..color = paint.color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(positions[i], radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SilhouetteConfig {
  const _SilhouetteConfig({
    required this.offset,
    required this.scale,
    required this.color,
  });

  final Offset offset;
  final double scale;
  final Color color;
}

class _StayConnectedIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {

    final frameRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(26, 32, size.width - 52, size.height - 80),
      topLeft: const Radius.circular(36),
      topRight: const Radius.circular(36),
      bottomLeft: const Radius.circular(28),
      bottomRight: const Radius.circular(28),
    );

    final framePath = Path()..addRRect(frameRect);
    canvas.drawShadow(
      framePath,
      Colors.black.withValues(alpha: 0.12),
      24,
      false,
    );

    final framePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1F2CFF), Color(0xFF5142FF), Color(0xFF7847FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(frameRect.outerRect);
    canvas.drawRRect(frameRect, framePaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.white.withValues(alpha: 0.95);
    canvas.drawRRect(frameRect.deflate(2.5), borderPaint);

    _paintPhone(canvas, frameRect);
    _paintSideCharacters(canvas, frameRect);
    _paintFloatingDots(canvas, size);
  }

  void _paintPhone(Canvas canvas, RRect frameRect) {
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: frameRect.outerRect.center + const Offset(0, 16),
        width: frameRect.width * 0.42,
        height: frameRect.height * 0.64,
      ),
      const Radius.circular(28),
    );

    final phoneBodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF101C3F), Color(0xFF1D2460)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(phoneRect.outerRect);
    canvas.drawRRect(phoneRect, phoneBodyPaint);

    final screenRect = phoneRect.deflate(18);
    final screenPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3C5BFF), Color(0xFF7245FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(screenRect.outerRect);
    canvas.drawRRect(screenRect, screenPaint);

    final indicatorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;
    final base = screenRect.outerRect;
    canvas.drawLine(
      Offset(base.left + 24, base.bottom - 24),
      Offset(base.right - 24, base.bottom - 24),
      indicatorPaint,
    );
  }

  void _paintSideCharacters(Canvas canvas, RRect frameRect) {
    final baseRect = frameRect.outerRect;
    final configs = [
      _CharacterConfig(
        center: baseRect.centerLeft + const Offset(36, 20),
        color: const Color(0xFFFF9E6D),
        mirror: false,
      ),
      _CharacterConfig(
        center: baseRect.centerRight + const Offset(-36, 16),
        color: const Color(0xFF8DE3FF),
        mirror: true,
      ),
    ];

    for (final config in configs) {
      final direction = config.mirror ? -1.0 : 1.0;
      final start = Offset(
        config.center.dx - 18 * direction,
        config.center.dy + 64,
      );
      final bodyPath = Path()
        ..moveTo(start.dx, start.dy)
        ..relativeCubicTo(
          12 * direction,
          -12,
          16 * direction,
          -58,
          8 * direction,
          -88,
        )
        ..relativeQuadraticBezierTo(6 * direction, -14, 18 * direction, -14)
        ..relativeQuadraticBezierTo(24 * direction, 30, 12 * direction, 70)
        ..relativeLineTo(-10 * direction, 26)
        ..close();

      final bodyPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            config.color.withValues(alpha: 0.95),
            config.color.withValues(alpha: 0.7),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bodyPath.getBounds());
      canvas.drawPath(bodyPath, bodyPaint);

      final headCenter = Offset(config.center.dx, config.center.dy - 48);
      final headPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            config.color.withValues(alpha: 0.8),
          ],
        ).createShader(Rect.fromCircle(center: headCenter, radius: 20));
      canvas.drawCircle(headCenter, 20, headPaint);

      final armPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      final armEnd = Offset(
        config.center.dx + 40 * direction,
        config.center.dy - 4,
      );
      canvas.drawLine(
        headCenter + Offset(12 * direction, 10),
        armEnd,
        armPaint,
      );

      final bubbleRect = RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(
            config.center.dx + 56 * direction,
            config.center.dy - 60,
          ),
          width: 78,
          height: 48,
        ),
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: const Radius.circular(18),
        bottomRight: const Radius.circular(18),
      );
      canvas.drawRRect(bubbleRect, Paint()..color = const Color(0xCCFFFFFF));

      final bubbleAccent = Paint()
        ..color = config.color.withValues(alpha: 0.8)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4;
      canvas.drawLine(
        bubbleRect.outerRect.centerLeft + Offset(12 * direction, 0),
        bubbleRect.outerRect.centerLeft + Offset(28 * direction, 0),
        bubbleAccent,
      );
      canvas.drawCircle(
        bubbleRect.outerRect.centerLeft + Offset(38 * direction, 0),
        3,
        bubbleAccent,
      );
    }
  }

  void _paintFloatingDots(Canvas canvas, Size size) {
    final dotPaints = [
      Paint()..color = const Color(0xFFFF8A65),
      Paint()..color = const Color(0xFF9575CD),
      Paint()..color = const Color(0xFFFF4D6D),
    ];

    final positions = [
      Offset(size.width * 0.18, size.height * 0.16),
      Offset(size.width * 0.82, size.height * 0.22),
      Offset(size.width * 0.12, size.height * 0.86),
      Offset(size.width * 0.86, size.height * 0.84),
      Offset(size.width * 0.52, size.height * 0.1),
    ];

    for (var i = 0; i < positions.length; i++) {
      final paint = dotPaints[i % dotPaints.length];
      final radius = 10.0 + (i % 3) * 5.5;
      final dotPaint = Paint()
        ..color = paint.color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(positions[i], radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CharacterConfig {
  const _CharacterConfig({
    required this.center,
    required this.color,
    required this.mirror,
  });

  final Offset center;
  final Color color;
  final bool mirror;
}

class _OverlappingShapesPainter extends CustomPainter {
  const _OverlappingShapesPainter({
    this.primaryImage,
    this.secondaryImage,
  });

  final ui.Image? primaryImage;
  final ui.Image? secondaryImage;

  @override
  void paint(Canvas canvas, Size size) {

    final frontWidth = size.width * 0.72;
    final frontHeight = size.height * 0.78;
    final frontRect = Rect.fromLTWH(
      size.width * 0.0,
      size.height * 0.28,
      frontWidth,
      frontHeight,
    );
    final frontRRect =
        RRect.fromRectAndRadius(frontRect, const Radius.circular(40));

    final backRect = Rect.fromLTWH(
      size.width * 0.45,
      size.height * 0.55,
      size.width * 0.59,
      size.height * 0.70,
    );
    final backRRect =
        RRect.fromRectAndRadius(backRect, const Radius.circular(36));

    final backPath = Path()..addRRect(backRRect);
    canvas.drawShadow(
      backPath,
      Colors.black.withValues(alpha: 0.14),
      20,
      false,
    );

    canvas.save();
    canvas.clipRRect(backRRect);

    if (secondaryImage != null) {
      paintImage(
        canvas: canvas,
        rect: backRect,
        image: secondaryImage!,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      );
    } else {
      final backPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF495BFF), Color(0xFF7A56FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(backRect);
      canvas.drawRect(backRect, backPaint);
    }

    final backOverlay = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.black.withValues(alpha: 0.45),
          Colors.black.withValues(alpha: 0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(backRect);
    canvas.drawRect(backRect, backOverlay);

    final backHighlight = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(backRect);
    canvas.drawRect(backRect, backHighlight);
    canvas.restore();

    final frontPath = Path()..addRRect(frontRRect);

    canvas.drawShadow(
      frontPath,
      Colors.black.withValues(alpha: 0.18),
      24,
      false,
    );

    canvas.save();
    canvas.clipPath(frontPath);

    if (primaryImage != null) {
      paintImage(
        canvas: canvas,
        rect: frontRect,
        image: primaryImage!,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      );
    } else {
      final frontPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF7AB3), Color(0xFFFF9867)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(frontRect);
      canvas.drawRect(frontRect, frontPaint);
    }

    final frontHighlight = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(frontRect);
    canvas.drawRect(frontRect, frontHighlight);
    canvas.restore();

    final frontBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.white;
    canvas.drawRRect(frontRRect, frontBorder);
  }

  @override
  bool shouldRepaint(covariant _OverlappingShapesPainter oldDelegate) {
    return oldDelegate.primaryImage != primaryImage ||
        oldDelegate.secondaryImage != secondaryImage;
  }
}
