import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../Model/createMemoryModel.dart';

class AddMemoryProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final TextEditingController memoryNameController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController captionController = TextEditingController();

  // State variables
  List<File> _selectedImages = [];
  DateTime? _startDate;
  DateTime? _endDate;
  PrivacySetting _privacy = PrivacySetting.private;
  List<TripStop> _tripStops = [];
  bool _isLoading = false;
  String _uploadProgress = '';
  File? _coverImage;

  // Validation errors
  String? _memoryNameError;
  String? _countryError;
  String? _dateError;
  String? _imagesError;

  // Stepper management
  int _currentStep = 0;
  final int _totalSteps = 4;
  int _selectedTabIndex = 0;

  // Maps for managing controllers and focus nodes
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  // Getters
  List<File> get selectedImages => _selectedImages;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  PrivacySetting get privacy => _privacy;
  List<TripStop> get tripStops => _tripStops;
  bool get isLoading => _isLoading;
  String get uploadProgress => _uploadProgress;
  String? get memoryNameError => _memoryNameError;
  String? get countryError => _countryError;
  String? get dateError => _dateError;
  String? get imagesError => _imagesError;
  int get currentStep => _currentStep;
  int get totalSteps => _totalSteps;
  int get selectedTabIndex => _selectedTabIndex;
  File? get coverImage => _coverImage;

  // Stepper management
  void setStep(int step) {
    if (step >= 0 && step < _totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  bool setStepWithValidation(int step) {
    if (step > _currentStep && !canProceedToNextStep()) {
      return false;
    }
    if (step >= 0 && step < _totalSteps) {
      _currentStep = step;
      notifyListeners();
      return true;
    }
    return false;
  }

  void nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  bool isStepActive(int stepIndex) {
    return stepIndex == _currentStep;
  }

  bool isStepCompleted(int stepIndex) {
    return stepIndex < _currentStep;
  }

  void setSelectedTab(int tabIndex) {
    if (tabIndex >= 0 && tabIndex <= 1) {
      _selectedTabIndex = tabIndex;
      _privacy = tabIndex == 0 ? PrivacySetting.private : PrivacySetting.public;
      notifyListeners();
    }
  }

  // Validation methods
  bool _validateMemoryName() {
    if (memoryNameController.text.trim().isEmpty) {
      _memoryNameError = 'Memory name is required';
      return false;
    }
    if (memoryNameController.text.trim().length < 3) {
      _memoryNameError = 'Memory name must be at least 3 characters';
      return false;
    }
    if (memoryNameController.text.trim().length > 50) {
      _memoryNameError = 'Memory name must be less than 50 characters';
      return false;
    }
    _memoryNameError = null;
    return true;
  }

  bool _validateCountry() {
    if (countryController.text.trim().isEmpty) {
      _countryError = 'Country is required';
      return false;
    }
    _countryError = null;
    return true;
  }

  bool _validateDates() {
    if (_startDate == null || _endDate == null) {
      _dateError = 'Both start and end dates are required';
      return false;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _dateError = 'End date cannot be before start date';
      return false;
    }
    final difference = _endDate!.difference(_startDate!).inDays;
    if (difference > 365) {
      _dateError = 'Trip cannot be longer than 1 year';
      return false;
    }
    _dateError = null;
    return true;
  }

  bool _validateImages() {
    if (_selectedImages.isEmpty) {
      _imagesError = 'At least one image is required';
      return false;
    }
    if (_selectedImages.length > 10) {
      _imagesError = 'Maximum 10 images allowed';
      return false;
    }
    _imagesError = null;
    return true;
  }

  bool validateStep(int step) {
    switch (step) {
      case 0: // Basic Info
        return _validateMemoryName() && _validateCountry() && _validateDates();
      case 1: // Trip Stops - optional
        return true;
      case 2: // Images
        return _validateImages();
      case 3: // Review - all validations
        return _validateMemoryName() && _validateCountry() && _validateDates() && _validateImages();
      default:
        return false;
    }
  }

  bool canProceedToNextStep() {
    return validateStep(_currentStep);
  }

  bool validateAll() {
    bool isValid = true;
    
    if (!_validateMemoryName()) isValid = false;
    if (!_validateCountry()) isValid = false;
    if (!_validateDates()) isValid = false;
    if (!_validateImages()) isValid = false;
    
    notifyListeners();
    return isValid;
  }


  // Media images picker - multiple image selection (separate from cover)
  Future<void> addMediaImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
      );
      
      if (images.isNotEmpty) {
        _selectedImages = images.map((image) => File(image.path)).toList();
        _imagesError = null;
        notifyListeners();
      }
    } catch (e) {
      _imagesError = 'Failed to pick images';
      notifyListeners();
    }
  }


  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      _validateImages();
      notifyListeners();
    }
  }

  // Date selection methods
  void setStartDate(DateTime date) {
    _startDate = date;
    _validateDates();
    // Update controller
    final controller = getController('startDate');
    controller.text = DateFormat('MM/dd/yyyy').format(date);
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    _endDate = date;
    _validateDates();
    // Update controller
    final controller = getController('endDate');
    controller.text = DateFormat('MM/dd/yyyy').format(date);
    notifyListeners();
  }

  void setPrivacy(PrivacySetting privacy) {
    _privacy = privacy;
    notifyListeners();
  }

  // Legacy methods for backward compatibility with existing UI
  void setMemoryName(String name) {
    memoryNameController.text = name;
    _validateMemoryName();
    notifyListeners();
  }

  void setCountry(String country) {
    countryController.text = country;
    _validateCountry();
    notifyListeners();
  }

  void setCoverImage(File image) {
    _coverImage = image;
    notifyListeners();
  }

  void setCaption(String caption) {
    if (captionController.text != caption) {
      captionController.text = caption;
    }
    notifyListeners();
  }

  // Date picker functionality
  Future<void> pickStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setStartDate(picked);
    }
  }

  Future<void> pickEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setEndDate(picked);
    }
  }

  Future<void> pickTripStopFromDate(BuildContext context, int stopIndex) async {
    if (stopIndex >= 0 && stopIndex < _tripStops.length) {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _tripStops[stopIndex].fromDate ?? _startDate ?? DateTime.now(),
        firstDate: _startDate ?? DateTime(2000),
        lastDate: _endDate ?? DateTime(2030),
      );
      if (picked != null) {
        updateTripStop(stopIndex, fromDate: picked);
        // Update the controller
        final controller = getController('tripStop${stopIndex}From');
        controller.text = DateFormat('MM/dd/yyyy').format(picked);
      }
    }
  }

  Future<void> pickTripStopToDate(BuildContext context, int stopIndex) async {
    if (stopIndex >= 0 && stopIndex < _tripStops.length) {
      final fromDate = _tripStops[stopIndex].fromDate;
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _tripStops[stopIndex].toDate ?? fromDate ?? _startDate ?? DateTime.now(),
        firstDate: fromDate ?? _startDate ?? DateTime(2000),
        lastDate: _endDate ?? DateTime(2030),
      );
      if (picked != null) {
        updateTripStop(stopIndex, toDate: picked);
        // Update the controller
        final controller = getController('tripStop${stopIndex}To');
        controller.text = DateFormat('MM/dd/yyyy').format(picked);
      }
    }
  }

  // Trip stops management
  void addTripStop() {
    final stopId = DateTime.now().millisecondsSinceEpoch.toString();
    final newStop = TripStop(
      stopId: stopId,
      country: '',
      fromDate: _startDate ?? DateTime.now(),
      toDate: _endDate ?? DateTime.now(),
      order: _tripStops.length,
    );
    _tripStops.add(newStop);
    notifyListeners();
  }

  void removeTripStop(int index) {
    if (index >= 0 && index < _tripStops.length) {
      _tripStops.removeAt(index);
      // Update order for remaining stops
      for (int i = 0; i < _tripStops.length; i++) {
        _tripStops[i] = _tripStops[i].copyWith(order: i);
      }
      notifyListeners();
    }
  }

  void updateTripStop(int index, {
    String? country,
    String? city,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    if (index >= 0 && index < _tripStops.length) {
      _tripStops[index] = _tripStops[index].copyWith(
        country: country,
        city: city,
        fromDate: fromDate,
        toDate: toDate,
      );
      notifyListeners();
    }
  }

  // Main memory creation method
  Future<bool> createMemory() async {
    if (!validateAll()) {
      return false;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _uploadProgress = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _uploadProgress = 'Starting upload...';
    notifyListeners();

    try {
      final memoryId = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('userMemory')
          .doc()
          .id;

      // Upload images to Firebase Storage
      final mediaImageUrls = await _uploadImages(user.uid, memoryNameController.text.trim(), memoryId);
      
      if (mediaImageUrls.isEmpty) {
        throw Exception('Failed to upload images');
      }

      // Set first image as cover image by default
      final coverImageUrl = mediaImageUrls.first;

      // If cover image exists, upload it separately and set as cover
      String finalCoverImageUrl = coverImageUrl;
      if (_coverImage != null) {
        _uploadProgress = 'Uploading cover image...';
        notifyListeners();
        
        final coverFileName = '${user.uid}_cover.jpg';
        // Use same cleaning logic as media images
        final cleanMemoryName = memoryNameController.text.trim()
            .replaceAll(RegExp(r'[^\w\s-]'), '')
            .replaceAll(RegExp(r'\s+'), '_')
            .toLowerCase();
        // Direct path: memories/userId/memoryName/cover.jpg
        final coverPath = 'memories/${user.uid}/$cleanMemoryName/$coverFileName';
        
        final coverRef = _storage.ref().child(coverPath);
        final coverUploadTask = coverRef.putFile(
          _coverImage!,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'memoryId': memoryId,
              'userId': user.uid,
              'memoryName': memoryNameController.text.trim(),
              'imageType': 'cover',
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
        final coverSnapshot = await coverUploadTask;
        finalCoverImageUrl = await coverSnapshot.ref.getDownloadURL();
      }

      // Create memory model
      final memory = CreateMemoryModel(
        memoryId: memoryId,
        memoryName: memoryNameController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        country: countryController.text.trim(),
        privacy: _privacy,
        userId: user.uid,
        mediaImageUrls: mediaImageUrls,
        coverImageUrl: finalCoverImageUrl,
        tripStops: _tripStops,
        createdAt: DateTime.now(),
        caption: captionController.text.trim(),
      );

      // Save to Firestore
      await _saveMemoryToFirestore(user.uid, memory);

      _uploadProgress = 'Memory created successfully!';
      notifyListeners();

      // Clear form after successful creation and brief delay
      await Future.delayed(const Duration(seconds: 1));
      resetForm();

      return true;
    } catch (e) {
      _uploadProgress = 'Failed to create memory: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Simple save method for UI - creates memory with cover image and media images
  Future<bool> saveMemory() async {
    return await createMemory();
  }

  // Check if we have minimum required data for saving
  bool canSaveMemory() {
    return memoryNameController.text.trim().isNotEmpty &&
           countryController.text.trim().isNotEmpty &&
           _startDate != null &&
           _endDate != null &&
           _selectedImages.isNotEmpty; // Media images are required
  }

  // Upload images to Firebase Storage
  Future<List<String>> _uploadImages(String userId, String memoryName, String memoryId) async {
    final List<String> downloadUrls = [];
    
    // Clean memory name for folder path - remove special characters and replace spaces with underscores
    final cleanMemoryName = memoryName.trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    try {
      for (int i = 0; i < _selectedImages.length; i++) {
        _uploadProgress = 'Uploading image ${i + 1} of ${_selectedImages.length}...';
        notifyListeners();

        final file = _selectedImages[i];
        final fileName = '${userId}_${i + 1}.jpg';
        // Direct path: memories/userId/memoryName/fileName
        final path = 'memories/$userId/$cleanMemoryName/$fileName';

        final ref = _storage.ref().child(path);
        final uploadTask = ref.putFile(
          file,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'memoryId': memoryId,
              'userId': userId,
              'memoryName': memoryName,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );

        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          _uploadProgress = 'Uploading image ${i + 1}: ${progress.toInt()}%';
          notifyListeners();
        });

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('Image upload failed: ${e.toString()}');
    }
  }

  // Save memory to Firestore
  Future<void> _saveMemoryToFirestore(String userId, CreateMemoryModel memory) async {
    _uploadProgress = 'Saving memory data...';
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('userMemory')
          .doc(memory.memoryId)
          .set(memory.toJson());
    } catch (e) {
      throw Exception('Failed to save memory data: ${e.toString()}');
    }
  }

  // Cover image picker - single image selection
  Future<void> pickCoverImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        final file = File(image.path);
        // Check file size (limit to 5MB per image)
        final fileSizeInBytes = await file.length();
        if (fileSizeInBytes > 5 * 1024 * 1024) {
          _imagesError = 'Cover image size cannot exceed 5MB';
          notifyListeners();
          return;
        }
        
        // Set cover image separately from media images
        _coverImage = file;
        _imagesError = null; // Clear any previous errors
        notifyListeners();
      }
    } catch (e) {
      _imagesError = 'Error picking cover image: $e';
      notifyListeners();
    }
  }





  // Controller management methods
  TextEditingController getController(String key) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController();
    }
    return _controllers[key]!;
  }

  // Focus node management methods
  FocusNode getFocusNode(String key) {
    if (!_focusNodes.containsKey(key)) {
      _focusNodes[key] = FocusNode();
    }
    return _focusNodes[key]!;
  }

  // Reset form data
  void resetForm() {
    _currentStep = 0;
    _selectedTabIndex = 0;
    _isLoading = false;
    
    // Clear all main controllers
    memoryNameController.clear();
    countryController.clear();
    captionController.clear();
    
    // Clear all state variables
    _selectedImages.clear();
    _startDate = null;
    _endDate = null;
    _privacy = PrivacySetting.private;
    _tripStops.clear();
    _uploadProgress = '';
    _coverImage = null;
    
    // Clear all validation errors
    _memoryNameError = null;
    _countryError = null;
    _dateError = null;
    _imagesError = null;

    for (var controller in _controllers.values) {
      controller.clear();
    }
    
    notifyListeners();
  }

  // Delete memory method
  Future<bool> deleteMemory(CreateMemoryModel memory) async {
    final user = _auth.currentUser;
    if (user == null) {
      _uploadProgress = 'User not authenticated';
      notifyListeners();
      return false;
    }

    // Check if current user is the owner of the memory
    if (memory.userId != user.uid) {
      _uploadProgress = 'You are not authorized to delete this memory';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _uploadProgress = 'Deleting memory...';
    notifyListeners();

    try {
      // Delete from Firestore first
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('userMemory')
          .doc(memory.memoryId)
          .delete();

      // Delete images from Storage
      await _deleteImagesFromStorage(user.uid, memory.memoryName, memory);

      _uploadProgress = 'Memory deleted successfully!';
      notifyListeners();

      await Future.delayed(const Duration(seconds: 1));
      _uploadProgress = '';
      
      return true;
    } catch (e) {
      _uploadProgress = 'Failed to delete memory: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete images from Firebase Storage
  Future<void> _deleteImagesFromStorage(String userId, String memoryName, CreateMemoryModel memory) async {
    _uploadProgress = 'Deleting images...';
    notifyListeners();

    try {
      // Clean memory name for folder path - same logic as upload
      final cleanMemoryName = memoryName.trim()
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .toLowerCase();

      // Delete the entire memory folder
      final folderRef = _storage.ref().child('memories/$userId/$cleanMemoryName');
      
      // List all files in the folder
      final listResult = await folderRef.listAll();
      
      // Delete each file
      for (final item in listResult.items) {
        await item.delete();
      }

      // Also delete any subfolders if they exist
      for (final prefix in listResult.prefixes) {
        final subItems = await prefix.listAll();
        for (final subItem in subItems.items) {
          await subItem.delete();
        }
      }
    } catch (e) {
      throw Exception('Failed to delete images from storage: ${e.toString()}');
    }
  }

  // Check if current user owns the memory
  bool isMemoryOwner(CreateMemoryModel memory) {
    final user = _auth.currentUser;
    return user != null && memory.userId == user.uid;
  }

  // Add view to memory (track who viewed the memory)
  Future<CreateMemoryModel?> addViewToMemory(CreateMemoryModel memory) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('User not authenticated for view tracking');
      return null;
    }

    try {
      // Check if user already viewed this memory (avoid duplicates)
      if (memory.viewedBy.contains(user.uid)) {
        debugPrint('User ${user.uid} already viewed this memory');
        return memory; // Return unchanged memory
      }

      // Add current user to viewedBy array
      final updatedViewedBy = [...memory.viewedBy, user.uid];

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(memory.userId)
          .collection('userMemory')
          .doc(memory.memoryId)
          .update({
        'viewedBy': updatedViewedBy,
      });

      // Return updated memory model
      final updatedMemory = memory.copyWith(viewedBy: updatedViewedBy);
      debugPrint('Added view from user ${user.uid} to memory ${memory.memoryId}. Total views: ${updatedViewedBy.length}');
      
      return updatedMemory;
    } catch (e) {
      debugPrint('Error adding view to memory: $e');
      return null;
    }
  }

  @override
  void dispose() {
    // Dispose main controllers
    memoryNameController.dispose();
    countryController.dispose();
    captionController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    // Dispose all focus nodes
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _focusNodes.clear();

    super.dispose();
  }
}