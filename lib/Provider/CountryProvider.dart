import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

class CountryProvider extends ChangeNotifier {
  final Map<String, String> _selectedCountries = {};
  final Map<String, String> _selectedCountryFlags = {};

  String? getSelectedCountry(String key) {
    return _selectedCountries[key];
  }

  String? getSelectedCountryFlag(String key) {
    return _selectedCountryFlags[key];
  }

  void selectCountry(String key, Country country) {
    _selectedCountries[key] = country.name;
    _selectedCountryFlags[key] = country.flagEmoji;
    notifyListeners();
  }

  void clearCountry(String key) {
    _selectedCountries.remove(key);
    _selectedCountryFlags.remove(key);
    notifyListeners();
  }

  void clearAllCountries() {
    _selectedCountries.clear();
    _selectedCountryFlags.clear();
    notifyListeners();
  }

  bool hasSelectedCountry(String key) {
    return _selectedCountries.containsKey(key) && _selectedCountries[key] != null;
  }
}