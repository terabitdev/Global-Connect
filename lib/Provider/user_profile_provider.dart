import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';
import '../Model/userModel.dart';
import '../core/services/firebase_services.dart' show FirebaseServices;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileProvider extends ChangeNotifier {
  List<UserModel> _allUsers = [];
  StreamSubscription<List<UserModel>>? _usersSubscription;
  bool _isLoading = false;
  String? _error;
  UserModel? _currentUser;
  List<UserModel> get allUsers => _allUsers;
  StreamSubscription<UserModel?>? _userSubscription;
  StreamSubscription<int>? _visitedCountriesSubscription;
  UserModel? get currentUser => _currentUser;
  String? _currentCountry;
  bool _isLoadingCountry = false;
  int _visitedCountriesCount = 0;
  bool _isUpdatingProfile = false;
  Map<String, String> _userCountries = {};

  String? get currentCountry => _currentCountry;
  bool get isLoadingCountry => _isLoadingCountry;
  int get visitedCountriesCount => _visitedCountriesCount;
  bool get isUpdatingProfile => _isUpdatingProfile;
  String? get error => _error;

  void listenToCurrentUser() {
    _userSubscription?.cancel();
    _userSubscription = FirebaseServices.instance
        .getCurrentUserStream()
        .listen((user) {
      _currentUser = user;
      notifyListeners();
      if (user != null) {
        if (user.latitude != null && user.longitude != null) {
          getCountryFromCoordinates(user.latitude!, user.longitude!);
        } else {
          _getCurrentLocationForCountry();
        }
      }
    });
    _listenToVisitedCountriesCount();
  }

  void listenToAllUsers() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _usersSubscription?.cancel();
    _usersSubscription = FirebaseServices.instance
        .getAllUsersStream()
        .listen(
          (users) async {
        _allUsers = users;
        _isLoading = false;
        _error = null;
        
        // Get countries for all users
        await _updateUserCountries(users);
        
        notifyListeners();
        print('✅ Users loaded: ${users.length}');
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
        print('❌ Error loading users: $error');
      },
    );
  }
  
  Future<void> _updateUserCountries(List<UserModel> users) async {
    for (UserModel user in users) {
      if (user.latitude != null && user.longitude != null) {
        String? country = await _getCountryForUser(user.latitude!, user.longitude!);
        if (country != null) {
          _userCountries[user.uid] = country;
        }
      }
    }
  }
  
  Future<String?> _getCountryForUser(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        return placemarks.first.country;
      }
    } catch (e) {
      print('Error getting country for user: $e');
    }
    return null;
  }

  List<UserModel> getFilteredUsers(bool showGlobal) {
    List<UserModel> filteredUsers;

    // Apply initial filtering based on countrymen or global
    if (showGlobal) {
      filteredUsers = _allUsers;
    } else {
      // Show only countrymen - filter by current user's nationality
      if (_currentUser?.nationality == null || _currentUser!.nationality.isEmpty) {
        return [];
      }
      filteredUsers = _allUsers.where((user) {
        return user.nationality == _currentUser!.nationality;
      }).toList();
    }

    // Filter by visibility radius
    final int visibilityRadius = _currentUser?.visibilityRadius.toInt() ?? 25; // Default to 25 km if null
    if (_currentUser?.latitude != null && _currentUser?.longitude != null) {
      filteredUsers = filteredUsers.where((user) {
        // Skip users without valid location or if they have visibility paused
        if (user.latitude == null ||
            user.longitude == null ||
            user.pauseMyVisibility) {
          return false;
        }

        // Calculate distance to user
        final double? distance = calculateDistanceToUser(user);
        if (distance == null) {
          return false;
        }

        return distance <= visibilityRadius;
      }).toList();
    } else {
      // If current user has no location, return empty list or handle differently
      return [];
    }

    // Sort by distance (nearest users first)
    filteredUsers.sort((a, b) {
      double? distanceA = calculateDistanceToUser(a);
      double? distanceB = calculateDistanceToUser(b);

      // Handle null distances (put them at the end)
      if (distanceA == null && distanceB == null) return 0;
      if (distanceA == null) return 1;
      if (distanceB == null) return -1;

      return distanceA.compareTo(distanceB);
    });

    return filteredUsers;
  }
  String calculateAge() {
    if (_currentUser?.dateOfBirth == null) {
      return 'Age not available';
    }

    final today = DateTime.now();
    final birthDate = _currentUser!.dateOfBirth!;
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return '$age Years Old';
  }

  void _listenToVisitedCountriesCount() {
    _visitedCountriesSubscription?.cancel();
    _visitedCountriesSubscription = FirebaseServices.instance
        .getVisitedCountriesCountStream()
        .listen((count) {
      _visitedCountriesCount = count;
      notifyListeners();
    });
  }


  double? calculateDistanceToUser(UserModel otherUser) {
    if (_currentUser?.latitude == null ||
        _currentUser?.longitude == null ||
        otherUser.latitude == null ||
        otherUser.longitude == null) {
      return null;
    }

    try {
      double distanceInMeters = Geolocator.distanceBetween(
        _currentUser!.latitude!,
        _currentUser!.longitude!,
        otherUser.latitude!,
        otherUser.longitude!,
      );

      double distanceInKm = distanceInMeters / 1000;
      return distanceInKm;
    } catch (e) {
      print('❌ Error calculating distance: $e');
      return null;
    }
  }


  double getWorldVisitedPercentage() {
    if (_visitedCountriesCount == 0) return 0.0;
    return (_visitedCountriesCount / 195.0);
  }
  Future<void> updatePauseMyVisibility(bool isPaused) async {
    if (_currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'pauseMyVisibility': isPaused,
      });

      _currentUser = _currentUser!.copyWith(pauseMyVisibility: isPaused);
      notifyListeners();

      print('✅ Pause visibility updated to: $isPaused');
    } catch (e) {
      print('❌ Error updating pause visibility: $e');
      rethrow;
    }
  }
  Future<void> updatePushNotificationEnabled(bool isEnabled) async {
    if (_currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'isPushNotificationEnabled': isEnabled,
      });

      _currentUser = _currentUser!.copyWith(isPushNotificationEnabled: isEnabled);
      notifyListeners();

      print('✅ Push notification enabled updated to: $isEnabled');
    } catch (e) {
      print('❌ Error updating push notification enabled: $e');
      rethrow;
    }
  }

  // ✅ Update AppSettings
  Future<void> updateAppSettings(AppSettings newSettings) async {
    if (_currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'appSettings': newSettings.toMap(),
      });

      _currentUser = _currentUser!.updateAppSettings(newSettings);
      notifyListeners();

      print('✅ App settings updated successfully');
    } catch (e) {
      print('❌ Error updating app settings: $e');
      rethrow;
    }
  }

  // ✅ Update specific app setting
  Future<void> updateAppSetting(String settingName, bool value) async {
    if (_currentUser == null) return;

    try {
      AppSettings currentSettings = _currentUser!.appSettings;
      AppSettings newSettings;

      switch (settingName) {
        case 'privateAccount':
          newSettings = currentSettings.copyWith(privateAccount: value);
          break;
        case 'publicProfile':
          newSettings = currentSettings.copyWith(publicProfile: value);
          break;
        case 'showTravelMap':
          newSettings = currentSettings.copyWith(showTravelMap: value);
          break;
        case 'showTravelStats':
          newSettings = currentSettings.copyWith(showTravelStats: value);
          break;
        case 'activityStatus':
          newSettings = currentSettings.copyWith(activityStatus: value);
          break;
        case 'autoDetectCities':
          newSettings = currentSettings.copyWith(autoDetectCities: value);
          break;
        case 'travelNotification':
          newSettings = currentSettings.copyWith(travelNotification: value);
          break;
        case 'locationSharing':
          newSettings = currentSettings.copyWith(locationSharing: value);
          break;
        case 'friendRequests':
          newSettings = currentSettings.copyWith(friendRequests: value);
          break;
        case 'newTipsAndEvents':
          newSettings = currentSettings.copyWith(newTipsAndEvents: value);
          break;
        default:
          print('❌ Unknown setting name: $settingName');
          return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'appSettings': newSettings.toMap(),
      });

      _currentUser = _currentUser!.updateAppSettings(newSettings);
      notifyListeners();

      print('✅ App setting $settingName updated to: $value');
    } catch (e) {
      print('❌ Error updating app setting $settingName: $e');
      rethrow;
    }
  }


  // Get formatted percentage string
  double getFormattedPercentage() {
    double percentage = getWorldVisitedPercentage() * 100;
    return percentage;
  }

  // Get the number of continents visited based on visited countries
  Future<int> getVisitedContinentsCount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return 0;

    try {
      final visitedCountriesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('VisitedCountries')
          .get();

      if (visitedCountriesSnapshot.docs.isEmpty) return 0;

      // Get all visited country names
      final visitedCountryNames = visitedCountriesSnapshot.docs
          .map((doc) => (doc.data()['name'] as String).toLowerCase())
          .toSet();

      // Map countries to continents
      final continentsVisited = <String>{};
      
      // Country to continent mapping
      const countryToContinentMap = {
        // Africa
        'algeria': 'Africa', 'angola': 'Africa', 'benin': 'Africa', 'botswana': 'Africa',
        'burkina faso': 'Africa', 'burundi': 'Africa', 'cameroon': 'Africa', 'cape verde': 'Africa',
        'central african republic': 'Africa', 'chad': 'Africa', 'comoros': 'Africa', 'congo': 'Africa',
        'democratic republic of congo': 'Africa', 'djibouti': 'Africa', 'egypt': 'Africa',
        'equatorial guinea': 'Africa', 'eritrea': 'Africa', 'eswatini': 'Africa', 'ethiopia': 'Africa',
        'gabon': 'Africa', 'gambia': 'Africa', 'ghana': 'Africa', 'guinea': 'Africa',
        'guinea-bissau': 'Africa', 'ivory coast': 'Africa', 'kenya': 'Africa', 'lesotho': 'Africa',
        'liberia': 'Africa', 'libya': 'Africa', 'madagascar': 'Africa', 'malawi': 'Africa',
        'mali': 'Africa', 'mauritania': 'Africa', 'mauritius': 'Africa', 'morocco': 'Africa',
        'mozambique': 'Africa', 'namibia': 'Africa', 'niger': 'Africa', 'nigeria': 'Africa',
        'rwanda': 'Africa', 'sao tome and principe': 'Africa', 'senegal': 'Africa', 'seychelles': 'Africa',
        'sierra leone': 'Africa', 'somalia': 'Africa', 'south africa': 'Africa', 'south sudan': 'Africa',
        'sudan': 'Africa', 'tanzania': 'Africa', 'togo': 'Africa', 'tunisia': 'Africa',
        'uganda': 'Africa', 'zambia': 'Africa', 'zimbabwe': 'Africa',

        // Asia
        'afghanistan': 'Asia', 'armenia': 'Asia', 'azerbaijan': 'Asia', 'bahrain': 'Asia',
        'bangladesh': 'Asia', 'bhutan': 'Asia', 'brunei': 'Asia', 'cambodia': 'Asia',
        'china': 'Asia', 'georgia': 'Asia', 'india': 'Asia', 'indonesia': 'Asia',
        'iran': 'Asia', 'iraq': 'Asia', 'israel': 'Asia', 'japan': 'Asia',
        'jordan': 'Asia', 'kazakhstan': 'Asia', 'kuwait': 'Asia', 'kyrgyzstan': 'Asia',
        'laos': 'Asia', 'lebanon': 'Asia', 'malaysia': 'Asia', 'maldives': 'Asia',
        'mongolia': 'Asia', 'myanmar': 'Asia', 'nepal': 'Asia', 'north korea': 'Asia',
        'oman': 'Asia', 'pakistan': 'Asia', 'palestine': 'Asia', 'philippines': 'Asia',
        'qatar': 'Asia', 'saudi arabia': 'Asia', 'singapore': 'Asia', 'south korea': 'Asia',
        'sri lanka': 'Asia', 'syria': 'Asia', 'taiwan': 'Asia', 'tajikistan': 'Asia',
        'thailand': 'Asia', 'timor-leste': 'Asia', 'turkey': 'Asia', 'turkmenistan': 'Asia',
        'united arab emirates': 'Asia', 'uzbekistan': 'Asia', 'vietnam': 'Asia', 'yemen': 'Asia',

        // Europe
        'albania': 'Europe', 'andorra': 'Europe', 'austria': 'Europe', 'belarus': 'Europe',
        'belgium': 'Europe', 'bosnia and herzegovina': 'Europe', 'bulgaria': 'Europe', 'croatia': 'Europe',
        'cyprus': 'Europe', 'czech republic': 'Europe', 'denmark': 'Europe', 'estonia': 'Europe',
        'finland': 'Europe', 'france': 'Europe', 'germany': 'Europe', 'greece': 'Europe',
        'hungary': 'Europe', 'iceland': 'Europe', 'ireland': 'Europe', 'italy': 'Europe',
        'kosovo': 'Europe', 'latvia': 'Europe', 'liechtenstein': 'Europe', 'lithuania': 'Europe',
        'luxembourg': 'Europe', 'malta': 'Europe', 'moldova': 'Europe', 'monaco': 'Europe',
        'montenegro': 'Europe', 'netherlands': 'Europe', 'north macedonia': 'Europe', 'norway': 'Europe',
        'poland': 'Europe', 'portugal': 'Europe', 'romania': 'Europe', 'russia': 'Europe',
        'san marino': 'Europe', 'serbia': 'Europe', 'slovakia': 'Europe', 'slovenia': 'Europe',
        'spain': 'Europe', 'sweden': 'Europe', 'switzerland': 'Europe', 'ukraine': 'Europe',
        'united kingdom': 'Europe', 'vatican city': 'Europe',

        // North America
        'antigua and barbuda': 'North America', 'bahamas': 'North America', 'barbados': 'North America',
        'belize': 'North America', 'canada': 'North America', 'costa rica': 'North America',
        'cuba': 'North America', 'dominica': 'North America', 'dominican republic': 'North America',
        'el salvador': 'North America', 'grenada': 'North America', 'guatemala': 'North America',
        'haiti': 'North America', 'honduras': 'North America', 'jamaica': 'North America',
        'mexico': 'North America', 'nicaragua': 'North America', 'panama': 'North America',
        'saint kitts and nevis': 'North America', 'saint lucia': 'North America',
        'saint vincent and the grenadines': 'North America', 'trinidad and tobago': 'North America',
        'united states': 'North America',

        // South America
        'argentina': 'South America', 'bolivia': 'South America', 'brazil': 'South America',
        'chile': 'South America', 'colombia': 'South America', 'ecuador': 'South America',
        'guyana': 'South America', 'paraguay': 'South America', 'peru': 'South America',
        'suriname': 'South America', 'uruguay': 'South America', 'venezuela': 'South America',

        // Oceania
        'australia': 'Oceania', 'fiji': 'Oceania', 'kiribati': 'Oceania', 'marshall islands': 'Oceania',
        'micronesia': 'Oceania', 'nauru': 'Oceania', 'new zealand': 'Oceania', 'palau': 'Oceania',
        'papua new guinea': 'Oceania', 'samoa': 'Oceania', 'solomon islands': 'Oceania',
        'tonga': 'Oceania', 'tuvalu': 'Oceania', 'vanuatu': 'Oceania',
      };

      // Check each visited country and add its continent
      for (final countryName in visitedCountryNames) {
        final continent = countryToContinentMap[countryName];
        if (continent != null) {
          continentsVisited.add(continent);
        }
      }

      return continentsVisited.length;
    } catch (e) {
      print('Error calculating visited continents: $e');
      return 0;
    }
  }

  // Method to get current location for country determination
  Future<void> _getCurrentLocationForCountry() async {
    try {
      _isLoadingCountry = true;
      notifyListeners();

      print('📍 Getting current location for country determination...');

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied');
          _currentCountry = null;
          _isLoadingCountry = false;
          notifyListeners();
          return;
        }
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        _currentCountry = null;
        _isLoadingCountry = false;
        notifyListeners();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      );

      print('📍 Current position obtained: ${position.latitude}, ${position.longitude}');

      // Get country from coordinates
      await getCountryFromCoordinates(position.latitude, position.longitude);

      // Update user location in Firebase so distance calculations work
      await _updateUserLocationInFirebase(position.latitude, position.longitude);

    } catch (e) {
      print('❌ Error getting current location for country: $e');
      _currentCountry = null;
      _isLoadingCountry = false;
      notifyListeners();
    }
  }

  Future<String?> getCountryFromCoordinates(double latitude, double longitude) async {
    try {
      _isLoadingCountry = true;
      notifyListeners();

      print('🌍 Getting country for coordinates: $latitude, $longitude');

      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        String? country = placemarks.first.country;
        print('✅ Country found: $country');
        _currentCountry = country;
        _isLoadingCountry = false;
        notifyListeners();

        return country;
      } else {
        print('❌ No placemarks found for coordinates');
        _currentCountry = null;
        _isLoadingCountry = false;
        notifyListeners();

        return null;
      }
    } catch (e) {
      print('❌ Error getting country from coordinates: $e');
      _currentCountry = null;
      _isLoadingCountry = false;
      notifyListeners();

      return null;
    }
  }

  // Method to update user location in Firebase
  Future<void> _updateUserLocationInFirebase(double latitude, double longitude) async {
    if (_currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'latitude': latitude,
        'longitude': longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'isLocationSharingEnabled': true,
      });

      // Update the local currentUser object so distance calculations work immediately
      _currentUser = _currentUser!.copyWith(
        latitude: latitude,
        longitude: longitude,
        lastLocationUpdate: DateTime.now(),
        isLocationSharingEnabled: true,
      );

      print('✅ User location updated in Firebase and locally');
      notifyListeners();
    } catch (e) {
      print('❌ Error updating user location in Firebase: $e');
    }
  }



  // Profile update functionality
  Future<bool> updateUserProfile({
    String? fullName,
    DateTime? dateOfBirth,
    String? nationality,
    String? homeCity,
    String? bio,
    File? newProfileImage,
    String? email,
    String? password,
  }) async {
    if (_currentUser == null) {
      _error = 'No user found';
      notifyListeners();
      return false;
    }

    _isUpdatingProfile = true;
    _error = null;
    notifyListeners();

    try {
      String? newProfileImageUrl;
      
      // Upload new profile image if provided
      if (newProfileImage != null) {
        newProfileImageUrl = await _uploadProfileImage(newProfileImage);
        if (newProfileImageUrl == null) {
          _error = 'Failed to upload profile image';
          _isUpdatingProfile = false;
          notifyListeners();
          return false;
        }
      }

      // Handle email update if provided
      if (email != null && email.trim().isNotEmpty && email.trim() != _currentUser!.email) {
        if (password == null || password.trim().isEmpty) {
          _error = 'Password is required to update email';
          _isUpdatingProfile = false;
          notifyListeners();
          return false;
        }
        
        final success = await updateEmailWithPassword(
          newEmail: email.trim(),
          currentPassword: password.trim(),
        );
        
        if (!success) {
          _isUpdatingProfile = false;
          notifyListeners();
          return false;
        }
      }

      // Create updated user model
      final updatedUser = _currentUser!.copyWith(
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        homeCity: homeCity,
        bio: bio,
        profileImageUrl: newProfileImageUrl ?? _currentUser!.profileImageUrl,
        nationality: nationality,
      );

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update(updatedUser.toMap());

      // Update local state
      _currentUser = updatedUser;
      _isUpdatingProfile = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      _isUpdatingProfile = false;
      notifyListeners();
      return false;
    }
  }

  // Upload profile image to Firebase Storage
  Future<String?> _uploadProfileImage(File imageFile) async {
    try {
      final String fileName = 'profile_pictures/${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Update email with password re-authentication
  Future<bool> updateEmailWithPassword({
    required String newEmail,
    required String currentPassword,
  }) async {
    _isUpdatingProfile = true;
    _error = null;
    notifyListeners();

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        _error = 'No user logged in';
        _isUpdatingProfile = false;
        notifyListeners();
        return false;
      }

      // Validate email format
      if (!_isValidEmail(newEmail)) {
        _error = 'Invalid email format';
        _isUpdatingProfile = false;
        notifyListeners();
        return false;
      }

      // Check if email is the same as current
      if (newEmail.trim().toLowerCase() == user.email!.toLowerCase()) {
        _error = 'New email is the same as current email';
        _isUpdatingProfile = false;
        notifyListeners();
        return false;
      }

      try {
        // Create credential for re-authentication
        final AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        // Re-authenticate user first
        await user.reauthenticateWithCredential(credential);
        print('✅ Re-authentication successful');

        try {
          // Try direct email update first
          await user.updateEmail(newEmail);
          print('✅ Email updated directly in Firebase Auth');
          
          // Update email in Firestore database
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'email': newEmail});
          print('✅ Email updated in Firestore');

          // Update local state immediately
          if (_currentUser != null) {
            _currentUser = _currentUser!.copyWith(email: newEmail);
          }

          _isUpdatingProfile = false;
          notifyListeners();
          return true;
          
        } on FirebaseAuthException catch (directUpdateError) {
          if (directUpdateError.code == 'operation-not-allowed') {
            // Fall back to verification method
            print('⚠️ Direct update not allowed, using verification method');
            
            try {
              // Send verification email to new address
              await user.verifyBeforeUpdateEmail(newEmail);
              print('✅ Verification email sent');
              
              // Update email in Firestore immediately (user will verify later)
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({'email': newEmail});
              print('✅ Email updated in Firestore');

              // Update local state immediately
              if (_currentUser != null) {
                _currentUser = _currentUser!.copyWith(email: newEmail);
              }

              _error = 'Verification email sent to $newEmail. Please check your email and verify to complete the email update.';
              _isUpdatingProfile = false;
              notifyListeners();
              return true;
              
            } catch (verificationError) {
              print('❌ Verification method also failed: $verificationError');
              throw verificationError;
            }
          } else {
            // Re-throw other Firebase auth errors
            throw directUpdateError;
          }
        }

      } on FirebaseAuthException catch (e) {
        _error = _getEmailUpdateErrorMessage(e);
        _isUpdatingProfile = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isUpdatingProfile = false;
      notifyListeners();
      return false;
    }
  }

  // Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }


  // Get user-friendly error message for email update failures
  String _getEmailUpdateErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already in use by another account';
      case 'invalid-email':
        return 'Invalid email format';
      case 'operation-not-allowed':
        return 'Email update is not enabled in Firebase configuration. Please contact support.';
      case 'weak-password':
        return 'Password is too weak';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid password. Please check your password and try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'requires-recent-login':
        return 'Please log out and log back in, then try again.';
      case 'admin-restricted-operation':
        return 'Email update is restricted by administrator settings.';
      case 'credential-already-in-use':
        return 'This email is already linked to another account.';
      default:
        return 'Failed to update email: ${e.message ?? 'Unknown error'}';
    }
  }



  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
