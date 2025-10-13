import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../Model/userModel.dart';
import '../core/utils/validation/signup_validation.dart';

class SignupProvider extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController homeCityController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController nationalityController = TextEditingController();


  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();
  final FocusNode fullNameFocusNode = FocusNode();
  final FocusNode dateOfBirthFocusNode = FocusNode();
  final FocusNode homeCityFocusNode = FocusNode();
  final FocusNode bioFocusNode = FocusNode();

  File? _profileImage;
  String _selectedNationality = 'Pakistan';
  bool _isTermsAccepted = false;
  DateTime? _selectedDate;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  // Loading states
  bool _isLoading = false;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  // Getters
  File? get profileImage => _profileImage;
  String get selectedNationality => _selectedNationality;
  bool get isTermsAccepted => _isTermsAccepted;
  DateTime? get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Methods
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );

      if (image != null) {
        _profileImage = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void setNationality(String nationality) {
    _selectedNationality = nationality;
    notifyListeners();
  }

  void toggleTermsAcceptance() {
    _isTermsAccepted = !_isTermsAccepted;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    dateOfBirthController.text =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return null;

    try {
      print('Starting image upload...');
      final String fileName =
          'profile_pictures/${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('File name: $fileName');
      final Reference ref = _storage.ref().child(fileName);
      print('Storage reference created');
      final UploadTask uploadTask = ref.putFile(_profileImage!);
      print('Upload task started');
      final TaskSnapshot snapshot = await uploadTask;
      print('Upload completed, getting download URL...');
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Download URL obtained: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }


  Future<bool> signUp() async {
    // Validate all fields using the validation class
    final Map<String, String?> validationResults =
        SignupValidation.validateSignupForm(
          email: emailController.text,
          password: passwordController.text,
          confirmPassword: confirmPasswordController.text,
          fullName: fullNameController.text,
          homeCity: homeCityController.text,
          dateOfBirth: _selectedDate,
          profileImage: _profileImage,
          bio: bioController.text,
          nationality: _selectedNationality,
          isTermsAccepted: _isTermsAccepted,
        );

    if (!SignupValidation.isFormValid(validationResults)) {
      final String? firstError = SignupValidation.getFirstErrorMessage(
        validationResults,
      );
      setErrorMessage(
        firstError ?? 'Please fill all required fields correctly',
      );
      return false;
    }

    setLoading(true);
    setErrorMessage(null);

    try {
      // 1. Create user account with email and password
      print('Creating Firebase Auth user...');
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      final User? user = userCredential.user;
      if (user == null) {
        setErrorMessage('Failed to create user account');
        setLoading(false);
        return false;
      }
      print('Firebase Auth user created with UID: ${user.uid}');

      // 2. Upload profile image FIRST and get URL
      String? profileImageUrl;
      if (_profileImage != null) {
        print('Uploading profile image to Firebase Storage...');
        profileImageUrl = await _uploadProfileImage();
        if (profileImageUrl != null) {
          print('✅ Profile image uploaded successfully');
          print('📷 Image URL: $profileImageUrl');
        } else {
          print('❌ Failed to upload profile image');
          // Delete the user account if image upload fails
          try {
            await user.delete();
            print('User account deleted due to image upload failure');
          } catch (deleteError) {
            print('Failed to delete user account: $deleteError');
          }
          setErrorMessage('Failed to upload profile image. Please try again.');
          setLoading(false);
          return false;
        }
      } else {
        print('No profile image selected');
      }

      print('Preparing user data for Firestore...');
      final DateTime now = DateTime.now();
      
      // Create UserModel instance
      final UserModel userModel = UserModel(
        uid: user.uid,
        email: emailController.text.trim(),
        fullName: fullNameController.text.trim(),
        dateOfBirth: _selectedDate,
        nationality: _selectedNationality,
        homeCity: homeCityController.text.trim(),
        createdAt: now,
        role: 'user',
        latitude: null,
        longitude: null,
        currentAddress: null,
        lastLocationUpdate: null,
        isLocationSharingEnabled: false,
        profileImageUrl: profileImageUrl,
        bio: bioController.text.trim(),
        feed: 'Global',
      );

      print('📋 User data prepared:');
      print('   - UID: ${userModel.uid}');
      print('   - Email: ${userModel.email}');
      print('   - Full Name: ${userModel.fullName}');
      print('   - Date of Birth: ${userModel.formattedDateOfBirth}');
      print('   - Created At: ${userModel.createdAt}');
      print('   - Profile Image URL: ${userModel.profileImageUrl}');
      print('   - Age: ${userModel.age}');

      // 4. Save user data to Firestore
      print('💾 Saving user data to Firestore...');

      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
        print('✅ User data saved successfully to Firestore');
      } catch (e) {
        print('❌ Error saving to Firestore: $e');
        try {
          await user.delete();
          print('User account deleted due to Firestore save failure');
          if (profileImageUrl != null) {
            try {
              await _storage.refFromURL(profileImageUrl).delete();
              print('Uploaded image deleted due to Firestore save failure');
            } catch (imageDeleteError) {
              print('Failed to delete uploaded image: $imageDeleteError');
            }
          }
        } catch (deleteError) {
          print('Failed to delete user account: $deleteError');
        }
        setErrorMessage('Failed to save user data: $e');
        setLoading(false);
        return false;
      }

      print('🎉 User registration completed successfully!');
      setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'weak-password':
          setErrorMessage('The password provided is too weak.');
          break;
        case 'email-already-in-use':
          setErrorMessage('An account already exists for that email.');
          break;
        case 'invalid-email':
          setErrorMessage('Please enter a valid email address.');
          break;
        default:
          setErrorMessage('An error occurred: ${e.message}');
      }
      return false;
    } catch (e) {
      setLoading(false);
      print('❌ Unexpected error: $e');
      setErrorMessage('An unexpected error occurred: $e');
      return false;
    }
  }

  bool get isFormValid {
    final Map<String, String?> validationResults =
        SignupValidation.validateSignupForm(
          email: emailController.text,
          password: passwordController.text,
          confirmPassword: confirmPasswordController.text,
          fullName: fullNameController.text,
          homeCity: homeCityController.text,
          dateOfBirth: _selectedDate,
          profileImage: _profileImage,
          nationality: _selectedNationality,
          isTermsAccepted: _isTermsAccepted,
          bio: bioController.text,
        );
    return SignupValidation.isFormValid(validationResults);
  }

  // Helper methods for real-time validation
  String? getEmailError() {
    return SignupValidation.validateEmail(emailController.text);
  }

  String? getPasswordError() {
    return SignupValidation.validatePassword(passwordController.text);
  }

  String? getConfirmPasswordError() {
    return SignupValidation.validateConfirmPassword(
      confirmPasswordController.text,
      passwordController.text,
    );
  }

  String? getFullNameError() {
    return SignupValidation.validateFullName(fullNameController.text);
  }

  String? getHomeCityError() {
    return SignupValidation.validateHomeCity(homeCityController.text);
  }

  String? getDateOfBirthError() {
    return SignupValidation.validateDateOfBirth(_selectedDate);
  }

  String? getProfileImageError() {
    return SignupValidation.validateProfileImage(_profileImage);
  }

  String? getNationalityError() {
    return SignupValidation.validateNationality(_selectedNationality);
  }

  String? getTermsError() {
    return SignupValidation.validateTermsAcceptance(_isTermsAccepted);
  }
  UserModel? createUserModelFromForm() {
    if (!isFormValid) return null;

    return UserModel(
      uid: '',
      email: emailController.text.trim(),
      fullName: fullNameController.text.trim(),
      dateOfBirth: _selectedDate,
      nationality: _selectedNationality,
      homeCity: homeCityController.text.trim(),
      createdAt: DateTime.now(),
      role: 'user',
      latitude: null,
      longitude: null,
      currentAddress: null,
      lastLocationUpdate: null,
      isLocationSharingEnabled: false,
      profileImageUrl: null,
      feed: 'Global',
    );
  }

  Map<String, dynamic> getFormDataPreview() {
    return {
      'email': emailController.text.trim(),
      'fullName': fullNameController.text.trim(),
      'phoneNumber': '',
      'dateOfBirth': _selectedDate,
      'nationality': _selectedNationality,
      'homeCity': homeCityController.text.trim(),
      'profileImage': _profileImage != null ? 'Image selected' : null,
    };
  }

  // Method to create user from Google Sign-In data
  Future<bool> createUserFromGoogleSignIn(User googleUser) async {
    try {
      print('Creating user from Google Sign-In data...');
      
      final userRef = _firestore.collection('users').doc(googleUser.uid);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        await userRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'displayName': googleUser.displayName ?? userDoc.data()?['displayName'] ?? '',
        });
        print('✅ Existing user data updated in Firestore');
        return true;
      } else {
        // Create new user from Google data
        final userData = {
          'uid': googleUser.uid,
          'email': googleUser.email ?? '',
          'fullName': googleUser.displayName ?? '',
          'profileImageUrl': googleUser.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'loginProvider': 'google',
          'role': 'user',
          'isActive': true,
          'nationality': '',
          'homeCity': '',
          'dateOfBirth': '',
          'bio': '',
          'latitude': null,
          'longitude': null,
          'currentAddress': null,
          'lastLocationUpdate': null,
          'isLocationSharingEnabled': false,
          'feed': 'Global',
        };

        await userRef.set(userData);
        print('✅ New user created in Firestore from Google Sign-In');
        return true;
      }
    } catch (e) {
      print('❌ Error creating/updating user from Google Sign-In: $e');
      return false;
    }
  }

  // Method to fetch current user data from Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Error fetching current user data: $e');
      return null;
    }
  }

  // Method to check if required profile fields are missing
  Future<bool> isProfileComplete() async {
    try {
      final userData = await getCurrentUserData();
      if (userData == null) return false;

      final requiredFields = ['homeCity', 'dateOfBirth', 'nationality', 'bio'];
      
      for (String field in requiredFields) {
        final value = userData[field];
        if (value == null || value.toString().trim().isEmpty) {
          print('Missing required field: $field');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('❌ Error checking profile completeness: $e');
      return false;
    }
  }

  // Method to populate form fields with existing user data
  Future<void> loadExistingUserData() async {
    try {
      final userData = await getCurrentUserData();
      if (userData == null) return;

      // Pre-fill existing data
      fullNameController.text = userData['fullName'] ?? '';
      emailController.text = userData['email'] ?? '';
      homeCityController.text = userData['homeCity'] ?? '';
      bioController.text = userData['bio'] ?? '';
      
      if (userData['nationality'] != null && userData['nationality'].toString().isNotEmpty) {
        _selectedNationality = userData['nationality'];
      }
      
      if (userData['dateOfBirth'] != null) {
        if (userData['dateOfBirth'] is Timestamp) {
          _selectedDate = (userData['dateOfBirth'] as Timestamp).toDate();
        } else if (userData['dateOfBirth'] is String && userData['dateOfBirth'].toString().isNotEmpty) {
          try {
            _selectedDate = DateTime.parse(userData['dateOfBirth']);
          } catch (e) {
            print('Error parsing date: $e');
          }
        }
        
        if (_selectedDate != null) {
          dateOfBirthController.text = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ Error loading existing user data: $e');
    }
  }

  // Method to update profile information only (for existing users)
  Future<bool> updateProfile() async {
    // Validate required fields for profile update
    final requiredFieldsValid = _validateRequiredFields();
    if (!requiredFieldsValid) {
      return false;
    }

    setLoading(true);
    setErrorMessage(null);

    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        setErrorMessage('No authenticated user found');
        setLoading(false);
        return false;
      }

      print('Updating profile for user: ${user.uid}');
      
      // Upload profile image if selected
      String? profileImageUrl;
      if (_profileImage != null) {
        profileImageUrl = await _uploadProfileImage();
        if (profileImageUrl == null) {
          setErrorMessage('Failed to upload profile image');
          setLoading(false);
          return false;
        }
      }

      // Prepare update data
      final Map<String, dynamic> updateData = {
        'homeCity': homeCityController.text.trim(),
        'nationality': _selectedNationality,
        'bio': bioController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_selectedDate != null) {
        updateData['dateOfBirth'] = Timestamp.fromDate(_selectedDate!);
      }

      if (profileImageUrl != null) {
        updateData['profileImageUrl'] = profileImageUrl;
      }

      // Update user document in Firestore
      await _firestore.collection('users').doc(user.uid).update(updateData);
      
      print('✅ Profile updated successfully');
      setLoading(false);
      return true;
    } catch (e) {
      setLoading(false);
      print('❌ Error updating profile: $e');
      setErrorMessage('Failed to update profile: $e');
      return false;
    }
  }

  // Helper method to validate required fields for profile completion
  bool _validateRequiredFields() {
    if (homeCityController.text.trim().isEmpty) {
      setErrorMessage('Home city is required');
      return false;
    }
    
    if (_selectedDate == null) {
      setErrorMessage('Date of birth is required');
      return false;
    }
    
    if (_selectedNationality.isEmpty) {
      setErrorMessage('Nationality is required');
      return false;
    }
    
    if (bioController.text.trim().isEmpty) {
      setErrorMessage('About section is required');
      return false;
    }
    
    return true;
  }

  // Method to clear all form data
  void clearForm() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    fullNameController.clear();
    dateOfBirthController.clear();
    homeCityController.clear();
    bioController.clear();
    _profileImage = null;
    _selectedNationality = 'Pakistan';
    _isTermsAccepted = false;
    _selectedDate = null;
    _isPasswordVisible = false;
    _isConfirmPasswordVisible = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    dateOfBirthController.dispose();
    homeCityController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    fullNameFocusNode.dispose();
    dateOfBirthFocusNode.dispose();
    homeCityFocusNode.dispose();
    super.dispose();
  }
}
