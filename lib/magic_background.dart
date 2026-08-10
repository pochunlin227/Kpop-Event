/// 魔幻星空背景:深夜漸層 + 閃爍星星 + 鑽石光芒
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class MagicBackground extends StatefulWidget {
  final Widget child;
  const MagicBackground({super.key, required this.child});

  @override
  State<MagicBackground> createState() => _MagicBackgroundState();
}

class _MagicBackgroundState extends State<MagicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B1026), // 深夜藍
                Color(0xFF1C1B3A), // 暗紫
                Color(0xFF35204A), // 魔幻紫
                Color(0xFF241B3A),
              ],
            ),
          ),
        ),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _StarfieldPainter(_controller.value),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Star {
  final double x, y, size, phase, speed;
  const _Star(this.x, this.y, this.size, this.phase, this.speed);
}

class _StarfieldPainter extends CustomPainter {
  final double t;
  _StarfieldPainter(this.t);

  static final List<_Star> _stars = _generate(140, seed: 17);
  static final List<_Star> _diamonds = _generate(7, seed: 95);

  static List<_Star> _generate(int count, {required int seed}) {
    final rng = math.Random(seed);
    return List.generate(count, (_) {
      return _Star(
        rng.nextDouble(),
        rng.nextDouble(),
        0.6 + rng.nextDouble() * 1.6,
        rng.nextDouble() * 2 * math.pi,
        0.5 + rng.nextDouble() * 1.5,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // 閃爍小星星
    for (final s in _stars) {
      final tw = 0.5 + 0.5 * math.sin(2 * math.pi * t * s.speed + s.phase);
      paint.color = Colors.white.withValues(alpha: 0.12 + 0.5 * tw);
      canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height), s.size * 0.9, paint);
    }
    // 大顆的鑽石四芒星光
    for (final d in _diamonds) {
      final tw = 0.5 + 0.5 * math.sin(2 * math.pi * t * d.speed + d.phase);
      final c = Offset(d.x * size.width, d.y * size.height);
      final r = (3.0 + d.size * 4.0) * (0.6 + 0.4 * tw);
      final color = Color.lerp(const Color(0xFFF7CAC9), const Color(0xFF92A8D1),
          d.phase / (2 * math.pi))!;
      paint.color = color.withValues(alpha: 0.25 + 0.45 * tw);
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(path, paint);
      // 中心亮點
      paint.color = Colors.white.withValues(alpha: 0.5 * tw);
      canvas.drawCircle(c, 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter oldDelegate) => oldDelegate.t != t;
}
