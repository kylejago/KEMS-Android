import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/kems_theme.dart';

class KemsSplashScreen extends StatefulWidget {
  const KemsSplashScreen({super.key});

  @override
  State<KemsSplashScreen> createState() => _KemsSplashScreenState();
}

class _KemsSplashScreenState extends State<KemsSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF031116), Color(0xFF06252B), Color(0xFF050C10)],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _SplashEnergyPainter(progress: _controller.value),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 34),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withValues(alpha: .08)),
                      boxShadow: [
                        BoxShadow(
                          color: KemsTheme.green.withValues(alpha: .12),
                          blurRadius: 50,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/branding/kems_mark.png',
                          width: 210,
                          height: 210,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'KEMS',
                          style: TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        const Text(
                          'KYLE ENERGY MANAGEMENT SYSTEM',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: KemsTheme.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  const Text(
                    'Connecting your live energy world',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: const LinearProgressIndicator(
                      minHeight: 5,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashEnergyPainter extends CustomPainter {
  const _SplashEnergyPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = KemsTheme.cyan.withValues(alpha: .12);
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = KemsTheme.green.withValues(alpha: .75);

    for (var i = 0; i < 6; i++) {
      final y = size.height * (.14 + i * .145);
      final path = Path()
        ..moveTo(-30, y)
        ..cubicTo(
          size.width * .25,
          y + math.sin(i.toDouble()) * 80,
          size.width * .7,
          y - 80,
          size.width + 30,
          y + 20,
        );
      canvas.drawPath(path, linePaint);

      final metric = path.computeMetrics().first;
      final offset = metric.getTangentForOffset(
        metric.length * ((progress + i * .17) % 1),
      )?.position;
      if (offset != null) {
        canvas.drawCircle(offset, 4, glowPaint);
        canvas.drawCircle(
          offset,
          12,
          glowPaint..color = KemsTheme.green.withValues(alpha: .08),
        );
        glowPaint.color = KemsTheme.green.withValues(alpha: .75);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SplashEnergyPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
