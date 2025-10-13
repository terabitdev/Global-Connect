import 'package:flutter/material.dart';

extension MediaQueryValues on BuildContext {
  double get screenHeight => MediaQuery.of(this).size.height;
  double get screenWidth => MediaQuery.of(this).size.width;
}

class ResponsiveLayout {
  final BuildContext context;
  
  ResponsiveLayout(this.context);
  
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  
  bool get isMobile => screenWidth <= 480;
  bool get isTablet => screenWidth > 600;
  bool get isVerySmallScreen => screenWidth <= 360;
  
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isTablet) return tablet ?? desktop ?? mobile;
    if (isMobile) return mobile;
    return desktop ?? mobile;
  }
  
  double responsiveValue({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsive<double>(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
  
  EdgeInsets responsivePadding({
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    return responsive<EdgeInsets>(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
  
  TextStyle responsiveTextStyle({
    required TextStyle base,
    double? mobileFontSize,
    double? tabletFontSize,
    double? desktopFontSize,
  }) {
    final fontSize = responsiveValue(
      mobile: mobileFontSize ?? base.fontSize ?? 14,
      tablet: tabletFontSize,
      desktop: desktopFontSize,
    );
    return base.copyWith(fontSize: fontSize);
  }
}

class ResponsiveSizes {
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 600;
  
  final BuildContext context;
  
  ResponsiveSizes(this.context);
  
  ResponsiveLayout get layout => ResponsiveLayout(context);
  
  double get avatarSize => layout.responsiveValue(
    mobile: 40,
    desktop: 48,
    tablet: 56,
  );
  
  double get iconSize => layout.responsiveValue(
    mobile: 12,
    desktop: 16,
    tablet: 18,
  );
  
  double get cardPadding => layout.responsiveValue(
    mobile: 12,
    desktop: 16,
    tablet: 20,
  );
  
  double get cardMargin => layout.responsiveValue(
    mobile: 6,
    desktop: 8,
    tablet: 10,
  );
  
  double get borderRadius => layout.responsiveValue(
    mobile: 12,
    desktop: 16,
    tablet: 20,
  );
  
  double get smallBorderRadius => layout.responsiveValue(
    mobile: 4,
    desktop: 5,
    tablet: 6,
  );
  
  double get avatarBorderRadius => layout.responsiveValue(
    mobile: 6,
    desktop: 8,
    tablet: 10,
  );
  
  EdgeInsets get cardMargins => EdgeInsets.symmetric(
    vertical: cardMargin,
    horizontal: layout.isMobile ? 8 : 0,
  );
  
  EdgeInsets get cardPaddings => EdgeInsets.all(cardPadding);
  
  EdgeInsets get buttonPadding => layout.responsivePadding(
    mobile: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    desktop: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  );
  
  EdgeInsets get engagementButtonPadding => layout.responsivePadding(
    mobile: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    desktop: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );
}

extension ResponsiveExtension on BuildContext {
  ResponsiveLayout get responsive => ResponsiveLayout(this);
  ResponsiveSizes get sizes => ResponsiveSizes(this);
}