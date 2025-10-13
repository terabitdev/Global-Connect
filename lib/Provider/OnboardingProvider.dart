import 'package:carousel_slider/carousel_controller.dart';
import 'package:flutter/material.dart';

import '../core/const/app_images.dart';

class OnboardingProvider extends ChangeNotifier {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  int get currentIndex => _currentIndex;
  CarouselSliderController get carouselController => _carouselController;

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      image: AppImages.onBoarding1,
      title: 'Global Connect, Where Every\n Journey Begins',
      description: 'From planning to exploring, TravelMate makes every step of your adventure seamless and unforgettable.',
    ),
    OnboardingItem(
      image: AppImages.onBoarding,
      title: 'Global Connect, Your Passport\n to Unforgettable Adventures',
      description: 'Discover, plan, and set off on an unforgettable journey using our travel app.',
    ),
    OnboardingItem(
      image: AppImages.onBoarding2,
      title: 'Global Connect, The World is\n Yours to Explore',
      description: 'Discover, plan, and experience your next journey with TravelMate — your travel guide to the world.',
    ),
  ];

  List<OnboardingItem> get onboardingItems => _onboardingItems;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void nextPage() {
    if (_currentIndex < _onboardingItems.length - 1) {
      _carouselController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (_currentIndex > 0) {
      _carouselController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToPage(int index) {
    _carouselController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool get isLastPage => _currentIndex == _onboardingItems.length - 1;
  bool get isFirstPage => _currentIndex == 0;

  // Get progress as percentage (useful for progress bars)
  double get progress => (_currentIndex + 1) / _onboardingItems.length;
}
class OnboardingItem {
  final String image;
  final String title;
  final String description;

  OnboardingItem({
    required this.image,
    required this.title,
    required this.description,
  });
}