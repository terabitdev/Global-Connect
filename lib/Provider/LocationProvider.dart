import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../Model/userModel.dart';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';
import '../core/services/NetworkAwareFirestore.dart';
import 'user_profile_provider.dart';



class LocationProvider extends ChangeNotifier {
  String? _currentUserCity;
  String? _currentUserCountry;
  String? get currentUserCity => _currentUserCity;
  String? get currentUserCountry => _currentUserCountry;

  LatLng? _currentPosition;
  LatLngBounds? _cityBounds;
  bool _isLoading = false;
  bool _isUpdatingFirebase = false;
  bool _isLoadingUsers = false;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  String? _currentAddress;
  String? _errorMessage;
  List<UserModel> _allUsers = [];
  double _selectedRadius = 5.0;
  double _currentZoom = 13.0;
  
  // Reference to UserProfileProvider for synced filtering
  UserProfileProvider? _userProfileProvider;
  bool _showGlobal = false; // Track current filter mode
  
  // Permission and location service status
  bool _locationServicesEnabled = false;
  LocationPermission _locationPermission = LocationPermission.denied;
  Timer? _permissionCheckTimer;
  bool _isCheckingPermissions = false;
  bool _hasInitialLocationFetched = false;
  bool _isInitializing = true;
  bool _hasValidLocation = false;
  DateTime? _lastSuccessfulLocationFetch;
  
  // Debouncing for marker updates
  Timer? _markerUpdateTimer;
  bool _isUpdatingMarkers = false;
  Set<String> _existingMarkerIds = {};
  
  // Camera movement debouncing for performance
  Timer? _cameraDebounceTimer;
  bool _isCameraMoving = false;
  
  // Getter to check if markers are currently being updated
  bool get isUpdatingMarkers => _isUpdatingMarkers;
  
  LocationProvider() {
    _initializeLocationProvider();
  }
  
  // Set UserProfileProvider reference for synced filtering
  void setUserProfileProvider(UserProfileProvider userProfileProvider) {
    _userProfileProvider = userProfileProvider;
  }
  
  // Update filter mode and refresh markers
  Future<void> updateFilterMode(bool showGlobal) async {
    if (_showGlobal != showGlobal) {
      _showGlobal = showGlobal;
      print('🔄 Filter mode changed to ${showGlobal ? "Global" : "Countrymen"}');
      
      // Force immediate update when filter mode changes
      _markerUpdateTimer?.cancel(); // Cancel any pending updates
      await _updateMarkersFromUserProvider();
      notifyListeners();
    }
  }
  
  // Public method to refresh markers when UserProfileProvider data changes - with debouncing
  Future<void> refreshMarkersFromUserProvider() async {
    // Cancel any pending marker update
    _markerUpdateTimer?.cancel();
    
    // Debounce marker updates to prevent rapid consecutive calls
    _markerUpdateTimer = Timer(Duration(milliseconds: 300), () async {
      if (!_isUpdatingMarkers) {
        await _updateMarkersFromUserProvider();
        notifyListeners();
      }
    });
  }
  
  Future<void> _initializeLocationProvider() async {
    await _checkLocationStatus();
    await _loadCurrentUserCity();
    await _loadUserRadiusPreference();
    await _startListeningToUsers();
    
    // Set initializing to false after a short delay to prevent UI flicker
    Future.delayed(Duration(milliseconds: 500), () {
      _isInitializing = false;
      notifyListeners();
    });
    
    _startPermissionMonitoring();
  }
  
  // Start monitoring for permission changes - only when needed
  void _startPermissionMonitoring() {
    _permissionCheckTimer?.cancel();
    // Only monitor if we don't have location yet or it's been more than 30 seconds since last check
    if (!_hasValidLocation || (_lastSuccessfulLocationFetch != null && 
        DateTime.now().difference(_lastSuccessfulLocationFetch!).inSeconds > 30)) {
      _permissionCheckTimer = Timer.periodic(Duration(seconds: 3), (_) async {
        if (!_isCheckingPermissions && !_hasValidLocation) {
          await _checkAndUpdateLocationStatus();
        }
      });
    }
  }
  
