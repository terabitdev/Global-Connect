import 'package:flutter/material.dart';

class SelectionProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  String get selectedOption => _selectedIndex == 0 ? 'Countrymen' : 'Global';

  bool isSelected(int index) => _selectedIndex == index;

  void selectOption(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
}

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void navigateToHome() {
    setCurrentIndex(0);
  }

  void navigateToTips() {
    setCurrentIndex(1);
  }

  void navigateToEvents() {
    setCurrentIndex(2);
  }
}