import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Model/ReportModel.dart';

class ReportProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State variables
  String? _selectedReason;
  String _additionalDetails = '';
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _mounted = true;

  // Available report reasons
  final List<String> _reportReasons = [
    'Spam or unwanted content',
    'Harassment or bullying',
    'Inappropriate or offensive content',
    'False or misleading information',
    'Other',
  ];

  // Getters
  String? get selectedReason => _selectedReason;
  String get additionalDetails => _additionalDetails;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get mounted => _mounted;
  List<String> get reportReasons => _reportReasons;

  // Validation
  bool get isValid => _selectedReason != null && _selectedReason!.isNotEmpty;

  // Set selected reason
  void setSelectedReason(String? reason) {
    if (!_mounted) return;
    _selectedReason = reason;
    _clearError();
    notifyListeners();
  }

  // Set additional details
  void setAdditionalDetails(String details) {
    if (!_mounted) return;
    _additionalDetails = details.trim();
    notifyListeners();
  }

  // Clear error message
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      if (_mounted) notifyListeners();
    }
  }

  // Set error message
  void _setError(String message) {
    _errorMessage = message;
    if (_mounted) notifyListeners();
  }

  // Reset form
  void resetForm() {
    if (!_mounted) return;
    _selectedReason = null;
    _additionalDetails = '';
    _errorMessage = null;
    _isSubmitting = false;
    notifyListeners();
  }

  // Submit report
  Future<bool> submitReport({
    required String contentId,
    required String contentOwnerId,
    required ReportContentType contentType,
  }) async {
    if (!_mounted) return false;

    // Validation
    if (!isValid) {
      _setError('Please select a reason for reporting');
      return false;
    }

    try {
      _isSubmitting = true;
      _clearError();
      notifyListeners();

      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('User not authenticated');
        return false;
      }

      // Get current user details
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      String userName = 'Unknown User';
      String userEmail = currentUser.email ?? 'Unknown Email';

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        userName = userData?['fullName'] ?? userData?['name'] ?? 'Unknown User';
        userEmail = userData?['email'] ?? currentUser.email ?? 'Unknown Email';
      }

      // Create report model
      final report = ReportModel(
        reportId: '', // Will be set by Firestore
        contentId: contentId,
        contentOwnerId: contentOwnerId,
        contentType: contentType,
        reportedBy: currentUser.uid,
        reportedByName: userName,
        reportedByEmail: userEmail,
        reason: _selectedReason!,
        additionalDetails: _additionalDetails,
        timestamp: DateTime.now(),
        status: 'pending',
      );

      // Save to Firestore
      await _firestore
          .collection('reports')
          .add(report.toFirestore());

      // Reset form after successful submission
      resetForm();

      return true;
    } catch (e) {
      _setError('Failed to submit report: ${e.toString()}');
      return false;
    } finally {
      if (_mounted) {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  // Get reports for admin (optional - for future admin panel)
  Future<List<ReportModel>> getReports({
    String? status,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching reports: $e');
      return [];
    }
  }

  // Update report status (for admin use)
  Future<bool> updateReportStatus({
    required String reportId,
    required String status,
    String? adminNotes,
    String? reviewedBy,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
      };

      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
      }

      if (reviewedBy != null) {
        updateData['reviewedBy'] = reviewedBy;
      }

      await _firestore
          .collection('reports')
          .doc(reportId)
          .update(updateData);

      return true;
    } catch (e) {
      print('Error updating report status: $e');
      return false;
    }
  }

  // Check if user has already reported this content
  Future<bool> hasUserReportedContent({
    required String contentId,
    required String userId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('contentId', isEqualTo: contentId)
          .where('reportedBy', isEqualTo: userId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking existing report: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }
}