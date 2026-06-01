import 'package:flutter/material.dart';
import 'dart:math' as math;

enum YogMood { happy, sad, thinking, excited, angry, anxious, calm, tired, motivated, confused, neutral }

class YogAvatar extends StatefulWidget {
  final double size;
  final bool showGlow;
  final bool isPulsing;
  final String mood;

  const YogAvatar({
    Key? key,
    this.size = 80,
    this.showGlow = true,
    this.isPulsing = false,
    this.mood = 'neutral',
  }) : super(key: key);

  factory YogAvatar.normal({double size = 80, bool isPulsing = false, String mood = 'neutral'}) {
    return YogAvatar(size: size, showGlow: true, isPulsing: isPulsing, mood: mood);
  }

  factory YogAvatar.alarm({double size = 130}) {
    return YogAvatar(size: size, showGlow: true, mood: 'excited');
  }

  factory YogAvatar.night({double size = 80}) {
    return YogAvatar(size: size, showGlow: true, mood: 'sad');
  }

  factory YogAvatar.small({double size = 40, String mood = 'neutral'}) {
    return YogAvatar(size: size, showGlow: false, mood: mood);
  }

  @override
  State<YogAvatar> createState() => _YogAvatarState();
}

class _YogAvatarState extends State<YogAvatar> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _moodTransitionController;
  late AnimationController _bobController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bobAnimation;

  YogMood _currentMood = YogMood.thinking;
  YogMood _previousMood = YogMood.thinking;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _bobAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );

    _moodTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _currentMood = _mapMood(widget.mood);
    _previousMood = _currentMood;
    _moodTransitionController.value = 1.0;

    if (widget.isPulsing) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(YogAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !oldWidget.isPulsing) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isPulsing && oldWidget.isPulsing) {
      _pulseController.stop();
      _pulseController.animateTo(1.0);
    }

    final newMood = _mapMood(widget.mood);
    if (newMood != _currentMood) {
      _previousMood = _currentMood;
      _currentMood = newMood;
      _moodTransitionController.forward(from: 0.0);
    }
  }

  YogMood _mapMood(String mood) {
    switch (mood) {
      case 'happy': return YogMood.happy;
      case 'sad': return YogMood.sad;
      case 'excited': return YogMood.excited;
      case 'angry': return YogMood.angry;
      case 'anxious': return YogMood.anxious;
      case 'calm': return YogMood.calm;
      case 'tired': return YogMood.tired;
      case 'motivated': return YogMood.motivated;
      case 'confused': return YogMood.confused;
      case 'neutral': return YogMood.neutral;
      default: return YogMood.thinking;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _moodTransitionController.dispose();
    _bobController.dispose();
    super.dispose();
  }

  Color _glowColor(YogMood mood) {
    switch (mood) {
      case YogMood.happy:
        return const Color(0xFF00BFFF);
      case YogMood.sad:
        return const Color(0xFF1A3A6B);
      case YogMood.thinking:
        return const Color(0xFF7B2FBE);
      case YogMood.excited:
        return const Color(0xFFFF4500);
      case YogMood.angry:
        return const Color(0xFFFF0000);
      case YogMood.anxious:
        return const Color(0xFFFFAA00);
      case YogMood.calm:
        return const Color(0xFF00CC88);
      case YogMood.tired:
        return const Color(0xFF4A5568);
      case YogMood.motivated:
        return const Color(0xFFFFD700);
      case YogMood.confused:
        return const Color(0xFFFF69B4);
      case YogMood.neutral:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _moodTransitionController, _bobAnimation]),
      builder: (context, child) {
        final t = _moodTransitionController.value;
        final glowFrom = _glowColor(_previousMood);
        final glowTo = _glowColor(_currentMood);
        final currentGlow = Color.lerp(glowFrom, glowTo, t)!;

        return Transform.translate(
          offset: Offset(0, _bobAnimation.value),
          child: Transform.scale(
            scale: widget.isPulsing ? _scaleAnimation.value : 1.0,
            child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: widget.showGlow
                  ? [
                      BoxShadow(
                        color: currentGlow.withOpacity(0.6),
                        blurRadius: widget.size * 0.3,
                        spreadRadius: widget.size * 0.05,
                      ),
                    ]
                  : null,
            ),
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _RobotPainter(
                mood: _currentMood,
                previousMood: _previousMood,
                transition: t,
                glowColor: currentGlow,
              ),
            ),
          ),
        ),
        );
      },
    );
  }
}

