import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';

import '../Model/AddPostModel.dart';

class AddPostProvider extends ChangeNotifier {
  // Controllers
  final TextEditingController captionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();

  // Focus nodes
  final FocusNode captionFocusNode = FocusNode();
  final FocusNode locationFocusNode = FocusNode();
  final FocusNode tagsFocusNode = FocusNode();

  // State variables
  List<File> _selectedImages = [];
  List<String> _existingImages = [];
  List<String> _originalImages = [];
  bool _isLoading = false;
  String _uploadProgress = '';
  double? _selectedLatitude;
  double? _selectedLongitude;
  String _selectedAddress = '';
  List<String> _locationSuggestions = [];
  bool _showSuggestions = false;

  // Edit mode variables
  String? _editingPostId;
  bool _isEditMode = false;

  // Validation errors
  String? _imageError;
  String? _captionError;
  String? _locationError;
  String? _tagsError;

  // Getters
  List<File> get selectedImages => _selectedImages;
  List<String> get existingImages => _existingImages;
  bool get isLoading => _isLoading;
  String get uploadProgress => _uploadProgress;
  String get selectedAddress => _selectedAddress;
  List<String> get locationSuggestions => _locationSuggestions;
  bool get showSuggestions => _showSuggestions;
  String? get imageError => _imageError;
  String? get captionError => _captionError;
  String? get locationError => _locationError;
  String? get tagsError => _tagsError;
  bool get isEditMode => _isEditMode;
  String? get editingPostId => _editingPostId;

  bool get isFormValid =>
      (_selectedImages.isNotEmpty || _existingImages.isNotEmpty) &&
      captionController.text.trim().isNotEmpty &&
      _selectedLatitude != null &&
      _selectedLongitude != null &&
      tagsController.text.trim().isNotEmpty;

