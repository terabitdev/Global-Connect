import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/utils/validation/login_validation.dart';
import 'SignupProvider.dart';

class LoginProvider extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  // Getters
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  String? get errorMessage => _errorMessage;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setGoogleLoading(bool loading) {
    _isGoogleLoading = loading;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Login method
  Future<Map<String, dynamic>> signIn() async {
    // Validate all fields using the validation class
    final Map<String, String?> validationResults = LoginValidation.validateLoginForm(
      email: emailController.text,
      password: passwordController.text,
    );

    if (!LoginValidation.isFormValid(validationResults)) {
      final String? firstError = LoginValidation.getFirstErrorMessage(validationResults);
      setErrorMessage(firstError ?? 'Please fill all required fields correctly');
      return {'success': false, 'profileComplete': false};
    }

    setLoading(true);
    setErrorMessage(null);

    try {
      // Sign in with email and password
      print('Signing in with Firebase Auth...');
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final User? user = userCredential.user;
      if (user != null) {
        print('✅ User signed in successfully: ${user.email}');
        await _generateAndSaveFCMToken(user.uid);
        
        // Check if profile is complete
        final signupProvider = SignupProvider();
        final profileComplete = await signupProvider.isProfileComplete();
        
        setLoading(false);
        return {
          'success': true,
          'profileComplete': profileComplete
        };
      } else {
        setErrorMessage('Failed to sign in');
        setLoading(false);
        return {'success': false, 'profileComplete': false};
      }
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          setErrorMessage('No user found for that email address.');
          break;
        case 'wrong-password':
          setErrorMessage('Wrong password provided.');
          break;
        case 'invalid-email':
          setErrorMessage('Please enter a valid email address.');
          break;
        case 'user-disabled':
          setErrorMessage('This account has been disabled.');
          break;
        case 'too-many-requests':
          setErrorMessage('Too many failed attempts. Please try again later.');
          break;
        default:
          setErrorMessage('An error occurred: ${e.message}');
      }
      return {'success': false, 'profileComplete': false};
    } catch (e) {
      setLoading(false);
      print('❌ Unexpected error: $e');
      setErrorMessage('An unexpected error occurred: $e');
      return {'success': false, 'profileComplete': false};
    }
  }

  Future<void> _generateAndSaveFCMToken(String userId) async {
    try {
      // FCM token get karo
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      final String? fcmToken = await messaging.getToken();

      if (fcmToken != null) {
        print('✅ FCM Token generated: $fcmToken');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': fcmToken,
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        print('✅ FCM Token saved to Firestore for user: $userId');
      } else {
        print('❌ Failed to generate FCM token');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }


  //login with google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    setGoogleLoading(true);
    setErrorMessage(null);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setGoogleLoading(false);
        return {'success': false, 'profileComplete': false};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        print('✅ User signed in with Google successfully: ${user.email}');
        
        final signupProvider = SignupProvider();
        final userCreated = await signupProvider.createUserFromGoogleSignIn(user);
        
        if (userCreated) {
          await _generateAndSaveFCMToken(user.uid);
          
          // Check if profile is complete
          final profileComplete = await signupProvider.isProfileComplete();
          
          setGoogleLoading(false);
          return {
            'success': true,
            'profileComplete': profileComplete
          };
        } else {
          setErrorMessage('Failed to create user profile');
          setGoogleLoading(false);
          return {'success': false, 'profileComplete': false};
        }
      } else {
        setErrorMessage('Failed to sign in with Google');
        setGoogleLoading(false);
        return {'success': false, 'profileComplete': false};
      }
    } catch (e) {
      setGoogleLoading(false);
      print('❌ Error signing in with Google: $e');
      setErrorMessage('Google sign-in failed: ${e.toString()}');
      return {'success': false, 'profileComplete': false};
    }
  }


  // Check if form is valid
  bool get isFormValid {
    final Map<String, String?> validationResults = LoginValidation.validateLoginForm(
      email: emailController.text,
      password: passwordController.text,
    );
    return LoginValidation.isFormValid(validationResults);
  }

  // Helper methods for real-time validation
  String? getEmailError() {
    return LoginValidation.validateEmail(emailController.text);
  }

  String? getPasswordError() {
    return LoginValidation.validatePassword(passwordController.text);
  }



  void clearForm() {
    emailController.clear();
    passwordController.clear();
    _isPasswordVisible = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }
} 