class _RobotPainter extends CustomPainter {
  final YogMood mood;
  final YogMood previousMood;
  final double transition;
  final Color glowColor;

  _RobotPainter({
    required this.mood,
    required this.previousMood,
    required this.transition,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle with gradient
    final bgGradient = RadialGradient(
      colors: [
        glowColor.withOpacity(0.3),
        const Color(0xFF0D1B2A),
        const Color(0xFF0A0A1A),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    final bgPaint = Paint()
      ..shader = bgGradient.createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);

    // Robot head (main body)
    final headCenter = Offset(center.dx, center.dy - radius * 0.05);
    final headRadius = radius * 0.52;

    // Head gradient
    final headGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFE8EDF2),
        const Color(0xFFB8C4D0),
        const Color(0xFF8A9AAA),
      ],
    );
    final headPaint = Paint()
      ..shader = headGradient.createShader(
        Rect.fromCircle(center: headCenter, radius: headRadius),
      );

    // Draw head shape (rounded rectangle-ish)
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: headCenter, width: headRadius * 2, height: headRadius * 1.7),
      Radius.circular(headRadius * 0.6),
    );
    canvas.drawRRect(headRect, headPaint);

    // Visor/face plate (dark area for eyes)
    final visorCenter = Offset(headCenter.dx, headCenter.dy + headRadius * 0.05);
    final visorPaint = Paint()..color = const Color(0xFF1A2030);
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: visorCenter, width: headRadius * 1.6, height: headRadius * 0.9),
      Radius.circular(headRadius * 0.4),
    );
    canvas.drawRRect(visorRect, visorPaint);

    // Draw eyes based on mood
    _drawEyes(canvas, visorCenter, headRadius);

    // Antenna
    final antennaBase = Offset(headCenter.dx, headCenter.dy - headRadius * 0.85);
    final antennaPaint = Paint()
      ..color = const Color(0xFF8A9AAA)
      ..strokeWidth = headRadius * 0.08
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      antennaBase,
      Offset(antennaBase.dx, antennaBase.dy - headRadius * 0.35),
      antennaPaint,
    );
    // Antenna tip glow
    final tipPaint = Paint()..color = glowColor;
    canvas.drawCircle(
      Offset(antennaBase.dx, antennaBase.dy - headRadius * 0.4),
      headRadius * 0.1,
      tipPaint,
    );

    // Ears
    final earPaint = Paint()..color = const Color(0xFF6A7A8A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(headCenter.dx - headRadius * 1.05, headCenter.dy),
          width: headRadius * 0.2,
          height: headRadius * 0.5,
        ),
        Radius.circular(headRadius * 0.1),
      ),
      earPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(headCenter.dx + headRadius * 1.05, headCenter.dy),
          width: headRadius * 0.2,
          height: headRadius * 0.5,
        ),
        Radius.circular(headRadius * 0.1),
      ),
      earPaint,
    );

    // Body (small, below head)
    final bodyCenter = Offset(center.dx, headCenter.dy + headRadius * 1.1);
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFD0D8E0), const Color(0xFF8A9AAA)],
      ).createShader(Rect.fromCenter(center: bodyCenter, width: headRadius * 1.2, height: headRadius * 0.7));
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: bodyCenter, width: headRadius * 1.2, height: headRadius * 0.7),
      Radius.circular(headRadius * 0.3),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Arms
    final armPaint = Paint()
      ..color = const Color(0xFF8A9AAA)
      ..strokeWidth = headRadius * 0.12
      ..strokeCap = StrokeCap.round;

    if (mood == YogMood.thinking || mood == YogMood.confused) {
      canvas.drawLine(
        Offset(bodyCenter.dx + headRadius * 0.6, bodyCenter.dy - headRadius * 0.1),
        Offset(headCenter.dx + headRadius * 0.5, headCenter.dy + headRadius * 0.3),
        armPaint,
      );
      canvas.drawLine(
        Offset(bodyCenter.dx - headRadius * 0.6, bodyCenter.dy - headRadius * 0.1),
        Offset(bodyCenter.dx - headRadius * 0.8, bodyCenter.dy + headRadius * 0.2),
        armPaint,
      );
    } else if (mood == YogMood.excited || mood == YogMood.motivated || mood == YogMood.happy) {
      canvas.drawLine(
        Offset(bodyCenter.dx - headRadius * 0.6, bodyCenter.dy - headRadius * 0.1),
        Offset(bodyCenter.dx - headRadius * 0.9, bodyCenter.dy - headRadius * 0.5),
        armPaint,
      );
      canvas.drawLine(
        Offset(bodyCenter.dx + headRadius * 0.6, bodyCenter.dy - headRadius * 0.1),
        Offset(bodyCenter.dx + headRadius * 0.9, bodyCenter.dy - headRadius * 0.5),
        armPaint,
      );
    } else if (mood == YogMood.angry) {
      canvas.drawLine(
        Offset(bodyCenter.dx - headRadius * 0.6, bodyCenter.dy - headRadius * 0.1),
        Offset(bodyCenter.dx - headRadius * 0.95, bodyCenter.dy + headRadius * 0.0),
        armPaint,
      );
      canvas.drawLine(
        Offset(bodyCenter.dx + headRadius * 0.6, bodyCenter.dy - headRadius * 0.1),
        Offset(bodyCenter.dx + headRadius * 0.95, bodyCenter.dy + headRadius * 0.0),
        armPaint,
      );
    } else if (mood == YogMood.tired || mood == YogMood.sad) {
      canvas.drawLine(
        Offset(bodyCenter.dx - headRadius * 0.6, bodyCenter.dy - headRadius * 0.1),
        Offset(bodyCenter.dx - headRadius * 0.7, bodyCenter.dy + headRadius * 0.45),
        armPaint,
      );
      canvas.drawLine(
        Offset(bodyCenter.dx + headRadius * 0.6, bodyCenter.dy - headRadius * 0.1),
        Offset(bodyCenter.dx + headRadius * 0.7, bodyCenter.dy + headRadius * 0.45),
        armPaint,
      );
    } else {
      canvas.drawLine(
        Offset(bodyCenter.dx - headRadius * 0.6, bodyCenter.dy - headRadius * 0.1),
        Offset(bodyCenter.dx - headRadius * 0.8, bodyCenter.dy + headRadius * 0.3),
        armPaint,
      );
      canvas.drawLine(
        Offset(bodyCenter.dx + headRadius * 0.6, bodyCenter.dy - headRadius * 0.1),
        Offset(bodyCenter.dx + headRadius * 0.8, bodyCenter.dy + headRadius * 0.3),
        armPaint,
      );
    }
  }

  void _drawEyes(Canvas canvas, Offset visorCenter, double headRadius) {
    final eyeSpacing = headRadius * 0.4;
    final leftEye = Offset(visorCenter.dx - eyeSpacing, visorCenter.dy - headRadius * 0.05);
    final rightEye = Offset(visorCenter.dx + eyeSpacing, visorCenter.dy - headRadius * 0.05);
    final eyeRadius = headRadius * 0.2;

    switch (mood) {
      case YogMood.happy:
        final eyePaint = Paint()
          ..color = const Color(0xFF00E5FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = headRadius * 0.08
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromCircle(center: leftEye, radius: eyeRadius), math.pi * 1.1, math.pi * 0.8, false, eyePaint);
        canvas.drawArc(Rect.fromCircle(center: rightEye, radius: eyeRadius), math.pi * 1.1, math.pi * 0.8, false, eyePaint);
        final smilePaint = Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.stroke..strokeWidth = headRadius * 0.06..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromCenter(center: Offset(visorCenter.dx, visorCenter.dy + headRadius * 0.2), width: headRadius * 0.6, height: headRadius * 0.3), 0.1, math.pi * 0.8, false, smilePaint);
        break;

      case YogMood.sad:
        final eyePaint = Paint()..color = const Color(0xFF4A7AB5)..style = PaintingStyle.fill;
        canvas.drawPath(Path()..addArc(Rect.fromCircle(center: leftEye, radius: eyeRadius), 0, math.pi), eyePaint);
        canvas.drawPath(Path()..addArc(Rect.fromCircle(center: rightEye, radius: eyeRadius), 0, math.pi), eyePaint);
        final mouthPaint = Paint()..color = const Color(0xFF4A7AB5)..style = PaintingStyle.stroke..strokeWidth = headRadius * 0.06..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromCenter(center: Offset(visorCenter.dx, visorCenter.dy + headRadius * 0.3), width: headRadius * 0.4, height: headRadius * 0.2), math.pi * 1.1, math.pi * 0.8, false, mouthPaint);
        // Tear drop
        final tearPaint = Paint()..color = const Color(0xFF4A7AB5);
        canvas.drawCircle(Offset(leftEye.dx + eyeRadius * 0.3, leftEye.dy + eyeRadius * 1.2), headRadius * 0.06, tearPaint);
        break;

      case YogMood.thinking:
        final eyePaint = Paint()..color = const Color(0xFFAA77FF);
        canvas.drawCircle(leftEye, eyeRadius * 0.7, eyePaint);
        final squintPaint = Paint()..color = const Color(0xFFAA77FF)..strokeWidth = headRadius * 0.08..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(rightEye.dx - eyeRadius * 0.6, rightEye.dy), Offset(rightEye.dx + eyeRadius * 0.6, rightEye.dy), squintPaint);
        final dotPaint = Paint()..color = const Color(0xFFAA77FF);
        for (int i = 0; i < 3; i++) {
          canvas.drawCircle(Offset(visorCenter.dx - headRadius * 0.2 + i * headRadius * 0.2, visorCenter.dy + headRadius * 0.25), headRadius * 0.05, dotPaint);
        }
        break;

      case YogMood.excited:
        final eyeOuterPaint = Paint()..color = const Color(0xFFFF6B00);
        canvas.drawCircle(leftEye, eyeRadius, eyeOuterPaint);
        canvas.drawCircle(rightEye, eyeRadius, eyeOuterPaint);
        final pupilPaint = Paint()..color = const Color(0xFF1A0000);
        canvas.drawCircle(leftEye, eyeRadius * 0.45, pupilPaint);
        canvas.drawCircle(rightEye, eyeRadius * 0.45, pupilPaint);
        final highlightPaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(leftEye.dx - eyeRadius * 0.2, leftEye.dy - eyeRadius * 0.2), eyeRadius * 0.2, highlightPaint);
        canvas.drawCircle(Offset(rightEye.dx - eyeRadius * 0.2, rightEye.dy - eyeRadius * 0.2), eyeRadius * 0.2, highlightPaint);
        final mouthPaint = Paint()..color = const Color(0xFFFF4500);
        canvas.drawOval(Rect.fromCenter(center: Offset(visorCenter.dx, visorCenter.dy + headRadius * 0.25), width: headRadius * 0.3, height: headRadius * 0.2), mouthPaint);
        break;

      case YogMood.angry:
        // Angry: V-shaped eyebrows, red eyes, gritting teeth
        final browPaint = Paint()..color = const Color(0xFFFF0000)..strokeWidth = headRadius * 0.09..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(leftEye.dx - eyeRadius, leftEye.dy - eyeRadius * 0.8), Offset(leftEye.dx + eyeRadius * 0.5, leftEye.dy - eyeRadius * 1.2), browPaint);
        canvas.drawLine(Offset(rightEye.dx + eyeRadius, rightEye.dy - eyeRadius * 0.8), Offset(rightEye.dx - eyeRadius * 0.5, rightEye.dy - eyeRadius * 1.2), browPaint);
        final eyePaint = Paint()..color = const Color(0xFFFF2200);
        canvas.drawCircle(leftEye, eyeRadius * 0.8, eyePaint);
        canvas.drawCircle(rightEye, eyeRadius * 0.8, eyePaint);
        final pupilPaint = Paint()..color = Colors.black;
        canvas.drawCircle(leftEye, eyeRadius * 0.35, pupilPaint);
        canvas.drawCircle(rightEye, eyeRadius * 0.35, pupilPaint);
        // Gritting mouth
        final mouthPaint = Paint()..color = const Color(0xFFFF0000)..strokeWidth = headRadius * 0.06..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(visorCenter.dx - headRadius * 0.25, visorCenter.dy + headRadius * 0.25), Offset(visorCenter.dx + headRadius * 0.25, visorCenter.dy + headRadius * 0.25), mouthPaint);
        // Teeth lines
        for (int i = 0; i < 3; i++) {
          final x = visorCenter.dx - headRadius * 0.15 + i * headRadius * 0.15;
          canvas.drawLine(Offset(x, visorCenter.dy + headRadius * 0.22), Offset(x, visorCenter.dy + headRadius * 0.28), mouthPaint);
        }
        break;

      case YogMood.anxious:
        // Anxious: wide uneven eyes, wavy mouth, sweat drop
        final eyePaint = Paint()..color = const Color(0xFFFFAA00);
        canvas.drawCircle(leftEye, eyeRadius * 0.9, eyePaint);
        canvas.drawCircle(rightEye, eyeRadius * 0.7, eyePaint);
        final pupilPaint = Paint()..color = Colors.black;
        canvas.drawCircle(Offset(leftEye.dx + eyeRadius * 0.1, leftEye.dy), eyeRadius * 0.4, pupilPaint);
        canvas.drawCircle(Offset(rightEye.dx - eyeRadius * 0.1, rightEye.dy), eyeRadius * 0.3, pupilPaint);
        // Wavy mouth
        final mouthPaint = Paint()..color = const Color(0xFFFFAA00)..style = PaintingStyle.stroke..strokeWidth = headRadius * 0.05..strokeCap = StrokeCap.round;
        final path = Path();
        path.moveTo(visorCenter.dx - headRadius * 0.25, visorCenter.dy + headRadius * 0.25);
        path.quadraticBezierTo(visorCenter.dx - headRadius * 0.1, visorCenter.dy + headRadius * 0.2, visorCenter.dx, visorCenter.dy + headRadius * 0.28);
        path.quadraticBezierTo(visorCenter.dx + headRadius * 0.1, visorCenter.dy + headRadius * 0.35, visorCenter.dx + headRadius * 0.25, visorCenter.dy + headRadius * 0.25);
        canvas.drawPath(path, mouthPaint);
        // Sweat drop
        final sweatPaint = Paint()..color = const Color(0xFF87CEEB);
        canvas.drawCircle(Offset(rightEye.dx + eyeRadius * 1.3, rightEye.dy + eyeRadius * 0.5), headRadius * 0.07, sweatPaint);
        break;

      case YogMood.calm:
        // Calm: gentle closed eyes (meditation), serene smile
        final eyePaint = Paint()..color = const Color(0xFF00CC88)..style = PaintingStyle.stroke..strokeWidth = headRadius * 0.07..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromCircle(center: leftEye, radius: eyeRadius * 0.7), math.pi * 0.1, math.pi * 0.8, false, eyePaint);
        canvas.drawArc(Rect.fromCircle(center: rightEye, radius: eyeRadius * 0.7), math.pi * 0.1, math.pi * 0.8, false, eyePaint);
        // Serene smile
        final smilePaint = Paint()..color = const Color(0xFF00CC88)..style = PaintingStyle.stroke..strokeWidth = headRadius * 0.05..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromCenter(center: Offset(visorCenter.dx, visorCenter.dy + headRadius * 0.2), width: headRadius * 0.4, height: headRadius * 0.15), 0.2, math.pi * 0.6, false, smilePaint);
        break;

      case YogMood.tired:
        // Tired: droopy half-closed eyes, open yawn mouth, Zzz
        final eyePaint = Paint()..color = const Color(0xFF4A5568)..style = PaintingStyle.stroke..strokeWidth = headRadius * 0.07..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(leftEye.dx - eyeRadius * 0.7, leftEye.dy + eyeRadius * 0.2), Offset(leftEye.dx + eyeRadius * 0.7, leftEye.dy), eyePaint);
        canvas.drawLine(Offset(rightEye.dx - eyeRadius * 0.7, rightEye.dy), Offset(rightEye.dx + eyeRadius * 0.7, rightEye.dy + eyeRadius * 0.2), eyePaint);
        // Yawn mouth (oval)
        final mouthPaint = Paint()..color = const Color(0xFF4A5568)..style = PaintingStyle.stroke..strokeWidth = headRadius * 0.05;
        canvas.drawOval(Rect.fromCenter(center: Offset(visorCenter.dx, visorCenter.dy + headRadius * 0.25), width: headRadius * 0.25, height: headRadius * 0.2), mouthPaint);
        // Zzz
        final zPaint = Paint()..color = const Color(0xFF4A5568)..style = PaintingStyle.stroke..strokeWidth = headRadius * 0.04..strokeCap = StrokeCap.round;
        final zStart = Offset(visorCenter.dx + headRadius * 0.6, visorCenter.dy - headRadius * 0.3);
        canvas.drawLine(zStart, Offset(zStart.dx + headRadius * 0.15, zStart.dy), zPaint);
        canvas.drawLine(Offset(zStart.dx + headRadius * 0.15, zStart.dy), Offset(zStart.dx, zStart.dy + headRadius * 0.12), zPaint);
        canvas.drawLine(Offset(zStart.dx, zStart.dy + headRadius * 0.12), Offset(zStart.dx + headRadius * 0.15, zStart.dy + headRadius * 0.12), zPaint);
        break;

      case YogMood.motivated:
        // Motivated: star eyes, big grin, sparkles
        final starPaint = Paint()..color = const Color(0xFFFFD700);
        _drawStar(canvas, leftEye, eyeRadius * 1.0, starPaint);
        _drawStar(canvas, rightEye, eyeRadius * 1.0, starPaint);
        // Big grin
        final grinPaint = Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = headRadius * 0.07..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromCenter(center: Offset(visorCenter.dx, visorCenter.dy + headRadius * 0.15), width: headRadius * 0.7, height: headRadius * 0.4), 0.1, math.pi * 0.8, false, grinPaint);
        break;

      case YogMood.confused:
        // Confused: one eye big, one small, spiral, question mark
        final eyePaint = Paint()..color = const Color(0xFFFF69B4);
        canvas.drawCircle(leftEye, eyeRadius * 1.0, eyePaint);
        canvas.drawCircle(rightEye, eyeRadius * 0.5, eyePaint);
        final pupilPaint = Paint()..color = Colors.black;
        canvas.drawCircle(leftEye, eyeRadius * 0.4, pupilPaint);
        canvas.drawCircle(rightEye, eyeRadius * 0.2, pupilPaint);
        // Squiggly mouth
        final mouthPaint = Paint()..color = const Color(0xFFFF69B4)..style = PaintingStyle.stroke..strokeWidth = headRadius * 0.05..strokeCap = StrokeCap.round;
        final mPath = Path();
        mPath.moveTo(visorCenter.dx - headRadius * 0.2, visorCenter.dy + headRadius * 0.25);
        mPath.quadraticBezierTo(visorCenter.dx - headRadius * 0.05, visorCenter.dy + headRadius * 0.18, visorCenter.dx + headRadius * 0.05, visorCenter.dy + headRadius * 0.28);
        mPath.quadraticBezierTo(visorCenter.dx + headRadius * 0.15, visorCenter.dy + headRadius * 0.35, visorCenter.dx + headRadius * 0.2, visorCenter.dy + headRadius * 0.22);
        canvas.drawPath(mPath, mouthPaint);
        // Question mark
        final qPaint = Paint()..color = const Color(0xFFFF69B4)..style = PaintingStyle.stroke..strokeWidth = headRadius * 0.05..strokeCap = StrokeCap.round;
        canvas.drawArc(Rect.fromCenter(center: Offset(visorCenter.dx + headRadius * 0.65, visorCenter.dy - headRadius * 0.2), width: headRadius * 0.2, height: headRadius * 0.2), math.pi * 1.2, math.pi * 1.2, false, qPaint);
        canvas.drawCircle(Offset(visorCenter.dx + headRadius * 0.65, visorCenter.dy + headRadius * 0.05), headRadius * 0.04, Paint()..color = const Color(0xFFFF69B4));
        break;

      case YogMood.neutral:
        // Neutral: simple dot eyes, flat line mouth
        final eyePaint = Paint()..color = const Color(0xFF6B7280);
        canvas.drawCircle(leftEye, eyeRadius * 0.6, eyePaint);
        canvas.drawCircle(rightEye, eyeRadius * 0.6, eyePaint);
        final mouthPaint = Paint()..color = const Color(0xFF6B7280)..strokeWidth = headRadius * 0.06..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(visorCenter.dx - headRadius * 0.2, visorCenter.dy + headRadius * 0.25), Offset(visorCenter.dx + headRadius * 0.2, visorCenter.dy + headRadius * 0.25), mouthPaint);
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * math.pi / 5) - math.pi / 2;
      final point = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RobotPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.transition != transition ||
        oldDelegate.glowColor != glowColor;
  }
}
