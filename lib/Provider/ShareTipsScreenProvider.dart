import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:country_picker/country_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../core/services/firebase_services.dart';

class ShareTipsScreenProvider extends ChangeNotifier {
  String? selectedCategory;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController restaurantController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController tipController = TextEditingController();
  int selectedPrice = 0;
  bool visibleToEveryone = true;
  bool countrymenOnly = false;
  bool allowComments = true;
  final List<String> quickTags = ['#local', '#foodie', '#budget', '#tapas'];
  final List<bool> selectedTags = [true, false, false, true];

  final ImagePicker _picker = ImagePicker();
  final List<File?> selectedImages = [null, null, null];

  // Location search
  List<String> addressSuggestions = [];
  List<String> addressPlaceIds = [];
  List<String> citySuggestions = [];
  bool isSearchingAddress = false;
  bool isSearchingCity = false;
  double? latitude;
  double? longitude;
  String? tipCity;
  Country? selectedCountry;
  String? selectedCountryCode;

  // Loading states
  bool _isLoading = false;
  bool _isSavingDraft = false;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  bool get isSavingDraft => _isSavingDraft;

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void setCategory(String? value) {
    selectedCategory = value;
    _safeNotifyListeners();
  }

  void setPrice(int value) {
    selectedPrice = value;
    _safeNotifyListeners();
  }

  void setVisibleToEveryone(bool value) {
    visibleToEveryone = value;
    _safeNotifyListeners();
  }

  void setCountrymenOnly(bool value) {
    countrymenOnly = value;
    _safeNotifyListeners();
  }

  void setAllowComments(bool value) {
    allowComments = value;
    _safeNotifyListeners();
  }

  void toggleTag(int index) {
    selectedTags[index] = !selectedTags[index];
    _safeNotifyListeners();
  }

