import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordProvider extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void setSuccessMessage(String? message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  // Validate email format
  String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }

    // Basic email validation regex
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }


  Future<bool> _checkUserExists(String email) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking user existence: $e');
      return false;
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail() async {
    final String? emailError = validateEmail(emailController.text.trim());
    if (emailError != null) {
      setErrorMessage(emailError);
      return false;
    }
    setLoading(true);
    setErrorMessage(null);
    setSuccessMessage(null);

    try {
      final String email = emailController.text.trim();
      final bool userExists = await _checkUserExists(email);

      if (!userExists) {
        setErrorMessage(
          'No user found with this email address. Please check your email or sign up.',
        );
        setLoading(false);
        return false;
      }

      await _auth.sendPasswordResetEmail(email: email);

      setSuccessMessage(
        'Password reset email sent successfully! Please check your email inbox.',
      );
      setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          setErrorMessage('No user found with this email address.');
          break;
        case 'invalid-email':
          setErrorMessage('Please enter a valid email address.');
          break;
        case 'too-many-requests':
          setErrorMessage('Too many requests. Please try again later.');
          break;
        default:
          setErrorMessage('An error occurred: ${e.message}');
      }
      return false;
    } catch (e) {
      setLoading(false);
      print('❌ Unexpected error: $e');
      setErrorMessage('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  // Check if form is valid
  bool get isFormValid {
    return validateEmail(emailController.text.trim()) == null;
  }

  // Helper method for real-time validation
  String? getEmailError() {
    return validateEmail(emailController.text.trim());
  }

  void clearForm() {
    emailController.clear();
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    emailFocusNode.dispose();
    super.dispose();
  }
}