  // Check and update location status - more reliable with caching
  Future<void> _checkAndUpdateLocationStatus() async {
    if (_isCheckingPermissions) return; // Prevent concurrent checks
    _isCheckingPermissions = true;
    
    try {
      bool previousServicesEnabled = _locationServicesEnabled;
      LocationPermission previousPermission = _locationPermission;
      
      // Check current status
      bool currentServicesEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission currentPermission = await Geolocator.checkPermission();
      
      // Only update and notify if there's a significant change
      bool significantChange = false;
      
      if (previousServicesEnabled != currentServicesEnabled) {
        _locationServicesEnabled = currentServicesEnabled;
        significantChange = true;
      }
      
      if (previousPermission != currentPermission) {
        _locationPermission = currentPermission;
        significantChange = true;
      }
      
      // If status improved and we don't have valid location, try to fetch
      if ((!previousServicesEnabled && currentServicesEnabled) ||
          (previousPermission != LocationPermission.always && 
           previousPermission != LocationPermission.whileInUse &&
           (currentPermission == LocationPermission.always ||
            currentPermission == LocationPermission.whileInUse))) {
        
        if (currentServicesEnabled && 
            (currentPermission == LocationPermission.always ||
             currentPermission == LocationPermission.whileInUse)) {
          _errorMessage = null;
          await _fetchLocationImmediately();
        }
      }
      
      // Only notify listeners if there was a significant change
      if (significantChange) {
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error checking location status: $e');
    } finally {
      _isCheckingPermissions = false;
    }
  }
  
  // Fetch location immediately with improved state management
  Future<void> _fetchLocationImmediately() async {
    try {
      if (_hasValidLocation && _currentPosition != null) return;
      
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      print('📍 Fetching location immediately after permission grant...');
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      
      _currentPosition = LatLng(position.latitude, position.longitude);
      _hasInitialLocationFetched = true;
      _hasValidLocation = true;
      _lastSuccessfulLocationFetch = DateTime.now();
      
      print('📍 Location fetched: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      
      // Clear error and update UI
      _errorMessage = null;
      
      // Update circles with new position
      _updateRadiusCircles();
      
      // Update user location in Firebase
      await _updateUserLocationInFirebase(
        position.latitude,
        position.longitude,
      );
      
      // Start listening to users
      await _startListeningToUsers();
      
      // Animate map to current location
      if (_mapController != null) {
        _currentZoom = _calculateZoomLevel(_selectedRadius);
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, _currentZoom),
        );
      }
      
      // Stop monitoring once we have valid location
      _permissionCheckTimer?.cancel();
      
    } catch (e) {
      print('❌ Error fetching location immediately: $e');
      _errorMessage = "Unable to get location. Please try again.";
      _hasValidLocation = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Check initial location status
  Future<void> _checkLocationStatus() async {
    _locationServicesEnabled = await Geolocator.isLocationServiceEnabled();
    _locationPermission = await Geolocator.checkPermission();
    notifyListeners();
  }
  
  Future<void> _loadCurrentUserCity() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        // Wait a bit and retry for users signing in with Google
        await Future.delayed(Duration(milliseconds: 500));
        final User? retryUser = _auth.currentUser;
        if (retryUser == null) return;
        
        return await _loadCurrentUserCityForUser(retryUser);
      }
      
      return await _loadCurrentUserCityForUser(currentUser);
    } catch (e) {
      print('❌ Error loading current user city: $e');
    }
  }
  
  Future<void> _loadCurrentUserCityForUser(User user) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        double? latitude = userData['latitude']?.toDouble();
        double? longitude = userData['longitude']?.toDouble();

        if (latitude != null && longitude != null) {
          await _getCityAndCountryFromCoordinates(latitude, longitude);
          if (_currentUserCity != null) {
            _currentPosition = LatLng(latitude, longitude);
            _createCityBounds();
            print('🏠 Current user city: $_currentUserCity');
            print('🌍 Current user country: $_currentUserCountry');
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('❌ Error loading current user city for user ${user.uid}: $e');
    }
  }
  
  Future<String?> _getCityFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String? city = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea;
        return city?.trim();
      }
    } catch (e) {
      print('❌ Error getting city from coordinates: $e');
    }
    return null;
  }

  Future<void> _getCityAndCountryFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        print("🏷️ Full Placemark: $placemark");
        print("🛑 Locality: ${placemark.locality}");
        print("🛑 SubAdmin: ${placemark.subAdministrativeArea}");
        print("🛑 AdminArea: ${placemark.administrativeArea}");
        print("🛑 Thoroughfare: ${placemark.thoroughfare}");
        print("🛑 SubLocality: ${placemark.subLocality}");

        // Extract city (with stronger fallback)
        _currentUserCity = placemark.locality?.trim();
        if (_currentUserCity == null || _currentUserCity!.isEmpty) {
          _currentUserCity = placemark.subAdministrativeArea?.trim();
        }
        if (_currentUserCity == null || _currentUserCity!.isEmpty) {
          _currentUserCity = placemark.administrativeArea?.trim();
        }

        _currentUserCountry = placemark.country?.trim();

        _currentAddress = '${_currentUserCity ?? ''}, ${_currentUserCountry ?? ''}';


        notifyListeners();
      }
    } catch (e) {
      print('❌ Error getting city and country from coordinates: $e');
    }
  }


  void _createCityBounds() {
    if (_currentPosition == null) return;

    // Define city radius in degrees (approximately 15-20 km radius)
    double cityRadiusInDegrees = 0.15; // Adjust this value based on city size

    double lat = _currentPosition!.latitude;
    double lng = _currentPosition!.longitude;

    _cityBounds = LatLngBounds(
      southwest: LatLng(lat - cityRadiusInDegrees, lng - cityRadiusInDegrees),
      northeast: LatLng(lat + cityRadiusInDegrees, lng + cityRadiusInDegrees),
    );

    print('🏙️ City bounds created: ${_cityBounds.toString()}');
  }
  
  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    print('🗺️ Map controller created');

    // Set initial position and zoom when map is created
    if (_currentPosition != null) {
      _setInitialMapState();
    }
    notifyListeners();
  }

  // Stream subscription for real-time updates
  StreamSubscription<List<UserModel>>? _usersStreamSubscription;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  double get selectedRadius => _selectedRadius;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NetworkAwareFirestore _networkAwareFirestore = NetworkAwareFirestore();

  // Getters
  LatLng? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  bool get isUpdatingFirebase => _isUpdatingFirebase;
  bool get isLoadingUsers => _isLoadingUsers;
  GoogleMapController? get mapController => _mapController;
  Set<Marker> get markers => _markers;
  Set<Circle> get circles => _circles;
  String? get currentAddress => _currentAddress;
  String? get errorMessage => _errorMessage;
  List<UserModel> get allUsers => _allUsers;
  double get currentZoom => _currentZoom;
  double get minZoomLevel => 10.0;
  double get maxZoomLevel => 18.0;
  bool get locationServicesEnabled => _locationServicesEnabled;
  LocationPermission get locationPermission => _locationPermission;
  bool get isInitializing => _isInitializing;
  bool get hasLocationAccess => _hasValidLocation && _currentPosition != null && 
      _locationServicesEnabled && 
      (_locationPermission == LocationPermission.always || 
       _locationPermission == LocationPermission.whileInUse);

  bool _isWithinCityBounds(LatLng position) {
    if (_cityBounds == null) return true;

    return position.latitude >= _cityBounds!.southwest.latitude &&
        position.latitude <= _cityBounds!.northeast.latitude &&
        position.longitude >= _cityBounds!.southwest.longitude &&
        position.longitude <= _cityBounds!.northeast.longitude;
  }

  bool get isCameraWithinCityBounds {
    if (_mapController == null || _cityBounds == null) return true;
    return true;
  }
  
  void onCameraMove(CameraPosition position) {
    // Set camera moving flag for performance optimization
    _isCameraMoving = true;
    
    // Cancel previous debounce timer
    _cameraDebounceTimer?.cancel();
    
    // Store current zoom level without heavy operations
    _currentZoom = position.zoom;
    
    // Only perform bounds checking if city bounds exist and it's necessary
    if (_cityBounds != null) {
      LatLng target = position.target;

      // Lightweight bounds check - only check if significantly outside bounds
      bool isSignificantlyOutside = target.latitude < _cityBounds!.southwest.latitude - 0.01 ||
          target.latitude > _cityBounds!.northeast.latitude + 0.01 ||
          target.longitude < _cityBounds!.southwest.longitude - 0.01 ||
          target.longitude > _cityBounds!.northeast.longitude + 0.01;

      if (isSignificantlyOutside) {
        // Debounce the bounds correction to avoid excessive camera animations
        _cameraDebounceTimer = Timer(Duration(milliseconds: 200), () {
          _correctCameraBounds(target);
        });
      }
    }
  }
  
  // Separate method for bounds correction to improve performance
  void _correctCameraBounds(LatLng target) {
    if (_cityBounds == null || _mapController == null) return;
    
    // Constrain the target within bounds
    double constrainedLat = target.latitude.clamp(
      _cityBounds!.southwest.latitude,
      _cityBounds!.northeast.latitude,
    );

    double constrainedLng = target.longitude.clamp(
      _cityBounds!.southwest.longitude,
      _cityBounds!.northeast.longitude,
    );

    LatLng constrainedTarget = LatLng(constrainedLat, constrainedLng);

    // Only animate if significantly different
    if ((target.latitude - constrainedLat).abs() > 0.001 || 
        (target.longitude - constrainedLng).abs() > 0.001) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(constrainedTarget),
      );
    }
  }

  // Handle camera idle to ensure bounds are respected
  void onCameraIdle() {
    // Set camera moving flag to false
    _isCameraMoving = false;
    
    // Cancel any pending camera operations
    _cameraDebounceTimer?.cancel();
    
    if (_cityBounds == null || _mapController == null) return;

    // Use a debounced approach for expensive bounds checking
    Timer(Duration(milliseconds: 100), () async {
      if (!_isCameraMoving) { // Only proceed if camera is still idle
        try {
          // Get visible region with timeout to prevent hanging
          final bounds = await _mapController!.getVisibleRegion().timeout(
            Duration(milliseconds: 500),
            onTimeout: () {
              // Return current position as fallback
              return LatLngBounds(
                southwest: _currentPosition ?? LatLng(33.6844, 73.0479),
                northeast: _currentPosition ?? LatLng(33.6844, 73.0479),
              );
            },
          );
          
          // Only perform bounds correction if significantly outside
          bool needsCorrection = bounds.southwest.latitude < _cityBounds!.southwest.latitude - 0.005 ||
              bounds.southwest.longitude < _cityBounds!.southwest.longitude - 0.005 ||
              bounds.northeast.latitude > _cityBounds!.northeast.latitude + 0.005 ||
              bounds.northeast.longitude > _cityBounds!.northeast.longitude + 0.005;

          if (needsCorrection) {
            await _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(_cityBounds!, 50.0),
            );
          }
        } catch (e) {
          // Silently handle errors to prevent performance issues
          print('Camera idle optimization: ${e.toString().substring(0, 50)}...');
        }
      }
    });
  }

  // Method to reset camera to city view
  Future<void> resetToCityView() async {
    if (_cityBounds == null || _mapController == null) return;

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(_cityBounds!, 50.0),
      );
      print('🎯 Reset camera to city view');
    } catch (e) {
      print('❌ Error resetting to city view: $e');
    }
  }


  Future<void> _setInitialMapState() async {
    if (_mapController != null && _currentPosition != null) {
      _currentZoom = _calculateZoomLevel(_selectedRadius);

      try {
        // Update circles first
        _updateRadiusCircles();

        // Then animate camera
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, _currentZoom),
        );
        print('🎯 Initial map state set: zoom $_currentZoom, radius ${_selectedRadius}km');

        // Notify listeners to refresh the map
        notifyListeners();
      } catch (e) {
        print('❌ Error setting initial map state: $e');
      }
    }
  }

  final Set<Factory<OneSequenceGestureRecognizer>> cityMapGestureRecognizer = {
    Factory<OneSequenceGestureRecognizer>(() => PanGestureRecognizer()),
    Factory<OneSequenceGestureRecognizer>(() => ScaleGestureRecognizer()),
  };

  Future<void> getCurrentLocation({BuildContext? context}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // Update status
      await _checkLocationStatus();

      // Step 1: Check if location services are enabled on device
      if (!_locationServicesEnabled) {
        _errorMessage = 'Location services are disabled. Please enable them in your device settings.';
        _isLoading = false;
        notifyListeners();
        
        // Show dialog and open settings
        if (context != null && context.mounted) {
          bool? shouldOpenSettings = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Location Services Disabled'),
                content: Text(
                  'To find nearby travelers, please enable Location Services in your device settings.',
                ),
                actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: Text('Open Settings'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              );
            },
          );
          
          if (shouldOpenSettings == true) {
            await Geolocator.openLocationSettings();
            // Start monitoring for when user returns
            _startPermissionMonitoring();
          }
        }
        return;
      }

      // Step 2: Check app location permissions
      if (_locationPermission == LocationPermission.denied) {
        _errorMessage = 'Location permission is required to find nearby travelers.';
        notifyListeners();
        
        // Request permission
        _locationPermission = await Geolocator.requestPermission();
        
        if (_locationPermission == LocationPermission.denied) {
          _errorMessage = 'Location permission denied. Please grant location access to use this feature.';
          _isLoading = false;
          notifyListeners();
          
          if (context != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location permission is required to show nearby travelers'),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () => getCurrentLocation(context: context),
                ),
              ),
            );
          }
          return;
        }
      }

      if (_locationPermission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permission is permanently denied. Please enable it in app settings.';
        _isLoading = false;
        notifyListeners();
        
        if (context != null && context.mounted) {
          bool? shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Location Permission Required'),
                content: Text(
                  'Location access has been permanently denied. Please enable it in app settings to use this feature.',
                ),
                actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: Text('Open Settings'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              );
            },
          );
          
          if (shouldOpenSettings == true) {
            await Geolocator.openAppSettings();
            // Start monitoring for when user returns
            _startPermissionMonitoring();
          }
        }
        return;
      }

      print('📍 Getting current position...');
      
      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ).catchError((e) async {
        // Fallback to last known position if current position fails
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          return lastPosition;
        }
        throw e;
      });

      _currentPosition = LatLng(position.latitude, position.longitude);
      _hasInitialLocationFetched = true;
      _hasValidLocation = true;
      _lastSuccessfulLocationFetch = DateTime.now();
      
      print('📍 Current position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

      // Clear error message on success
      _errorMessage = null;

      // Update circles with new position
      _updateRadiusCircles();

      // Update user location in Firebase
      await _updateUserLocationInFirebase(
        position.latitude,
        position.longitude,
      );

      // Start listening to users
      await _startListeningToUsers();

      // Set camera to current location
      _currentZoom = _calculateZoomLevel(_selectedRadius);
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, _currentZoom),
        );
      }
      
      // Stop monitoring once we have valid location
      _permissionCheckTimer?.cancel();
      
    } catch (e) {
      print("Location Error: $e");
      _errorMessage = "Unable to get location. Please ensure location services are enabled and try again.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Retry location with real-time status check
  Future<void> retryLocationAccess({BuildContext? context}) async {
    _errorMessage = null;
    notifyListeners();
    
    // Check current status
    await _checkLocationStatus();
    
    if (!_locationServicesEnabled) {
      // Open location settings
      await Geolocator.openLocationSettings();
      _startPermissionMonitoring();
    } else if (_locationPermission == LocationPermission.denied) {
      // Permission was never asked or denied (not forever), request it
      _locationPermission = await Geolocator.requestPermission();
      
      if (_locationPermission == LocationPermission.whileInUse || 
          _locationPermission == LocationPermission.always) {
        // Permission granted, fetch location immediately
        await getCurrentLocation(context: context);
      } else if (_locationPermission == LocationPermission.deniedForever) {
        // Now it's permanently denied, open app settings
        await Geolocator.openAppSettings();
        _startPermissionMonitoring();
      }
      notifyListeners();
    } else if (_locationPermission == LocationPermission.deniedForever) {
      // Open app settings for permanently denied
      await Geolocator.openAppSettings();
      _startPermissionMonitoring();
    } else {
      // Permission already granted, fetch location
      await getCurrentLocation(context: context);
    }
  }

  double _calculateZoomLevel(double radiusKm) {
    // Fine-tuned zoom levels for different radius
    if (radiusKm <= 5) {
      return 13.0; // Close view for 5km
    } else if (radiusKm <= 10) {
      return 11.5; // Medium view for 10km
    } else if (radiusKm <= 25) {
      return 9.5; // Wide view for 25km
    } else {
      return 8.0; // Very wide view for larger radius
    }
  }

  // Update radius circles based on current position and selected radius
  void _updateRadiusCircles() {
    if (_currentPosition == null) return;

    _circles.clear();

    // Define all available radius options
    List<double> radiusOptions = [5.0, 10.0, 25.0];

    for (double radius in radiusOptions) {
      // Determine if this is the selected radius
      bool isSelected = radius == _selectedRadius;

      _circles.add(
        Circle(
          circleId: CircleId('radius_${radius}km'),
          center: _currentPosition!,
          radius: radius * 1000, // Convert km to meters
          strokeWidth: isSelected ? 3 : 1,
          strokeColor: isSelected
              ? Colors.blue.shade600
              : Colors.blue.shade300.withOpacity(0.5),
          fillColor: isSelected
              ? Colors.blue.shade100.withOpacity(0.2)
              : Colors.blue.shade50.withOpacity(0.1),
        ),
      );
    }

    print('🔵 Updated ${_circles.length} radius circles');
  }

  /// Set discovery radius and update map zoom in real-time
  Future<void> setDiscoveryRadius(double radiusKm) async {
    try {
      print('🔄 Setting discovery radius to ${radiusKm}km...');

      _selectedRadius = radiusKm;
      _currentZoom = _calculateZoomLevel(radiusKm);

      // Save radius preference to Firebase
      await _saveRadiusToFirebase(radiusKm);

      // Update circles immediately
      _updateRadiusCircles();

      // Immediately notify listeners to refresh the map
      notifyListeners();

      // Small delay to ensure UI updates first
      await Future.delayed(const Duration(milliseconds: 50));

      // Animate camera if position and controller are available
      if (_currentPosition != null && _mapController != null) {
        print('🎯 Animating camera to zoom level $_currentZoom');

        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            _currentPosition!,
            _currentZoom,
          ),
        );

        print('✅ Camera animation completed for ${radiusKm}km radius');
      } else {
        print('⚠️ Cannot animate camera: position=${_currentPosition}, controller=${_mapController}');
      }

      // Update markers for the new radius using UserProfileProvider
      await _updateMarkersFromUserProvider();

      // Final notification to ensure everything is updated
      notifyListeners();

      print('🎉 Discovery radius updated successfully to ${radiusKm}km');
    } catch (e) {
      print('❌ Error setting discovery radius: $e');
      _errorMessage = 'Failed to update radius: $e';
      notifyListeners();
    }
  }

  Future<void> _updateMarkersForRadius() async {
    await _updateMarkersFromUserProvider();
  }
  
  // Updated method to use UserProfileProvider's filtered users with deduplication
  Future<void> _updateMarkersFromUserProvider() async {
    if (_isUpdatingMarkers) return; // Prevent concurrent updates
    _isUpdatingMarkers = true;
    
    try {
      // Get current user ID
      final String? currentUserId = _auth.currentUser?.uid;

      // Get the EXACT same filtered users that appear in ProfileCard list
      List<UserModel> usersToShow = [];
      if (_userProfileProvider != null) {
        usersToShow = _userProfileProvider!.getFilteredUsers(_showGlobal);
        print('🗺️ Map showing ${usersToShow.length} users (same as ProfileCard list)');
      } else {
        // Fallback to old logic if UserProfileProvider not set
        usersToShow = _getUsersWithinRadius();
        print('⚠️ Using fallback filtering, ${usersToShow.length} users found');
      }

      // Create new marker set with deduplication
      Set<Marker> newMarkers = {};
      Set<String> newMarkerIds = {};
      
      for (UserModel user in usersToShow) {
        if (user.latitude == null || user.longitude == null) continue;
        if (newMarkerIds.contains(user.uid)) continue; // Skip duplicates
        
        final bool isCurrentUser = user.uid == currentUserId;

        BitmapDescriptor markerIcon = await _createCustomMarker(
          user: user,
          isCurrentUser: isCurrentUser,
        );

        final Marker marker = Marker(
          markerId: MarkerId(user.uid),
          position: LatLng(user.latitude!, user.longitude!),
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: isCurrentUser ? 'You (${user.fullName})' : user.fullName,
            snippet: user.currentAddress ??
                'Lat: ${user.latitude!.toStringAsFixed(4)}, Lng: ${user.longitude!.toStringAsFixed(4)}',
          ),
          onTap: () {
            _showUserBottomSheet(user, isCurrentUser);
          },
        );

        newMarkers.add(marker);
        newMarkerIds.add(user.uid);
      }

      // Only update if there are actual changes
      if (newMarkerIds != _existingMarkerIds) {
        _markers = newMarkers;
        _existingMarkerIds = newMarkerIds;
        print('✅ Map markers updated: ${_markers.length} users displayed (${_showGlobal ? "Global" : "Countrymen"} mode)');
      }
    } catch (e) {
      print('❌ Error updating markers from UserProfileProvider: $e');
    } finally {
      _isUpdatingMarkers = false;
    }
  }

  List<UserModel> _getUsersWithinRadius() {
    if (_currentPosition == null) return [];

    return _allUsers.where((user) {
      // Check basic location requirements
      if (user.latitude == null || user.longitude == null) return false;

      // Check if user has paused visibility
      if (user.pauseMyVisibility == true) return false;

      // Calculate distance between current user and this user
      double distance = _calculateDistance(
        _currentPosition!,
        LatLng(user.latitude!, user.longitude!),
      );

      // User is visible if:
      // 1. They are within current user's selected discovery radius, AND
      // 2. Current user is within their visibility radius preference
      bool withinDiscoveryRadius = distance <= _selectedRadius;
      bool withinTheirVisibilityRadius = distance <= user.visibilityRadius;

      return withinDiscoveryRadius && withinTheirVisibilityRadius;
    }).toList();
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    ) / 1000; // Convert meters to kilometers
  }

  Future<void> _updateUserLocationInFirebase(
      double latitude,
      double longitude,
      ) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in, cannot update location');
        return;
      }

      _isUpdatingFirebase = true;
      notifyListeners();

      print('💾 Updating user location in Firebase...');
      print('   - User UID: ${currentUser.uid}');
      print('   - Latitude: $latitude');
      print('   - Longitude: $longitude');

      // Get city and country from coordinates before updating Firebase
      await _getCityAndCountryFromCoordinates(latitude, longitude);

      // Prepare the data to update
      Map<String, dynamic> locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'currentAddress': _currentAddress,
        'currentCity': _currentUserCity,
        'currentCountry': _currentUserCountry,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
        'isLocationSharingEnabled': true,
      };

      await _firestore.collection('users').doc(currentUser.uid).update(locationData);

      print('✅ User location updated successfully in Firebase');
      print('   - City: $_currentUserCity');
      print('   - Country: $_currentUserCountry');
    } catch (e) {
      print('❌ Error updating user location in Firebase: $e');
      _errorMessage = 'Failed to save location: $e';
    } finally {
      _isUpdatingFirebase = false;
      notifyListeners();
    }
  }

  Future<void> refreshLocation() async {
    await getCurrentLocation();
  }

  Future<UserModel?> getUserLocationFromFirebase() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return UserModel.fromMap(userData);
      }
    } catch (e) {
      print('❌ Error getting user location from Firebase: $e');
    }
    return null;
  }

  // Convert to Stream for real-time updates
  Stream<List<UserModel>> getAllUserLocationsStreamFromFirebase() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      List<UserModel> users = snapshot.docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final user = UserModel.fromMap(data);

        print("📌 User: ${user.fullName}, "
            "latitude: ${user.latitude}, "
            "longitude: ${user.longitude}, "
            "pauseMyVisibility: ${user.pauseMyVisibility}");

        return user;
      })
          .where((user) =>
      user.latitude != null &&
          user.longitude != null &&
          user.fullName != null &&
          user.isLocationSharingEnabled &&
          (user.pauseMyVisibility == false || user.pauseMyVisibility == null)) // Real-time filter
          .toList();

      print('✅ Stream: Retrieved ${users.length} visible user locations (pauseMyVisibility = false)');
      return users;
    });
  }

  // Start listening to users stream for real-time updates
  Future<void> _startListeningToUsers() async {
    try {
      _isLoadingUsers = true;
      notifyListeners();

      print('🔄 Starting to listen to users stream...');

      // Cancel existing subscription if any
      await _usersStreamSubscription?.cancel();

      // Listen to the stream
      _usersStreamSubscription = getAllUserLocationsStreamFromFirebase().listen(
            (List<UserModel> users) async {
          print('🔄 Received ${users.length} users from stream');

          _allUsers = users;

          // Update circles and markers based on current radius
          _updateRadiusCircles();
          await _updateMarkersForRadius();

          // Notify listeners to update UI
          notifyListeners();

          print('✅ Real-time update: displaying users within ${_selectedRadius}km radius');
        },
        onError: (error) {
          print('❌ Error in users stream: $error');
          _errorMessage = 'Failed to load users: $error';
          notifyListeners();
        },
      );

      print('✅ Successfully started listening to users stream');
    } catch (e) {
      print('❌ Error starting users stream: $e');
      _errorMessage = 'Failed to start real-time updates: $e';
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  // Update the old method to use the new stream approach
  Future<void> loadAllUsersAndDisplayMarkers() async {
    await _startListeningToUsers();
  }

  // Create custom marker with user profile picture and name
  Future<BitmapDescriptor> _createCustomMarker({
    required UserModel user,
    required bool isCurrentUser,
  }) async {
    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);

      // Marker dimensions
      const double markerWidth = 250;
      const double markerHeight = 250;
      const double profileImageSize = 120;

      // Colors
      final Color backgroundColor = isCurrentUser ? Colors.blue : Colors.white;
      final Color borderColor = isCurrentUser ? Colors.blue.shade800 : Colors.grey.shade400;

      // Draw shadow
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);

      canvas.drawCircle(
        Offset(markerWidth / 2, profileImageSize / 2 + 5),
        profileImageSize / 2 + 5,
        shadowPaint,
      );

      // Draw main circle background
      final Paint backgroundPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(markerWidth / 2, profileImageSize / 2),
        profileImageSize / 2 + 3,
        backgroundPaint,
      );

      // Draw border
      final Paint borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(
        Offset(markerWidth / 2, profileImageSize / 2),
        profileImageSize / 2 + 3,
        borderPaint,
      );

      // Draw profile image
      if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
        try {
          final http.Response response = await http.get(Uri.parse(user.profileImageUrl!));
          final Uint8List imageBytes = response.bodyBytes;
          final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
          final ui.FrameInfo frameInfo = await codec.getNextFrame();
          final ui.Image profileImage = frameInfo.image;

          // Create circular clip for profile image
          canvas.save();
          canvas.clipPath(
            Path()
              ..addOval(Rect.fromCircle(
                center: Offset(markerWidth / 2, profileImageSize / 2),
                radius: profileImageSize / 2,
              )),
          );

          canvas.drawImageRect(
            profileImage,
            Rect.fromLTWH(0, 0, profileImage.width.toDouble(), profileImage.height.toDouble()),
            Rect.fromCircle(
              center: Offset(markerWidth / 2, profileImageSize / 2),
              radius: profileImageSize / 2,
            ),
            Paint(),
          );
          canvas.restore();
        } catch (e) {
          print('Error loading profile image for ${user.fullName}: $e');
          _drawDefaultAvatar(canvas, markerWidth, profileImageSize, user.fullName);
        }
      } else {
        _drawDefaultAvatar(canvas, markerWidth, profileImageSize, user.fullName);
      }

      // Draw name background
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: user.fullName.length > 20 ? '${user.fullName.substring(0, 20)}...' : user.fullName,
          style: pjsStyleBlack22700.copyWith(color: AppColors.black),
        ),
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout();

      // Draw name background rounded rectangle
      final RRect nameBackground = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(markerWidth / 2, profileImageSize + 20),
          width: textPainter.width + 16,
          height: 24,
        ),
        const Radius.circular(12),
      );

      final Paint nameBackgroundPaint = Paint()
        ..color = isCurrentUser ? Colors.blue.shade600 : Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawRRect(nameBackground, nameBackgroundPaint);

      // Draw name border
      final Paint nameBorderPaint = Paint()
        ..color = isCurrentUser ? Colors.blue.shade800 : Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRRect(nameBackground, nameBorderPaint);

      // Draw name text
      textPainter.paint(
        canvas,
        Offset(
          markerWidth / 2 - textPainter.width / 2,
          profileImageSize + 20 - textPainter.height / 2,
        ),
      );

      // Draw pointer triangle if current user
      if (isCurrentUser) {
        final Path trianglePath = Path();
        trianglePath.moveTo(markerWidth / 2, markerHeight - 20);
        trianglePath.lineTo(markerWidth / 2 - 8, markerHeight - 35);
        trianglePath.lineTo(markerWidth / 2 + 8, markerHeight - 35);
        trianglePath.close();

        final Paint trianglePaint = Paint()
          ..color = Colors.blue.shade600
          ..style = PaintingStyle.fill;

        canvas.drawPath(trianglePath, trianglePaint);
      }

      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image markerImage = await picture.toImage(
        markerWidth.toInt(),
        markerHeight.toInt(),
      );

      final ByteData? byteData = await markerImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      final Uint8List imageBytes = byteData!.buffer.asUint8List();
      return BitmapDescriptor.fromBytes(imageBytes);
    } catch (e) {
      print('Error creating custom marker for ${user.fullName}: $e');
      // Fallback to default marker
      return isCurrentUser
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  void _drawDefaultAvatar(Canvas canvas, double markerWidth, double profileImageSize, String name) {
    // Draw default avatar background
    final Paint avatarPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(markerWidth / 2, profileImageSize / 2),
      profileImageSize / 2,
      avatarPaint,
    );

    // Draw initial letter
    final TextPainter initialPainter = TextPainter(
      text: TextSpan(
        text: name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    initialPainter.layout();
    initialPainter.paint(
      canvas,
      Offset(
        markerWidth / 2 - initialPainter.width / 2,
        profileImageSize / 2 - initialPainter.height / 2,
      ),
    );
  }

  void _showUserBottomSheet(UserModel user, bool isCurrentUser) {
    // You can implement a bottom sheet to show user details
    print('Show details for ${user.fullName}');
    // This would typically show a bottom sheet with user information
  }

  Future<void> loadSavedLocation() async {
    try {
      UserModel? userModel = await getUserLocationFromFirebase();
      if (userModel != null && userModel.hasLocation) {
        _currentPosition = LatLng(userModel.latitude!, userModel.longitude!);
        _currentAddress = userModel.currentAddress;

        // Update circles with new position
        _updateRadiusCircles();

        // Start listening to users stream for real-time updates
        await _startListeningToUsers();

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition!, _currentZoom),
          );
        }

        print('📍 Loaded saved location: ${userModel.locationCoordinates}');
        notifyListeners();
      } else {
        // If no saved location, still start listening to users
        await _startListeningToUsers();
      }
    } catch (e) {
      print('❌ Error loading saved location: $e');
    }
  }

  void moveToLocation(LatLng location) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15.0));
  }

  void moveToUser(UserModel user) {
    if (user.hasLocation) {
      final LatLng userLocation = LatLng(user.latitude!, user.longitude!);
      moveToLocation(userLocation);
    }
  }

  String getCoordinatesString() {
    if (_currentPosition != null) {
      return 'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\nLng: ${_currentPosition!.longitude.toStringAsFixed(6)}';
    }
    return 'Location not available';
  }

  // Method to clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Save visibility radius preference to Firebase
  Future<void> _saveRadiusToFirebase(double radiusKm) async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _networkAwareFirestore.updateDocument(
        _firestore.collection('users').doc(currentUserId),
        {
          'visibilityRadius': radiusKm,
          'lastRadiusUpdate': FieldValue.serverTimestamp(),
        },
        operationName: 'Save radius preference',
      );

      print('💾 Saved radius preference: ${radiusKm}km to Firebase');
    } on NetworkException catch (e) {
      print('❌ Network error saving radius to Firebase: ${e.message}');
      _errorMessage = 'Failed to save radius preference: ${e.message}';
      notifyListeners();
    } catch (e) {
      print('❌ Error saving radius to Firebase: $e');
    }
  }

  /// Load user's visibility radius preference from Firebase
  Future<void> _loadUserRadiusPreference() async {
    try {
      final String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final double savedRadius = data['visibilityRadius']?.toDouble() ?? 5.0;
        
        // Update local radius without saving back to Firebase
        _selectedRadius = savedRadius;
        _currentZoom = _calculateZoomLevel(savedRadius);
        
        print('📖 Loaded user radius preference: ${savedRadius}km');
      }
    } catch (e) {
      print('❌ Error loading user radius preference: $e');
    }
  }

  // Handle app lifecycle changes
  void onAppResumed() {
    print('🔄 App resumed, checking location status...');
    // Only check if we don't have valid location or it's been a while
    if (!_hasValidLocation || (_lastSuccessfulLocationFetch != null && 
        DateTime.now().difference(_lastSuccessfulLocationFetch!).inMinutes > 5)) {
      _checkAndUpdateLocationStatus();
    }
  }

  void onAppPaused() {
    // Stop monitoring when app is paused to save battery
    _permissionCheckTimer?.cancel();
  }
  
  // Force refresh location status (for manual retry)
  Future<void> forceRefreshLocationStatus() async {
    _hasValidLocation = false;
    _errorMessage = null;
    await _checkLocationStatus();
    await _checkAndUpdateLocationStatus();
    if (!_hasValidLocation) {
      _startPermissionMonitoring();
    }
  }

  // Method to be called after user authentication (especially Google Sign-In)
  Future<void> refreshUserLocationAfterAuth() async {
    try {
      print('🔄 Refreshing user location after authentication...');
      
      // Wait for authentication to complete
      await Future.delayed(Duration(milliseconds: 1000));
      
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return;
      }
      
      print('✅ Authenticated user found: ${currentUser.uid}');
      
      // First, load existing city data from Firebase
      await _loadCurrentUserCityForUser(currentUser);
      
      // If no location data exists in Firebase or current position is null, get fresh location
      if (_currentPosition == null && hasLocationAccess) {
        print('🔄 Getting fresh location for new user...');
        await getCurrentLocation();
      } else if (_currentPosition != null) {
        // Update Firebase with current location data (refresh city/country)
        await _updateUserLocationInFirebase(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        
        // Move camera to current position if map controller exists
        if (_mapController != null) {
          print('📍 Moving camera to user location: $_currentPosition');
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition!, _currentZoom),
          );
        }
      }
      
      print('✅ User location refresh completed');
    } catch (e) {
      print('❌ Error refreshing user location after auth: $e');
    }
  }

  @override
  void dispose() {
    // Cancel timers and subscriptions
    _permissionCheckTimer?.cancel();
    _markerUpdateTimer?.cancel();
    _cameraDebounceTimer?.cancel(); // Cancel camera debounce timer
    _usersStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}