  // Image Picker
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImagesFromGallery(BuildContext? context) async {
    try {
      // Removed imageQuality parameter to get full quality images
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isNotEmpty) {
        List<File> processedImages = [];

        for (XFile image in images) {
          final croppedFile = await _getCroppedImage(image.path);
          if (croppedFile != null) {
            // Removed height constraint to preserve original quality
            processedImages.add(File(croppedFile.path));
          }
        }

        if (processedImages.isNotEmpty) {
          _selectedImages.addAll(processedImages);
          _imageError = null;
          notifyListeners();
        }
      }
    } catch (e) {
      _imageError = 'Failed to pick images';
      notifyListeners();
    }
  }

  Future<CroppedFile?> _getCroppedImage(String imagePath) async {
    try {
      return await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
        // Added to maintain maximum quality
        compressQuality: 100,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            rotateButtonsHidden: true,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
    } catch (e) {
      print('Error cropping image: $e');
      return null;
    }
  }

  // Remove the _resizeImageToFixedHeight method since we want to keep original quality
  // Remove _applyHeightConstraint method as well
  Future<File?> _applyHeightConstraint(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final constrainedBytes = await _resizeImageToFixedHeight(imageBytes, 240);
      final directory = imageFile.parent;
      final fileName =
          'constrained_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final constrainedFile = File('${directory.path}/$fileName');
      await constrainedFile.writeAsBytes(constrainedBytes);
      return constrainedFile;
    } catch (e) {
      print('Error applying height constraint: $e');
      return imageFile;
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      if (_selectedImages.isEmpty && _existingImages.isEmpty) {
        _imageError = 'Please select at least one image';
      }
      notifyListeners();
    }
  }

  void removeExistingImage(int index) {
    if (index >= 0 && index < _existingImages.length) {
      _existingImages.removeAt(index);
      if (_selectedImages.isEmpty && _existingImages.isEmpty) {
        _imageError = 'Please select at least one image';
      }
      notifyListeners();
    }
  }

  void initializeForEdit({
    required String postId,
    required String caption,
    required List<String> images,
    required String location,
    required double latitude,
    required double longitude,
    required String hashtags,
  }) {
    _isEditMode = true;
    _editingPostId = postId;

    captionController.text = caption;
    locationController.text = location;
    tagsController.text = hashtags;

    _selectedLatitude = latitude;
    _selectedLongitude = longitude;
    _selectedAddress = location;

    _existingImages = List.from(images);
    _originalImages = List.from(images);
    _selectedImages.clear();

    _imageError = null;
    _captionError = null;
    _locationError = null;
    _tagsError = null;

    notifyListeners();
  }

  // Location autocomplete methods
  Future<void> searchLocation(String query) async {
    if (query.isEmpty) {
      _locationSuggestions.clear();
      _showSuggestions = false;
      notifyListeners();
      return;
    }

    try {
      final String? apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      if (apiKey == null) {
        _locationError = 'Google Maps API key not found';
        notifyListeners();
        return;
      }

      final url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&types=geocode'
          '&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          _locationSuggestions = [];
          for (var prediction in data['predictions']) {
            _locationSuggestions.add(prediction['description'] as String);
          }
          _showSuggestions = _locationSuggestions.isNotEmpty;
          _locationError = null;
        } else {
          _locationSuggestions.clear();
          _showSuggestions = false;
        }
      } else {
        _locationSuggestions.clear();
        _showSuggestions = false;
      }
      notifyListeners();
    } catch (e) {
      _locationSuggestions.clear();
      _showSuggestions = false;
      notifyListeners();
    }
  }

  Future<void> selectLocation(String selectedPlace) async {
    // Immediately update UI to avoid multiple taps
    _selectedAddress = selectedPlace;
    locationController.text = selectedPlace;
    _locationSuggestions.clear();
    _showSuggestions = false;
    _locationError = null;
    notifyListeners();

    // Then get coordinates in background
    await _geocodeLocation(selectedPlace);
  }

  Future<void> _geocodeLocation(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        _selectedLatitude = location.latitude;
        _selectedLongitude = location.longitude;
        _selectedAddress = address;
        locationController.text = address;
        _locationSuggestions.clear();
        _showSuggestions = false;
        _locationError = null;
        notifyListeners();
      } else {
        _locationError = 'Location not found';
        notifyListeners();
      }
    } catch (e) {
      _locationError = 'Failed to get location coordinates';
      notifyListeners();
    }
  }

  void hideSuggestions() {
    _showSuggestions = false;
    notifyListeners();
  }

  // Validation methods
  void validateForm() {
    _imageError = (_selectedImages.isEmpty && _existingImages.isEmpty)
        ? 'Please select at least one image'
        : null;
    _captionError = captionController.text.trim().isEmpty
        ? 'Please enter a caption'
        : null;
    _locationError = (_selectedLatitude == null || _selectedLongitude == null)
        ? 'Please select a location'
        : null;
    _tagsError = tagsController.text.trim().isEmpty
        ? 'Please enter at least one tag'
        : null;

    notifyListeners();
  }

  List<String> _formatTags(String input) {
    // Split by spaces and commas, then format each tag
    return input
        .replaceAll(',', ' ')
        .split(' ')
        .where((tag) => tag.isNotEmpty)
        .map((tag) => tag.startsWith('#') ? tag : '#$tag')
        .toList();
  }

  Future<int> _getNextImageNumber(String userId) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get user document to check total images uploaded
      final DocumentSnapshot userDoc = await firestore
          .collection('addpost')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        final totalImages = data?['totalImages'] ?? 0;
        return totalImages + 1;
      }
      return 1;
    } catch (e) {
      return 1;
    }
  }

  // Method to delete an image from Firebase Storage
  Future<void> _deleteImageFromStorage(String imageUrl) async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instance;

      // Create reference from URL and delete
      final Reference imageRef = storage.refFromURL(imageUrl);
      await imageRef.delete();

      print('✅ Deleted image from storage: ${imageRef.fullPath}');
    } catch (e) {
      print('❌ Error deleting image from storage: $e');
      // Don't throw error as this shouldn't break the update process
    }
  }

  // Method to get list of images to delete (removed from original list)
  List<String> _getImagesToDelete() {
    return _originalImages
        .where((originalUrl) => !_existingImages.contains(originalUrl))
        .toList();
  }

  // Upload post to Firebase using AddPostModel
  Future<bool> uploadPost() async {
    if (_isEditMode && _editingPostId != null) {
      return await _updateExistingPost();
    } else {
      return await _createNewPost();
    }
  }

  Future<bool> _updateExistingPost() async {
    validateForm();

    if (!isFormValid) {
      return false;
    }

    _isLoading = true;
    _uploadProgress = 'Updating post...';
    notifyListeners();

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final String userId = user.uid;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseStorage storage = FirebaseStorage.instance;

      // Step 1: Delete removed images from storage
      final List<String> imagesToDelete = _getImagesToDelete();
      if (imagesToDelete.isNotEmpty) {
        _uploadProgress = 'Cleaning up removed images...';
        notifyListeners();

        for (String imageUrl in imagesToDelete) {
          await _deleteImageFromStorage(imageUrl);
        }

        // Update total images count by decrementing deleted images
        await firestore.collection('addpost').doc(userId).update({
          'totalImages': FieldValue.increment(-imagesToDelete.length),
        });

        print('🗑️ Deleted ${imagesToDelete.length} images from storage');
      }

      // Step 2: Upload new images
      List<String> newImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        _uploadProgress = 'Uploading new images...';
        notifyListeners();

        int nextImageNumber = await _getNextImageNumber(userId);

        for (int i = 0; i < _selectedImages.length; i++) {
          final String fileName = '$userId$nextImageNumber';
          final Reference storageRef = storage
              .ref()
              .child('AllPost')
              .child(userId)
              .child(fileName);

          final UploadTask uploadTask = storageRef.putFile(_selectedImages[i]);

          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            if (snapshot.totalBytes > 0) {
              double progress =
                  (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
              _uploadProgress =
                  'Uploading image ${i + 1}/${_selectedImages.length} (${progress.toInt()}%)';
              notifyListeners();
            }
          });

          final TaskSnapshot snapshot = await uploadTask;
          final String downloadUrl = await snapshot.ref.getDownloadURL();
          newImageUrls.add(downloadUrl);

          nextImageNumber++;
        }

        // Update total images count by incrementing new images
        await firestore.collection('addpost').doc(userId).update({
          'totalImages': FieldValue.increment(_selectedImages.length),
        });

        print('📸 Uploaded ${_selectedImages.length} new images');
      }

      // Step 3: Combine remaining existing images and new images
      List<String> allImages = [..._existingImages, ...newImageUrls];

      // Step 4: Update post data in Firestore
      _uploadProgress = 'Updating post data...';
      notifyListeners();

      final LocationModel locationModel = LocationModel(
        address: _selectedAddress.isNotEmpty
            ? _selectedAddress
            : 'Unknown location',
        latitude: _selectedLatitude ?? 0.0,
        longitude: _selectedLongitude ?? 0.0,
      );

      final Map<String, dynamic> updateData = {
        'caption': captionController.text.trim(),
        'location': locationModel.toJson(),
        'tags': _formatTags(tagsController.text.trim()),
        'images': allImages,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update post in Firestore
      await firestore
          .collection('addpost')
          .doc(userId)
          .collection('posts')
          .doc(_editingPostId)
          .update(updateData);

      _uploadProgress = 'Post updated successfully!';
      notifyListeners();

      print('✅ Post updated successfully');
      print('📊 Final image count: ${allImages.length}');
      print(
        '🔄 Images removed: ${imagesToDelete.length}, Images added: ${newImageUrls.length}',
      );

      // Clear form after successful update
      clearFormExceptProgress();

      return true;
    } catch (e) {
      _uploadProgress = 'Update failed: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _createNewPost() async {
    validateForm();

    if (!isFormValid) {
      return false;
    }

    _isLoading = true;
    _uploadProgress = 'Preparing upload...';
    notifyListeners();

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final String userId = user.uid;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseStorage storage = FirebaseStorage.instance;

      // Get next image number for continuous numbering
      int nextImageNumber = await _getNextImageNumber(userId);

      // Upload images to Firebase Storage with continuous numbering
      _uploadProgress = 'Uploading images to storage...';
      notifyListeners();

      List<String> imageUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        // Filename format: userId + continuous number (e.g., DWZG9YzOlLYLknJ944vE68CunTt21, DWZG9YzOlLYLknJ944vE68CunTt22, etc.)
        final String fileName = '$userId$nextImageNumber';
        final Reference storageRef = storage
            .ref()
            .child('AllPost')
            .child(userId)
            .child(fileName);

        final UploadTask uploadTask = storageRef.putFile(_selectedImages[i]);

        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            double progress =
                (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
            _uploadProgress =
                'Uploading image ${i + 1}/${_selectedImages.length} (${progress.toInt()}%)';
            notifyListeners();
          }
        });

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);

        // Increment for next image
        nextImageNumber++;
      }

      // Prepare post data using AddPostModel
      _uploadProgress = 'Saving post data to Firestore...';
      notifyListeners();

      // Create location model with null safety
      final LocationModel locationModel = LocationModel(
        address: _selectedAddress.isNotEmpty
            ? _selectedAddress
            : 'Unknown location',
        latitude: _selectedLatitude ?? 0.0,
        longitude: _selectedLongitude ?? 0.0,
      );

      // Create post model with proper null checks and initial values
      final AddPost newPost = AddPost(
        postId: '',
        caption: captionController.text.trim().isNotEmpty
            ? captionController.text.trim()
            : '',
        location: locationModel,
        tags: _formatTags(tagsController.text.trim()),
        images: imageUrls,
        userId: userId,
        likes: 0,
        shares: 0,
        commentCount: 0,
        comments: [],
      );

      // Create user document in addpost collection if it doesn't exist
      final DocumentReference userDocRef = firestore
          .collection('addpost')
          .doc(userId);

      // Check if user document exists
      final DocumentSnapshot userDocSnapshot = await userDocRef.get();

      if (!userDocSnapshot.exists) {
        // Create user document with basic info
        await userDocRef.set({
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'totalPosts': 0,
          'totalImages': 0,
        });
      }

      // Add the post as a new document in the posts subcollection
      final CollectionReference postsRef = userDocRef.collection('posts');

      // Add post with auto-generated document ID
      final DocumentReference postDocRef = await postsRef.add(newPost.toJson());

      // Update user document to increment total posts count and total images
      await userDocRef.update({
        'totalPosts': FieldValue.increment(1),
        'totalImages': FieldValue.increment(_selectedImages.length),
        'lastPostAt': FieldValue.serverTimestamp(),
      });

      // Update the post document with its own document ID as postId
      await postDocRef.update({'postId': postDocRef.id});

      // Increment postsCount in user's main profile (users collection)
      await _incrementUserPostsCount(userId);

      _uploadProgress = 'Post uploaded successfully!';
      notifyListeners();

      // Clear form after successful upload (but preserve success message)
      clearFormExceptProgress();

      return true;
    } catch (e) {
      _uploadProgress = 'Upload failed: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Increment user's posts count in their main profile
  Future<void> _incrementUserPostsCount(String userId) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get current user's profile document
      final DocumentReference userDocRef = firestore
          .collection('users')
          .doc(userId);

      // Check if user document exists
      final DocumentSnapshot userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        final socialStats =
            userData?['socialStats'] as Map<String, dynamic>? ?? {};

        // Get current posts count and increment it
        final currentPostsCount =
            int.tryParse(socialStats['postsCount']?.toString() ?? '0') ?? 0;
        final newPostsCount = currentPostsCount + 1;

        // Update the socialStats.postsCount field
        await userDocRef.update({
          'socialStats.postsCount': newPostsCount.toString(),
        });
      }
    } catch (e) {
      // Don't throw error as this shouldn't break the post upload process
      // Just log the error silently
    }
  }

  void clearForm() {
    _selectedImages.clear();
    _existingImages.clear();
    _originalImages.clear();
    captionController.clear();
    locationController.clear();
    tagsController.clear();
    _selectedLatitude = null;
    _selectedLongitude = null;
    _selectedAddress = '';
    _locationSuggestions.clear();
    _showSuggestions = false;
    _imageError = null;
    _captionError = null;
    _locationError = null;
    _tagsError = null;
    _uploadProgress = '';
    _isEditMode = false;
    _editingPostId = null;
    notifyListeners();
  }

  void clearFormExceptProgress() {
    _selectedImages.clear();
    _existingImages.clear();
    _originalImages.clear();
    captionController.clear();
    locationController.clear();
    tagsController.clear();
    _selectedLatitude = null;
    _selectedLongitude = null;
    _selectedAddress = '';
    _locationSuggestions.clear();
    _showSuggestions = false;
    _imageError = null;
    _captionError = null;
    _locationError = null;
    _tagsError = null;
    _isEditMode = false;
    _editingPostId = null;
    notifyListeners();
  }

  Future<Uint8List> _resizeImageToFixedHeight(
    Uint8List imageBytes,
    int maxHeight,
  ) async {
    try {
      // Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;

      // Enforce maximum height constraint - Always resize to max 240px height
      // This ensures no image can be taller than 240px regardless of crop selection
      if (image.height > maxHeight) {
        // Calculate proportional width based on max height limit
        final aspectRatio = image.width / image.height;
        final targetWidth = (maxHeight * aspectRatio).round();

        // Resize the image to max height (240px) with proportional width
        final resizedImage = img.copyResize(
          image,
          width: targetWidth,
          height: maxHeight,
          interpolation: img.Interpolation.cubic,
        );

        // Encode back to bytes
        return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
      } else {
        // Image is within height limit, keep original size
        return imageBytes;
      }
    } catch (e) {
      print('Error resizing image: $e');
      return imageBytes; // Return original if resize fails
    }
  }

  @override
  void dispose() {
    captionController.dispose();
    locationController.dispose();
    tagsController.dispose();
    captionFocusNode.dispose();
    locationFocusNode.dispose();
    tagsFocusNode.dispose();
    super.dispose();
  }
}