String getFlagByNationality(String? nationality) {
  if (nationality == null) return '🏳️';

  final Map<String, String> nationalityToFlag = {
    'Pakistani': '🇵🇰',
    'American': '🇺🇸',
    'British': '🇬🇧',
    'Canadian': '🇨🇦',
    'German': '🇩🇪',
    'French': '🇫🇷',
    'Spanish': '🇪🇸',
    'Italian': '🇮🇹',
    'Indian': '🇮🇳',
    'Chinese': '🇨🇳',
    'Japanese': '🇯🇵',
    'Korean': '🇰🇷',
    'Australian': '🇦🇺',
    'Brazilian': '🇧🇷',
    'Mexican': '🇲🇽',
    'Russian': '🇷🇺',
    'Turkish': '🇹🇷',
    'Saudi': '🇸🇦',
    'UAE': '🇦🇪',
    'Egyptian': '🇪🇬',
    'South African': '🇿🇦',
    'Nigerian': '🇳🇬',
    'Bangladeshi': '🇧🇩',
    'Sri Lankan': '🇱🇰',
    'Nepali': '🇳🇵',
    'Afghan': '🇦🇫',
    'Iranian': '🇮🇷',
    'Iraqi': '🇮🇶',
    'Dutch': '🇳🇱',
    'Swedish': '🇸🇪',
    'Norwegian': '🇳🇴',
    'Danish': '🇩🇰',
    'Finnish': '🇫🇮',
    'Swiss': '🇨🇭',
    'Austrian': '🇦🇹',
    'Belgian': '🇧🇪',
    'Portuguese': '🇵🇹',
    'Greek': '🇬🇷',
    'Polish': '🇵🇱',
    'Czech': '🇨🇿',
    'Hungarian': '🇭🇺',
    'Romanian': '🇷🇴',
    'Bulgarian': '🇧🇬',
    'Croatian': '🇭🇷',
    'Serbian': '🇷🇸',
    'Ukrainian': '🇺🇦',
    'Belarusian': '🇧🇾',
    'Lithuanian': '🇱🇹',
    'Latvian': '🇱🇻',
    'Estonian': '🇪🇪',
    'Singaporean': '🇸🇬',
    'Malaysian': '🇲🇾',
    'Indonesian': '🇮🇩',
    'Filipino': '🇵🇭',
    'Thai': '🇹🇭',
    'Vietnamese': '🇻🇳',
    'Cambodian': '🇰🇭',
    'Laotian': '🇱🇦',
    'Mongolian': '🇲🇳',
    'Kazakh': '🇰🇿',
    'Uzbek': '🇺🇿',
    'Kyrgyz': '🇰🇬',
    'Tajik': '🇹🇯',
    'Turkmen': '🇹🇲',
    'Armenian': '🇦🇲',
    'Georgian': '🇬🇪',
    'Azerbaijani': '🇦🇿',
    'Israeli': '🇮🇱',
    'Jordanian': '🇯🇴',
    'Lebanese': '🇱🇧',
    'Syrian': '🇸🇾',
    'Kuwaiti': '🇰🇼',
    'Qatari': '🇶🇦',
    'Bahraini': '🇧🇭',
    'Omani': '🇴🇲',
    'Yemeni': '🇾🇪',
    'Moroccan': '🇲🇦',
    'Algerian': '🇩🇿',
    'Tunisian': '🇹🇳',
    'Libyan': '🇱🇾',
    'Sudanese': '🇸🇩',
    'Ethiopian': '🇪🇹',
    'Kenyan': '🇰🇪',
    'Tanzanian': '🇹🇿',
    'Ugandan': '🇺🇬',
    'Zimbabwean': '🇿🇼',
    'Ghanaian': '🇬🇭',
    'Senegalese': '🇸🇳',
    'Ivorian': '🇨🇮',
    'Cameroonian': '🇨🇲',
    'Malian': '🇲🇱',
    'Burkinabe': '🇧🇫',
    'Chilean': '🇨🇱',
    'Argentine': '🇦🇷',
    'Peruvian': '🇵🇪',
    'Colombian': '🇨🇴',
    'Venezuelan': '🇻🇪',
    'Ecuadorian': '🇪🇨',
    'Bolivian': '🇧🇴',
    'Paraguayan': '🇵🇾',
    'Uruguayan': '🇺🇾',
    "France": "🇫🇷",


  };

  String normalizedNationality = nationality.toLowerCase();

  // Try exact match first
  for (String key in nationalityToFlag.keys) {
    if (key.toLowerCase() == normalizedNationality) {
      return nationalityToFlag[key]!;
    }
  }

  for (String key in nationalityToFlag.keys) {
    if (key.toLowerCase().contains(normalizedNationality) ||
        normalizedNationality.contains(key.toLowerCase())) {
      return nationalityToFlag[key]!;
    }
  }
  return '🏳️';
}
String calculateDistanceToRestaurant(dynamic currentUser, double? restaurantLat, double? restaurantLng, String restaurantName) {
  if (currentUser?.latitude == null ||
      currentUser?.longitude == null ||
      restaurantLat == null ||
      restaurantLng == null) {
    return '-- km';
  }

  try {
    double distanceInMeters = Geolocator.distanceBetween(
      currentUser!.latitude!,
      currentUser!.longitude!,
      restaurantLat,
      restaurantLng,
    );

    double distanceInKm = distanceInMeters / 1000;

    print('🗺️ Distance calculated: ${distanceInKm.toStringAsFixed(2)} km to $restaurantName');

    // Format distance for display
    if (distanceInKm < 1) {
      // Show in meters if less than 1 km
      return '${(distanceInKm * 1000).toInt()}m';
    } else {
      // Show in km with 1 decimal place
      return '${distanceInKm.toStringAsFixed(1)}km';
    }
  } catch (e) {
    print('❌ Error calculating distance: $e');
    return '-- km'; // Fallback on error
  }
}