import 'dart:io';

class SignupValidation {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    // You can add more password validation rules here
    // For example: uppercase, lowercase, numbers, special characters
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Full name validation
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    // Check if name contains only letters and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Full name should contain only letters and spaces';
    }
    return null;
  }

  // Home city validation
  static String? validateHomeCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Home city is required';
    }
    if (value.length < 2) {
      return 'Home city must be at least 2 characters';
    }
    return null;
  }

  // Date of birth validation
  static String? validateDateOfBirth(DateTime? selectedDate) {
    if (selectedDate == null) {
      return 'Date of birth is required';
    }
    
    final DateTime now = DateTime.now();
    final DateTime minimumAge = DateTime(now.year - 13, now.month, now.day);
    final DateTime maximumAge = DateTime(now.year - 100, now.month, now.day);
    
    if (selectedDate.isAfter(minimumAge)) {
      return 'You must be at least 13 years old';
    }
    
    if (selectedDate.isBefore(maximumAge)) {
      return 'Please enter a valid date of birth';
    }
    
    return null;
  }

  // Profile image validation
  static String? validateProfileImage(File? profileImage) {
    if (profileImage == null) {
      return 'Profile image is required';
    }
    
    // Check file size (max 5MB)
    final int fileSizeInBytes = profileImage.lengthSync();
    final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
    if (fileSizeInMB > 5) {
      return 'Profile image size should be less than 5MB';
    }
    
    return null;
  }

  // Nationality validation
  static String? validateNationality(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nationality is required';
    }
    return null;
  }
static String? validateBio(String? value) {
    if (value == null || value.isEmpty) {
      return 'About is required';
    }
    return null;
  }

  // Terms acceptance validation
  static String? validateTermsAcceptance(bool isTermsAccepted) {
    if (!isTermsAccepted) {
      return 'You must accept the Terms and Conditions';
    }
    return null;
  }

  // Comprehensive form validation
  static Map<String, String?> validateSignupForm({
    required String? email,
    required String? password,
    required String? confirmPassword,
    required String? fullName,
    required String? homeCity,
    required DateTime? dateOfBirth,
    required File? profileImage,
    required String? nationality,
    required bool isTermsAccepted,
    required String? bio,
  }) {
    return {
      'email': validateEmail(email),
      'password': validatePassword(password),
      'confirmPassword': validateConfirmPassword(confirmPassword, password ?? ''),
      'fullName': validateFullName(fullName),
      'homeCity': validateHomeCity(homeCity),
      'dateOfBirth': validateDateOfBirth(dateOfBirth),
      'profileImage': validateProfileImage(profileImage),
      'nationality': validateNationality(nationality),
      'terms': validateTermsAcceptance(isTermsAccepted),
      'bio': validateBio(bio),
    };
  }

  // Check if form is valid
  static bool isFormValid(Map<String, String?> validationResults) {
    return validationResults.values.every((error) => error == null);
  }

  // Get first error message
  static String? getFirstErrorMessage(Map<String, String?> validationResults) {
    for (String? error in validationResults.values) {
      if (error != null) {
        return error;
      }
    }
    return null;
  }

  // Get all error messages
  static List<String> getAllErrorMessages(Map<String, String?> validationResults) {
    return validationResults.values
        .where((error) => error != null)
        .cast<String>()
        .toList();
  }
} 