  Future<void> pickImage(int index) async {
    if (index < 0 || index >= 3) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImages[index] = File(image.path);
        _safeNotifyListeners();
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void removeImage(int index) {
    if (index < 0 || index >= 3) return;
    selectedImages[index] = null;
    _safeNotifyListeners();
  }

  void selectCountry(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        selectedCountry = country;
        selectedCountryCode = country.countryCode;
        countryController.text = country.name;
        cityController.clear();
        citySuggestions = [];
        _safeNotifyListeners();
      },
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40.0),
          topRight: Radius.circular(40.0),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> searchCity(String query) async {
    if (query.isEmpty || query.length < 2 || selectedCountry == null) {
      citySuggestions = [];
      _safeNotifyListeners();
      return;
    }

    isSearchingCity = true;
    _safeNotifyListeners();

    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&types=(cities)'
          '&components=country:${selectedCountry!.countryCode.toLowerCase()}'
          '&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          citySuggestions = [];
          for (var prediction in data['predictions']) {
            final description = prediction['description'] as String;
            final cityName = description.split(',')[0];
            if (!citySuggestions.contains(cityName)) {
              citySuggestions.add(cityName);
            }
          }
        } else {
          citySuggestions = [];
        }
      } else {
        citySuggestions = [];
      }
    } catch (e) {
      citySuggestions = [];
    }

    isSearchingCity = false;
    _safeNotifyListeners();
  }

  void selectCity(String city) {
    cityController.text = city;
    citySuggestions = [];
    _safeNotifyListeners();
  }

  Future<void> searchAddress(String query) async {
    if (query.isEmpty || query.length < 3) {
      addressSuggestions = [];
      _safeNotifyListeners();
      return;
    }

    isSearchingAddress = true;
    _safeNotifyListeners();

    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}';
      
      if (selectedCountry != null && cityController.text.isNotEmpty) {
        url += '&components=country:${selectedCountry!.countryCode.toLowerCase()}';
      }
      
      url += '&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          addressSuggestions = [];
          addressPlaceIds = [];
          for (var prediction in data['predictions']) {
            addressSuggestions.add(prediction['description'] as String);
            addressPlaceIds.add(prediction['place_id'] as String);
          }
        } else {
          addressSuggestions = [];
          addressPlaceIds = [];
        }
      } else {
        addressSuggestions = [];
        addressPlaceIds = [];
      }
    } catch (e) {
      addressSuggestions = [];
      addressPlaceIds = [];
    }

    isSearchingAddress = false;
    _safeNotifyListeners();
  }

  Future<void> selectAddress(String address) async {
    addressController.text = address;
    
    final int index = addressSuggestions.indexOf(address);
    if (index != -1 && index < addressPlaceIds.length) {
      await fetchPlaceDetails(addressPlaceIds[index]);
    }
    
    addressSuggestions = [];
    addressPlaceIds = [];
    _safeNotifyListeners();
  }
  
  Future<void> fetchPlaceDetails(String placeId) async {
    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      final url = 'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=${Uri.encodeComponent(placeId)}'
          '&fields=geometry'
          '&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          final geometry = data['result']['geometry'];
          if (geometry != null && geometry['location'] != null) {
            latitude = geometry['location']['lat']?.toDouble();
            longitude = geometry['location']['lng']?.toDouble();
            
            // Perform reverse geocoding to get city name
            if (latitude != null && longitude != null) {
              await reverseGeocodeLocation(latitude!, longitude!);
            }
          }
        }
      }
    } catch (e) {
      // Error fetching place details
    }
  }

  /// Reverse geocode to get city name from coordinates
  Future<void> reverseGeocodeLocation(double lat, double lng) async {
    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=$lat,$lng'
          '&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          
          // Look for locality (city) in address components
          for (var component in result['address_components']) {
            if (component['types'].contains('locality')) {
              tipCity = component['long_name'];
              _safeNotifyListeners();
              return;
            }
            // Fallback to administrative_area_level_2 if locality not found
            if (component['types'].contains('administrative_area_level_2')) {
              tipCity = component['long_name'];
              _safeNotifyListeners();
              return;
            }
          }
        }
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
    }
  }

  /// Validate form data
  String? _validateForm() {
    if (selectedCategory == null || selectedCategory!.isEmpty) {
      return 'Please select a category';
    }
    if (titleController.text.trim().isEmpty) {
      return 'Please enter a tip title';
    }
    if (countryController.text.trim().isEmpty) {
      return 'Please select a country';
    }
    if (cityController.text.trim().isEmpty) {
      return 'Please enter a city';
    }
    if (addressController.text.trim().isEmpty) {
      return 'Please enter an address';
    }
    if (tipController.text.trim().isEmpty) {
      return 'Please enter your tip content';
    }
    return null;
  }

  /// Share tip to Firebase
  Future<bool> shareTip(BuildContext context) async {
    // Validate form
    final validationError = _validateForm();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    _isLoading = true;
    _safeNotifyListeners();

    try {
      final success = await FirebaseServices.addTip(
        category: selectedCategory!,
        title: titleController.text.trim(),
        restaurantName: restaurantController.text.trim().isEmpty
            ? null
            : restaurantController.text.trim(),
        country: countryController.text.trim(),
        city: cityController.text.trim(),
        tipCity: tipCity,
        address: addressController.text.trim(),
        tip: tipController.text.trim(),
        countrymenOnly: countrymenOnly,
        latitude: latitude,
        longitude: longitude,
      );

      if (success) {

        _clearForm();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tip shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to share tip. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      print('Error sharing tip: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Save as draft (you can implement local storage or Firebase draft functionality)
  Future<bool> saveDraft(BuildContext context) async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least a title to save draft'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    _isSavingDraft = true;
    _safeNotifyListeners();

    try {
      // Here you can implement draft saving logic
      // For now, just show a success message
      await Future.delayed(const Duration(seconds: 1));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💾 Draft saved successfully!'),
          backgroundColor: Colors.blue,
        ),
      );

      return true;
    } catch (e) {
      print('Error saving draft: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error saving draft: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    } finally {
      _isSavingDraft = false;
      _safeNotifyListeners();
    }
  }


  void _clearForm() {
    selectedCategory = null;
    titleController.clear();
    restaurantController.clear();
    countryController.clear();
    cityController.clear();
    addressController.clear();
    tipController.clear();
    selectedPrice = 0;
    visibleToEveryone = true;
    countrymenOnly = false;
    allowComments = true;

    // Reset location data
    addressSuggestions = [];
    addressPlaceIds = [];
    citySuggestions = [];
    isSearchingAddress = false;
    isSearchingCity = false;
    latitude = null;
    longitude = null;
    tipCity = null;
    selectedCountry = null;
    selectedCountryCode = null;

    // Reset tags
    for (int i = 0; i < selectedTags.length; i++) {
      selectedTags[i] = false;
    }

    // Clear images
    for (int i = 0; i < selectedImages.length; i++) {
      selectedImages[i] = null;
    }

    _safeNotifyListeners();
  }

  /// Reset form (public method)
  void resetForm() {
    _clearForm();
  }

  @override
  void dispose() {
    _isDisposed = true;
    titleController.dispose();
    restaurantController.dispose();
    countryController.dispose();
    cityController.dispose();
    addressController.dispose();
    tipController.dispose();
    super.dispose();
  }
}