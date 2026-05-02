import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class YogAvatar extends StatefulWidget {
  final double size;
  final Color ringColor;
  final bool showGlow;
  final Color glowColor;
  final bool isPulsing;

  const YogAvatar({
    Key? key,
    this.size = 80,
    this.ringColor = AppTheme.primaryPurple,
    this.showGlow = true,
    this.glowColor = AppTheme.primaryPurple,
    this.isPulsing = false,
  }) : super(key: key);

  factory YogAvatar.normal({double size = 80, bool isPulsing = false}) {
    return YogAvatar(
      size: size,
      ringColor: AppTheme.primaryPurple,
      showGlow: true,
      glowColor: AppTheme.primaryPurple,
      isPulsing: isPulsing,
    );
  }

  factory YogAvatar.alarm({double size = 130}) {
    return YogAvatar(
      size: size,
      ringColor: AppTheme.gold,
      showGlow: true,
      glowColor: AppTheme.gold,
    );
  }

  factory YogAvatar.night({double size = 80}) {
    return YogAvatar(
      size: size,
      ringColor: const Color(0xFF4A90D9),
      showGlow: true,
      glowColor: const Color(0xFF4A90D9),
    );
  }

  factory YogAvatar.small({double size = 40}) {
    return YogAvatar(
      size: size,
      ringColor: AppTheme.primaryPurple,
      showGlow: false,
      glowColor: Colors.transparent,
    );
  }

  @override
  State<YogAvatar> createState() => _YogAvatarState();
}

class _YogAvatarState extends State<YogAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(YogAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !oldWidget.isPulsing) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && oldWidget.isPulsing) {
      _controller.stop();
      _controller.animateTo(1.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isPulsing ? _scaleAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.backgroundMain,
              border: Border.all(
                color: widget.ringColor,
                width: widget.size * 0.04,
              ),
              boxShadow: widget.showGlow
                  ? [
                      BoxShadow(
                        color: widget.glowColor.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Container(
                width: widget.size * 0.8,
                height: widget.size * 0.8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryPurple,
                ),
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: AppTheme.textWhite,
                  size: widget.size * 0.48,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
