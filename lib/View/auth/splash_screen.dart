import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/const/responsive_layout.dart';
import '../../core/utils/routes/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushNamed(context, RoutesName.onboardingScreen);
    });
  }
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final aspectRatio = screenSize.width / screenSize.height;
    
    return SafeArea(
      top: false,
      bottom: true,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: context.responsive.responsive<Widget>(
            mobile: _buildMobileLayout(context, aspectRatio),
            tablet: _buildTabletLayout(context, aspectRatio),
            desktop: _buildDesktopLayout(context, aspectRatio),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, double aspectRatio) {
    // For mobile devices, adapt based on screen size
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Check if it's a small phone (height < 700 or very narrow aspect ratio)
    final isSmallPhone = screenHeight < 700 || aspectRatio < 0.45;
    
    if (isSmallPhone) {
      // For small phones, use fitWidth to show more of the image vertically
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary, // Fill any remaining space with the primary color
          image: DecorationImage(
            image: AssetImage(AppImages.splashScreen),
            fit: BoxFit.fitWidth, // Shows more vertical content
            alignment: Alignment.center,
          ),
        ),
      );
    } else {
      // For larger phones, use cover to fill screen
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.splashScreen),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      );
    }
  }

  Widget _buildTabletLayout(BuildContext context, double aspectRatio) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.screenWidth * 0.1,
        vertical: context.screenHeight * 0.05,
      ),
      child: Image.asset(
        AppImages.splashScreen,
        fit: BoxFit.contain,
        alignment: Alignment.center,
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, double aspectRatio) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16, // Typical mobile aspect ratio
          child: Image.asset(
            AppImages.splashScreen,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}
