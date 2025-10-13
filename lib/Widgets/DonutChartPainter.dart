import 'package:flutter/cupertino.dart';
import '../core/const/app_color.dart';
import 'package:flutter/material.dart';


class DonutChartPainter extends CustomPainter {
  final double percentage;
  DonutChartPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0;

    final backgroundPaint = Paint()
      ..color = const Color(0xFFD9D9D9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final foregroundPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    canvas.drawCircle(center, radius, backgroundPaint);
    final normalizedPercentage = percentage.clamp(0.0, 100.0) / 100.0;
    final sweepAngle = 2 * 3.141592653589793 * normalizedPercentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is DonutChartPainter && oldDelegate.percentage != percentage;
  }
}