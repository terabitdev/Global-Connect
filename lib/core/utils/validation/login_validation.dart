class LoginValidation {
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
    return null;
  }

  // Comprehensive form validation
  static Map<String, String?> validateLoginForm({
    required String? email,
    required String? password,
  }) {
    return {
      'email': validateEmail(email),
      'password': validatePassword(password),
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