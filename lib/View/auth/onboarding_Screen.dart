import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';
import '../../Provider/OnboardingProvider.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';
import '../../core/utils/routes/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Scaffold(
        body: Consumer<OnboardingProvider>(
          builder: (context, provider, child) {
            final currentItem = provider.onboardingItems[provider.currentIndex];
            return SizedBox(
              height: context.screenHeight,
              width: context.screenWidth,
              child: Stack(
                children: [
                  CarouselSlider(
                    carouselController: provider.carouselController,
                    options: CarouselOptions(
                      height: context.screenHeight,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: false,
                      scrollDirection: Axis.horizontal,
                      pageSnapping: true,
                      enlargeCenterPage: false,
                      autoPlay: false,
                      scrollPhysics: PageScrollPhysics(),
                      onPageChanged: (index, reason) {
                        provider.setCurrentIndex(index);
                      },
                    ),
                    items: provider.onboardingItems.map((item) {
                      return SizedBox(
                        width: context.screenWidth,
                        height: context.screenHeight,
                        child: Image.asset(item.image, fit: BoxFit.cover),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),

                  Positioned(
                    bottom: context.screenHeight * 0.40,
                    child: IgnorePointer(
                      child: Container(
                        width: context.screenWidth,
                        height: context.screenHeight * 0.30,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.white.withOpacity(0.2),
                              AppColors.white.withOpacity(0.5),
                              AppColors.white.withOpacity(0.8),
                              AppColors.white,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Center(
                              child: AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                child: Text(
                                  currentItem.title,
                                  key: ValueKey(provider.currentIndex),
                                  style: pjsStyleBlack22900.copyWith(
                                    color: AppColors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom content
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: context.screenWidth,
                      height: context.screenHeight * 0.40,
                      decoration: BoxDecoration(color: AppColors.white),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.screenWidth * 0.05,
                          vertical: context.screenHeight * 0.05,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              child: Text(
                                currentItem.description,
                                key: ValueKey('desc_${provider.currentIndex}'),
                                style: pjsStyleBlack14400.copyWith(
                                  color: AppColors.darkGrey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                provider.onboardingItems.length,
                                (index) => GestureDetector(
                                  onTap: () => provider.goToPage(index),
                                  child: Container(
                                    margin: EdgeInsets.symmetric(horizontal: 4),
                                    width: provider.currentIndex == index
                                        ? 24
                                        : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: provider.currentIndex == index
                                          ? AppColors.primary
                                          : AppColors.garyModern200,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            CustomButton2(
                              text: provider.isLastPage
                                  ? 'Get Started'
                                  : 'Continue',
                              onTap: () {
                                if (provider.isLastPage) {
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.loginScreen,
                                  );
                                } else {
                                  provider.nextPage();
                                }
                              },
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RoutesName.signupScreen,
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: pjsStyleBlack16400.copyWith(
                                    color: AppColors.black,
                                  ),
                                  children: [
                                    TextSpan(text: "Don't have an account? "),
                                    TextSpan(
                                      text: "Register",
                                      style: pjsStyleBlack16400.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
