import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../Provider/NetworkProvider.dart';
import '../../Widgets/NetworkStatusWidget.dart';

class NetworkAwareFirestore {
  static final NetworkAwareFirestore _instance = NetworkAwareFirestore._internal();
  factory NetworkAwareFirestore() => _instance;
  NetworkAwareFirestore._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NetworkProvider _networkProvider = NetworkProvider();

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _timeout = Duration(seconds: 10);

  /// Execute a Firestore operation with network awareness and retry logic
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    String? operationName,
    bool requireInternet = true,
    BuildContext? context,
  }) async {
    final String opName = operationName ?? 'Firestore operation';
    
    // Check network connectivity first
    if (requireInternet && !_networkProvider.isOnline) {
      if (context != null) {
        NetworkSnackBar.showNetworkError(
          context,
          'No internet connection. Please check your network and try again.',
        );
      }
      throw NetworkException(
        'No network connection available for $opName',
        NetworkErrorType.noConnection,
      );
    }

    int attempt = 0;
    dynamic lastException;

    while (attempt < _maxRetries) {
      try {
        print('🔄 Executing $opName (attempt ${attempt + 1}/$_maxRetries)');
        
        // Execute operation with timeout
        final T result = await operation().timeout(_timeout);
        
        print('✅ $opName completed successfully');
        return result;
        
      } on FirebaseException catch (e) {
        lastException = e;
        print('❌ Firebase error in $opName: ${e.code} - ${e.message}');
        
        // Check if it's a network-related error
        if (_isNetworkError(e)) {
          if (attempt < _maxRetries - 1) {
            print('🔄 Network error detected, retrying in ${_retryDelay.inSeconds}s...');
            await Future.delayed(_retryDelay);
            attempt++;
            continue;
          } else {
            throw NetworkException(
              'Network error in $opName: ${e.message}',
              NetworkErrorType.firebaseNetworkError,
              originalException: e,
            );
          }
        } else {
          // Non-network Firebase error, don't retry
          throw e;
        }
        
      } on TimeoutException catch (e) {
        lastException = e;
        print('⏰ Timeout in $opName: ${e.message}');
        
        if (attempt < _maxRetries - 1) {
          print('🔄 Timeout detected, retrying in ${_retryDelay.inSeconds}s...');
          await Future.delayed(_retryDelay);
          attempt++;
          continue;
        } else {
          throw NetworkException(
            'Operation timeout for $opName',
            NetworkErrorType.timeout,
            originalException: e,
          );
        }
        
      } catch (e) {
        lastException = e;
        print('❌ Unexpected error in $opName: $e');
        
        if (attempt < _maxRetries - 1) {
          print('🔄 Unexpected error, retrying in ${_retryDelay.inSeconds}s...');
          await Future.delayed(_retryDelay);
          attempt++;
          continue;
        } else {
          throw NetworkException(
            'Unexpected error in $opName: $e',
            NetworkErrorType.unknown,
            originalException: e,
          );
        }
      }
    }

    // If we get here, all retries failed
    if (context != null) {
      NetworkSnackBar.showNetworkError(
        context,
        'Operation failed after multiple attempts. Please check your connection and try again.',
      );
    }
    throw NetworkException(
      'All retry attempts failed for $opName',
      NetworkErrorType.maxRetriesExceeded,
      originalException: lastException,
    );
  }

  /// Check if a Firebase exception is network-related
  bool _isNetworkError(FirebaseException e) {
    const networkErrorCodes = [
      'unavailable',
      'deadline-exceeded',
      'internal',
      'unknown',
      'unauthenticated', // Sometimes network issues cause auth problems
    ];
    
    return networkErrorCodes.contains(e.code.toLowerCase()) ||
           e.message?.toLowerCase().contains('network') == true ||
           e.message?.toLowerCase().contains('connection') == true ||
           e.message?.toLowerCase().contains('timeout') == true ||
           e.message?.toLowerCase().contains('unable to resolve host') == true;
  }

  /// Get a document with retry logic
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    DocumentReference<Map<String, dynamic>> docRef, {
    String? operationName,
    BuildContext? context,
  }) async {
    return executeWithRetry(
      () => docRef.get(),
      operationName: operationName ?? 'Get document ${docRef.path}',
      context: context,
    );
  }

  /// Set a document with retry logic
  Future<void> setDocument(
    DocumentReference<Map<String, dynamic>> docRef,
    Map<String, dynamic> data, {
    SetOptions? options,
    String? operationName,
    BuildContext? context,
  }) async {
    return executeWithRetry(
      () => docRef.set(data, options),
      operationName: operationName ?? 'Set document ${docRef.path}',
      context: context,
    );
  }

  /// Update a document with retry logic
  Future<void> updateDocument(
    DocumentReference<Map<String, dynamic>> docRef,
    Map<String, dynamic> data, {
    String? operationName,
    BuildContext? context,
  }) async {
    return executeWithRetry(
      () => docRef.update(data),
      operationName: operationName ?? 'Update document ${docRef.path}',
      context: context,
    );
  }

  /// Delete a document with retry logic
  Future<void> deleteDocument(
    DocumentReference<Map<String, dynamic>> docRef, {
    String? operationName,
  }) async {
    return executeWithRetry(
      () => docRef.delete(),
      operationName: operationName ?? 'Delete document ${docRef.path}',
    );
  }

  /// Add a document with retry logic
  Future<DocumentReference<Map<String, dynamic>>> addDocument(
    CollectionReference<Map<String, dynamic>> collectionRef,
    Map<String, dynamic> data, {
    String? operationName,
  }) async {
    return executeWithRetry(
      () => collectionRef.add(data),
      operationName: operationName ?? 'Add document to ${collectionRef.path}',
    );
  }

  /// Get a collection with retry logic
  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(
    Query<Map<String, dynamic>> query, {
    String? operationName,
  }) async {
    return executeWithRetry(
      () => query.get(),
      operationName: operationName ?? 'Get collection',
    );
  }

  /// Listen to a document with network awareness
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToDocument(
    DocumentReference<Map<String, dynamic>> docRef, {
    bool includeMetadataChanges = false,
    String? operationName,
  }) {
    return docRef.snapshots(includeMetadataChanges: includeMetadataChanges)
        .handleError((error) {
      print('❌ Error in document stream ${docRef.path}: $error');
      if (_isNetworkError(error as FirebaseException)) {
        throw NetworkException(
          'Network error in document stream: ${error.message}',
          NetworkErrorType.firebaseNetworkError,
          originalException: error,
        );
      }
      throw error;
    });
  }

  /// Listen to a collection with network awareness
  Stream<QuerySnapshot<Map<String, dynamic>>> listenToCollection(
    Query<Map<String, dynamic>> query, {
    bool includeMetadataChanges = false,
    String? operationName,
  }) {
    return query.snapshots(includeMetadataChanges: includeMetadataChanges)
        .handleError((error) {
      print('❌ Error in collection stream: $error');
      if (_isNetworkError(error as FirebaseException)) {
        throw NetworkException(
          'Network error in collection stream: ${error.message}',
          NetworkErrorType.firebaseNetworkError,
          originalException: error,
        );
      }
      throw error;
    });
  }

  /// Batch write with retry logic
  Future<void> batchWrite(
    List<WriteOperation> operations, {
    String? operationName,
  }) async {
    return executeWithRetry(
      () async {
        final WriteBatch batch = _firestore.batch();
        
        for (final operation in operations) {
          switch (operation.type) {
            case WriteOperationType.set:
              batch.set(operation.docRef, operation.data, operation.options);
              break;
            case WriteOperationType.update:
              batch.update(operation.docRef, operation.data);
              break;
            case WriteOperationType.delete:
              batch.delete(operation.docRef);
              break;
          }
        }
        
        await batch.commit();
      },
      operationName: operationName ?? 'Batch write (${operations.length} operations)',
    );
  }
}

/// Network exception class
class NetworkException implements Exception {
  final String message;
  final NetworkErrorType type;
  final dynamic originalException;

  NetworkException(this.message, this.type, {this.originalException});

  @override
  String toString() => 'NetworkException: $message (Type: $type)';
}

/// Network error types
enum NetworkErrorType {
  noConnection,
  firebaseNetworkError,
  timeout,
  maxRetriesExceeded,
  unknown,
}

/// Write operation for batch writes
class WriteOperation {
  final DocumentReference<Map<String, dynamic>> docRef;
  final Map<String, dynamic> data;
  final SetOptions? options;
  final WriteOperationType type;

  WriteOperation.set(this.docRef, this.data, {this.options})
      : type = WriteOperationType.set;

  WriteOperation.update(this.docRef, this.data)
      : type = WriteOperationType.update,
        options = null;

  WriteOperation.delete(this.docRef)
      : type = WriteOperationType.delete,
        data = const {},
        options = null;
}

enum WriteOperationType { set, update, delete }
