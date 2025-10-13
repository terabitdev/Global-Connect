class Validators {
  // Validate email format
  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate signup inputs
  static bool validateSignUpInputs({
    required String name,
    required String email,
    required String password,
    required Function(String) setError,
    required Function(String) showError,
  }) {
    if (name.trim().isEmpty) {
      setError('Name is required');
      showError('Name is required');
      return false;
    }

    if (email.trim().isEmpty) {
      setError('Email is required');
      showError('Email is required');
      return false;
    }

    if (!_isValidEmail(email.trim())) {
      setError('Please enter a valid email');
      showError('Please enter a valid email');
      return false;
    }

    if (password.isEmpty) {
      setError('Password is required');
      showError('Password is required');
      return false;
    }

    if (password.length < 6) {
      setError('Password must be at least 6 characters');
      showError('Password must be at least 6 characters');
      return false;
    }

    return true;
  }

  // Validate signin inputs
  static bool validateSignInInputs({
    required String email,
    required String password,
    required Function(String) setError,
    required Function(String) showError,
  }) {
    if (email.trim().isEmpty) {
      setError('Email is required');
      showError('Email is required');
      return false;
    }

    if (password.isEmpty) {
      setError('Password is required');
      showError('Password is required');
      return false;
    }

    return true;
  }
}