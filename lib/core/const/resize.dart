import 'package:flutter/material.dart';
import 'dart:ui';

double referWidth = 375.0;
double referHeight = 840.0;
final view = PlatformDispatcher.instance.implicitView!;
final screenHeight = view.physicalSize.height / view.devicePixelRatio;
final screenWidth = view.physicalSize.width / view.devicePixelRatio;

double h(double height) {
  return screenHeight * (height / referHeight);
}

double w(double width) {
  return screenWidth * (width / referWidth);
}

double t(double size) {
  return h(size);
}

bool get isTablet => screenWidth > 600;

Size textSize(Text text) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text.data, style: text.style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout(minWidth: 0, maxWidth: double.infinity);
  return textPainter.size;
}