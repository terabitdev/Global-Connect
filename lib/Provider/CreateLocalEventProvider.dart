import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../Model/localEvenModel.dart';
import '../core/services/firebase_services.dart';

class CreateLocalEventProvider extends ChangeNotifier {
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseServices _firebaseServices = FirebaseServices.instance;

  // Text Controllers
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController maxAttendeesController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final FocusNode groupNameFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();
  final FocusNode maxAttendeesFocus = FocusNode();
  final FocusNode locationFocus = FocusNode();

  // Date & Time
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // Location search
  List<String> locationSuggestions = [];
  List<String> placeIds = [];
  bool isSearchingLocation = false;
  String? selectedCategory;
  double? latitude;
  double? longitude;

  // Save state
  bool _isSaving = false;
  String? _errorMessage;

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> searchLocation(String query) async {
    if (query.isEmpty || query.length < 2) {
      locationSuggestions = [];
      notifyListeners();
      return;
    }

    isSearchingLocation = true;
    notifyListeners();

    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&types=geocode'
          '&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          locationSuggestions = [];
          placeIds = [];
          for (var prediction in data['predictions']) {
            locationSuggestions.add(prediction['description'] as String);
            placeIds.add(prediction['place_id'] as String);
          }
        } else {
          locationSuggestions = [];
          placeIds = [];
        }
      } else {
        locationSuggestions = [];
        placeIds = [];
      }
    } catch (e) {
      locationSuggestions = [];
      placeIds = [];
    }

    isSearchingLocation = false;
    notifyListeners();
  }
  Future<void> selectLocation(String location) async {
    locationController.text = location;
    
    // Find the index of the selected location to get the corresponding place ID
    final int index = locationSuggestions.indexOf(location);
    if (index != -1 && index < placeIds.length) {
      await fetchPlaceDetails(placeIds[index]);
    }
    
    locationSuggestions = [];
    placeIds = [];
    notifyListeners();
  }
  
  Future<void> fetchPlaceDetails(String placeId) async {
    try {
      const apiKey = 'AIzaSyA_9Fc_kjnJDIy4FhzAewMZ0ydHlYbgl_U';
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
          }
        }
      }
    } catch (e) {
      // Error fetching place details
    }
  }
  // Category

  final List<String> categories = [
    "Music",
    "Sports",
    "Technology",
    "Food",
    "Art"
  ];

  // Pick Date
  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      selectedDate = picked;
      notifyListeners();
    }
  }

  // Pick Time
  Future<void> pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      selectedTime = picked;
      notifyListeners();
    }
  }

  // Select Category
  void setCategory(String value) {
    selectedCategory = value;
    notifyListeners();
  }

  // Validate form fields
  String? _validateForm({required File? imageFile}) {
    if ((groupNameController.text).trim().isEmpty) {
      return 'Please enter event title';
    }
    if ((descriptionController.text).trim().isEmpty) {
      return 'Please enter description';
    }
    if ((locationController.text).trim().isEmpty) {
      return 'Please select a location';
    }
    final int? maxAttendees = int.tryParse(maxAttendeesController.text.trim());
    if (maxAttendees == null || maxAttendees <= 0) {
      return 'Please enter a valid max attendees (> 0)';
    }
    if (selectedDate == null) {
      return 'Please select a date';
    }
    if (selectedTime == null) {
      return 'Please select a time';
    }
    if (selectedCategory == null || selectedCategory!.trim().isEmpty) {
      return 'Please select a category';
    }
    if (imageFile == null) {
      return 'Please add an event image';
    }
    return null;
  }

  String _formatSelectedTimeWithAmPm(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    
    if (hour == 0) {
      return '12:$minute AM';
    } else if (hour < 12) {
      return '$hour:$minute AM';
    } else if (hour == 12) {
      return '12:$minute PM';
    } else {
      return '${hour - 12}:$minute PM';
    }
  }

  // Save event to Firestore under
  // localgroupchat/{cityName}/localEvent/{autoId} for Local Event
  // groupChatRooms/{groupChatRoomId}/localEvent/{autoId} for Group Event
  Future<bool> saveEvent({
    required String cityName,
    required File? imageFile,
    String eventName = "Local Event",
  }) async {
    // Validate
    final String? validationError = _validateForm(imageFile: imageFile);
    if (validationError != null) {
      _setError(validationError);
      return false;
    }

    try {
      _setError(null);
      _setSaving(true);

      // Determine collection and storage path based on event type
      final bool isGroupEvent = eventName == "Group Event";
      final String collectionName = isGroupEvent ? 'groupChatRooms' : 'localgroupchat';
      final String storageFolder = isGroupEvent ? 'group_events' : 'local_events';
      
      // Ensure parent document exists (merge to avoid overwrite)
      if (isGroupEvent) {
        // For group events, ensure the groupChatRooms document exists
        await _firestore
            .collection('groupChatRooms')
            .doc(cityName)  // This is actually groupChatRoomId
            .set({
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // For local events, ensure the localgroupchat document exists
        await _firestore
            .collection('localgroupchat')
            .doc(cityName)
            .set({
          'cityName': cityName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Upload image
      final String storagePath =
          '$storageFolder/$cityName/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child(storagePath);
      final UploadTask uploadTask = ref.putFile(imageFile!);
      final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      final String imageUrl = await snapshot.ref.getDownloadURL();

      // Create event document with auto ID
      final CollectionReference<Map<String, dynamic>> eventsCol = _firestore
          .collection(collectionName)
          .doc(cityName)
          .collection('localEvent');
      final DocumentReference<Map<String, dynamic>> docRef = eventsCol.doc();

      final LocalEventModel event = LocalEventModel(
        id: docRef.id,
        title: groupNameController.text.trim(),
        description: descriptionController.text.trim(),
        date: selectedDate!,
        time: _formatSelectedTimeWithAmPm(selectedTime!),
        location: locationController.text.trim(),
        imageUrl: imageUrl,
        category: selectedCategory!.trim(),
        maxAttendees: int.parse(maxAttendeesController.text.trim()),
        createdAt: DateTime.now(),
        attendeesIds: [],
        latitude: latitude,
        longitude: longitude,
        createdById: _firebaseServices.getCurrentUserId() ?? '',
      );

      await docRef.set(event.toMap());
      _clearForm();
      _setSaving(false);
      return true;
    } catch (e) {
      _setSaving(false);
      _setError('Failed to save event: $e');
      return false;
    }
  }

  void _clearForm() {
    groupNameController.clear();
    descriptionController.clear();
    maxAttendeesController.clear();
    locationController.clear();
    selectedDate = null;
    selectedTime = null;
    selectedCategory = null;
    locationSuggestions = [];
    placeIds = [];
    isSearchingLocation = false;
    latitude = null;
    longitude = null;
    notifyListeners();
  }
  @override
  void dispose() {
    groupNameController.dispose();
    descriptionController.dispose();
    maxAttendeesController.dispose();
    locationController.dispose();
    groupNameFocus.dispose();
    descriptionFocus.dispose();
    maxAttendeesFocus.dispose();
    locationFocus.dispose();
    super.dispose();
  }
}
