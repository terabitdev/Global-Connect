import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../Model/restaurants_model.dart';
import '../Model/userModel.dart';
import '../core/services/firebase_services.dart';
import '../core/const/app_images.dart';

class UserTipsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _allTips = [];
  List<Map<String, dynamic>> _filteredTips = [];
  List<Map<String, dynamic>> _currentUserTips = [];
  List<RestaurantsModel> _allRestaurants = [];
  bool _isLoading = true;
  bool _isRestaurantsLoading = true;
  String? _error;
  String? _restaurantsError;
  String? _currentUserNationality;
  String _selectedCategory = 'All Categories';
  bool _showGlobalTips = false; // false = Countrymen, true = Global
  String _sortBy = 'Recent'; // 'Recent' or 'Popular'
  final Map<String, bool> _expandedTips = {}; // Track expansion state by tipId
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Map<String, Map<String, dynamic>> _userDataCache = {}; // Cache user data for search
  bool? _originalGlobalTipsPreference; // Store user's original preference before auto-adjustment

  StreamSubscription<List<Map<String, dynamic>>>? _allTipsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _userTipsSubscription;
  StreamSubscription<List<RestaurantsModel>>? _restaurantsSubscription;
  StreamSubscription<UserModel?>? _currentUserSubscription;

  // Getters
  List<Map<String, dynamic>> get allTips => _filteredTips;
  List<Map<String, dynamic>> get currentUserTips => _currentUserTips;
  List<RestaurantsModel> get allRestaurants => _allRestaurants;
  bool get isLoading => _isLoading;
  bool get isRestaurantsLoading => _isRestaurantsLoading;
  String? get error => _error;
  String? get restaurantsError => _restaurantsError;
  String get selectedCategory => _selectedCategory;
  bool get showGlobalTips => _showGlobalTips;
  String get sortBy => _sortBy;
  String get searchQuery => _searchQuery;
  TextEditingController get searchController => _searchController;

  /// Check if a specific tip is expanded
  bool isExpanded(String tipId) {
    return _expandedTips[tipId] ?? false;
  }

  /// Toggle expansion state for a specific tip
  void toggleExpansion(String tipId) {
    _expandedTips[tipId] = !(_expandedTips[tipId] ?? false);
    notifyListeners();
  }

  /// Set expansion state for a specific tip
  void setExpansion(String tipId, bool isExpanded) {
    _expandedTips[tipId] = isExpanded;
    notifyListeners();
  }

  UserTipsProvider() {
    _initializeStreams();
  }

  void _initializeStreams() {
    _listenToCurrentUser();
    _listenToAllTips();
    _listenToCurrentUserTips();
    _listenToAllRestaurants();
  }

  void _listenToCurrentUser() {
    _currentUserSubscription = FirebaseServices.instance.getCurrentUserStream().listen(
      (user) {
        if (user != null) {
          _currentUserNationality = user.nationality;
          _filterTipsByNationality();
          notifyListeners();
        }
      },
      onError: (error) {
        print('Error in current user stream: $error');
      },
    );
  }

  void _listenToAllTips() {
    _allTipsSubscription = FirebaseServices.getAllTipsStream().listen(
          (tips) {
        _allTips = tips;
        _cacheUserDataFromTips();
        _filterTipsByNationality();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load tips: ${error.toString()}';
        _isLoading = false;
        notifyListeners();
        print('Error in all tips stream: $error');
      },
    );
  }

  void _filterTipsByNationality() {
    List<Map<String, dynamic>> nationalityFilteredTips;

    if (_showGlobalTips) {
      // Show all tips regardless of nationality
      nationalityFilteredTips = _allTips;
    } else {
      // Show only tips from users with same nationality as current user
      if (_currentUserNationality == null || _currentUserNationality!.trim().isEmpty) {
        _filteredTips = [];
        return;
      }

      nationalityFilteredTips = _allTips.where((tip) {
        final tipUserNationality = tip['userNationality'] as String?;
        
        if (tipUserNationality == null || tipUserNationality.trim().isEmpty) {
          return false;
        }
        
        return tipUserNationality.trim().toLowerCase() == _currentUserNationality!.trim().toLowerCase();
      }).toList();
    }

    // Then filter by category if a specific category is selected
    List<Map<String, dynamic>> categoryFilteredTips;
    if (_selectedCategory == 'All Categories') {
      categoryFilteredTips = nationalityFilteredTips;
    } else {
      categoryFilteredTips = nationalityFilteredTips.where((tip) {
        final tipCategory = tip['category'] as String?;
        return tipCategory != null && tipCategory.trim().toLowerCase() == _selectedCategory.trim().toLowerCase();
      }).toList();
    }

    // Finally, apply search filter if search query exists
    if (_searchQuery.isNotEmpty) {
      _filteredTips = categoryFilteredTips.where((tip) {
        final searchLower = _searchQuery.toLowerCase();
        
        // Search in tip content
        final tipContent = tip['tip'] as String? ?? '';
        final tipTitle = tip['title'] as String? ?? '';
        final tipCategory = tip['category'] as String? ?? '';
        
        bool matchesContent = tipContent.toLowerCase().contains(searchLower) ||
               tipTitle.toLowerCase().contains(searchLower) ||
               tipCategory.toLowerCase().contains(searchLower);
        
        // Search in user information
        final userName = tip['userName'] as String? ?? '';
        final userNationality = tip['userNationality'] as String? ?? '';
        final userHomeCity = tip['userHomeCity'] as String? ?? '';
        
        // Search in location information
        final address = tip['address'] as String? ?? '';
        
        bool matchesUserData = userName.toLowerCase().contains(searchLower) ||
               userNationality.toLowerCase().contains(searchLower) ||
               userHomeCity.toLowerCase().contains(searchLower) ||
               address.toLowerCase().contains(searchLower);
        
        return matchesContent || matchesUserData;
      }).toList();
    } else {
      _filteredTips = categoryFilteredTips;
    }

    // Finally, sort the filtered tips
    _sortTips();
  }

  void _listenToCurrentUserTips() {
    _userTipsSubscription = FirebaseServices.getCurrentUserTipsStream().listen(
          (tips) {
        _currentUserTips = tips;
        notifyListeners();
      },
      onError: (error) {
        print('Error in user tips stream: $error');
      },
    );
  }

  void _listenToAllRestaurants() {
    _restaurantsSubscription = FirebaseServices.getAllRestaurantsStream().listen(
          (restaurants) {
        _allRestaurants = restaurants;
        _isRestaurantsLoading = false;
        _restaurantsError = null;
        notifyListeners();
      },
      onError: (error) {
        _restaurantsError = 'Failed to load restaurants: ${error.toString()}';
        _isRestaurantsLoading = false;
        notifyListeners();
        print('Error in restaurants stream: $error');
      },
    );
  }

  /// Refresh data manually
  void refresh() {
    _isLoading = true;
    _isRestaurantsLoading = true;
    _error = null;
    _restaurantsError = null;
    notifyListeners();
    
    // Re-initialize streams to force refresh
    _allTipsSubscription?.cancel();
    _userTipsSubscription?.cancel();
    _restaurantsSubscription?.cancel();
    _currentUserSubscription?.cancel();
    _initializeStreams();
  }

  /// Get featured restaurants only
  List<RestaurantsModel> get featuredRestaurants {
    return _allRestaurants.where((restaurant) => restaurant.featuredRestaurant).toList();
  }

  /// Get restaurants by city
  List<RestaurantsModel> getRestaurantsByCity(String city) {
    return _allRestaurants.where((restaurant) =>
        restaurant.city.toLowerCase().contains(city.toLowerCase())).toList();
  }

  /// Get restaurants by cuisine type
  List<RestaurantsModel> getRestaurantsByCuisine(String cuisineType) {
    return _allRestaurants.where((restaurant) =>
        restaurant.cuisineType.toLowerCase().contains(cuisineType.toLowerCase())).toList();
  }

  /// Convert tip data to display format
  Map<String, dynamic> formatTipForDisplay(Map<String, dynamic> tipData) {
    // Use the user data that's already fetched in the stream
    final userImage = tipData['userImage'] ?? '';
    final userName = tipData['userName'] ?? 'Anonymous';
    final countryFlag = tipData['userCountryFlag'] ?? '🌍';
    final homeCity = tipData['userHomeCity'] ?? '';
    final userNationality = tipData['nationality'] ?? '';

    // Create location string - prioritize restaurant name, then address, then user's home city
    String location = '';
    if (tipData['restaurantName'] != null && tipData['restaurantName'].toString().isNotEmpty) {
      location = tipData['restaurantName'];
    } else if (tipData['address'] != null && tipData['address'].toString().isNotEmpty) {
      location = tipData['address'];
    } else if (homeCity.isNotEmpty) {
      location = homeCity;
    }
    else if (userNationality.isNotEmpty) {
      location = userNationality;
    }
    else {
      location = 'Unknown location';
    }

    return {
      'id': tipData['id'] ?? '',
      'userName': userName,
      'userImage': userImage.isNotEmpty ? userImage : AppImages.profileImage,
      'countryFlag': countryFlag,
      'timeAgo': _formatTimeAgo(tipData['createdAt']),
      'title': tipData['title'] ?? '',
      'description': tipData['tip'] ?? '',
      'location': location,
      'likesCount': tipData['likeCount'] ?? 0,
      'dislikesCount': tipData['dislikeCount'] ?? 0,
      'category': tipData['category'] ?? '',
      'countrymenOnly': tipData['countrymenOnly'] ?? false,
      'userId': tipData['userId'] ?? '',
      'userHomeCity': homeCity,
      'userNationality': tipData['userNationality'] ?? '',
    };
  }

  String _formatTimeAgo(dynamic createdAt) {
    try {
      DateTime dateTime;
      if (createdAt is Timestamp) {
        dateTime = createdAt.toDate();
      } else if (createdAt is String) {
        dateTime = DateTime.parse(createdAt);
      } else {
        return 'Unknown time';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return 'about $years year${years > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return 'about $months month${months > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  /// Filter tips by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    _filterTipsByNationality(); // Re-apply all filters
    notifyListeners();
  }

  /// Reset category filter
  void resetCategoryFilter() {
    _selectedCategory = 'All Categories';
    _filterTipsByNationality(); // Re-apply all filters
    notifyListeners();
  }

  /// Set nationality filter (true = Global, false = Countrymen)
  void setNationalityFilter(bool showGlobal) {
    _showGlobalTips = showGlobal;
    // Reset auto-adjustment tracking when user manually changes
    _originalGlobalTipsPreference = null;
    _filterTipsByNationality(); // Re-apply all filters
    notifyListeners();
  }

  /// Toggle between Global and Countrymen
  void toggleNationalityFilter() {
    _showGlobalTips = !_showGlobalTips;
    // Reset auto-adjustment tracking when user manually changes
    _originalGlobalTipsPreference = null;
    _filterTipsByNationality(); // Re-apply all filters
    notifyListeners();
  }

  /// Sort filtered tips based on selected sort type
  void _sortTips() {
    if (_sortBy == 'Popular') {
      // Sort by like count (highest first)
      _filteredTips.sort((a, b) {
        final aLikes = a['likeCount'] as int? ?? 0;
        final bLikes = b['likeCount'] as int? ?? 0;
        return bLikes.compareTo(aLikes); // Descending order
      });
    } else {
      // Sort by creation date (newest first)
      _filteredTips.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime); // Descending order (newest first)
        }
        return 0;
      });
    }
  }

  /// Set sorting type ('Recent' or 'Popular')
  void setSortBy(String sortType) {
    _sortBy = sortType;
    _sortTips(); // Re-sort current filtered tips
    notifyListeners();
  }

  /// Cache user data from tips for efficient search
  void _cacheUserDataFromTips() {
    for (var tip in _allTips) {
      final userId = tip['userId'] as String?;
      final userName = tip['userName'] as String?;
      final userImage = tip['userImage'] as String?;
      
      if (userId != null && !_userDataCache.containsKey(userId)) {
        _userDataCache[userId] = {
          'fullName': userName ?? '',
          'profileImageUrl': userImage ?? '',
        };
      }
    }
  }

  /// Set search query and apply filter
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    _filterTipsByNationality(); // Re-apply all filters including search
  }

  /// Handle search changes with auto nationality detection
  void onSearchChanged(String value) {
    // Trim spaces from the search value
    final trimmedValue = value.trim();
    
    if (trimmedValue.isNotEmpty) {
      // Store original preference before auto-adjustment (only once)
      _originalGlobalTipsPreference ??= _showGlobalTips;
      
      // When user searches by name, auto-detect if we need to switch to Global
      // This will also apply the filter immediately
      _searchQuery = trimmedValue; // Set trimmed search query first
      _autoAdjustNationalityForSearch(trimmedValue);
      _filterTipsByNationality(); // Apply filter immediately after auto-adjust
      notifyListeners(); // Ensure UI updates
    } else {
      // When search is cleared, restore original preference
      _restoreOriginalNationalityPreference();
      setSearchQuery('');
    }
  }

  /// Auto-adjust Global/Countrymen based on search results
  void _autoAdjustNationalityForSearch(String searchQuery) {
    final searchLower = searchQuery.toLowerCase();
    
    // Check if search query matches any user names or content
    bool foundInCountrymen = false;
    bool foundInGlobal = false;
    
    for (var tip in _allTips) {
      final userName = tip['userName'] as String? ?? '';
      final tipContent = tip['tip'] as String? ?? '';
      final tipTitle = tip['title'] as String? ?? '';
      final tipCategory = tip['category'] as String? ?? '';
      final tipUserNationality = tip['userNationality'] as String?;
      final userHomeCity = tip['userHomeCity'] as String? ?? '';
      final address = tip['address'] as String? ?? '';
      
      // Check if search matches any searchable field
      bool matches = userName.toLowerCase().contains(searchLower) ||
                    tipTitle.toLowerCase().contains(searchLower) ||
                    tipContent.toLowerCase().contains(searchLower) ||
                    tipCategory.toLowerCase().contains(searchLower) ||
                    (tipUserNationality?.toLowerCase().contains(searchLower) ?? false) ||
                    userHomeCity.toLowerCase().contains(searchLower) ||
                    address.toLowerCase().contains(searchLower);
      
      if (matches) {
        // Check if this tip is from same nationality as current user
        if (_currentUserNationality != null && 
            tipUserNationality != null &&
            tipUserNationality.trim().toLowerCase() == _currentUserNationality!.trim().toLowerCase()) {
          foundInCountrymen = true;
        } else {
          foundInGlobal = true;
        }
        
        // If found in both, no need to continue checking
        if (foundInCountrymen && foundInGlobal) break;
      }
    }
    
    // Auto-adjust nationality filter based on where search results are found
    // Priority: If found only in one section, switch to that. If in both, show Global for all results
    if (foundInCountrymen && !foundInGlobal) {
      // Found only in countrymen, switch to Countrymen
      if (_showGlobalTips != false) {
        _showGlobalTips = false;
        print('🔄 Auto-switched to Countrymen for search: "$searchQuery"');
      }
    } else if (!foundInCountrymen && foundInGlobal) {
      // Found only in global, switch to Global
      if (_showGlobalTips != true) {
        _showGlobalTips = true;
        print('🔄 Auto-switched to Global for search: "$searchQuery"');
      }
    } else if (foundInCountrymen && foundInGlobal) {
      // Found in both, prefer Global to show all results
      if (_showGlobalTips != true) {
        _showGlobalTips = true;
        print('🔄 Auto-switched to Global to show all search results: "$searchQuery"');
      }
    }
    // If no matches found in either, keep current setting
  }

  /// Restore original nationality preference
  void _restoreOriginalNationalityPreference() {
    if (_originalGlobalTipsPreference != null) {
      _showGlobalTips = _originalGlobalTipsPreference!;
      _originalGlobalTipsPreference = null; // Reset for next search session
      print('🔄 Restored original nationality preference');
    }
  }

  /// Clear search
  void clearSearch() {
    _restoreOriginalNationalityPreference();
    _searchController.clear();
    setSearchQuery('');
  }

  @override
  void dispose() {
    _allTipsSubscription?.cancel();
    _userTipsSubscription?.cancel();
    _restaurantsSubscription?.cancel();
    _currentUserSubscription?.cancel();
    _searchController.dispose();
    _userDataCache.clear();
    super.dispose();
  }

  /// Update tip reactions locally (for optimistic updates)
  void updateTipReactions({
    required String tipId,
    required List<String> likeMembers,
    required List<String> dislikeMembers,
  }) {
    // Update in _allTips
    final allTipsIndex = _allTips.indexWhere((tip) => tip['id'] == tipId);
    if (allTipsIndex != -1) {
      _allTips[allTipsIndex] = {
        ..._allTips[allTipsIndex],
        'likeMembers': likeMembers,
        'dislikeMembers': dislikeMembers,
        'likeCount': likeMembers.length,
        'dislikeCount': dislikeMembers.length,
      };
    }

    // Update in _filteredTips
    final filteredTipsIndex = _filteredTips.indexWhere((tip) => tip['id'] == tipId);
    if (filteredTipsIndex != -1) {
      _filteredTips[filteredTipsIndex] = {
        ..._filteredTips[filteredTipsIndex],
        'likeMembers': likeMembers,
        'dislikeMembers': dislikeMembers,
        'likeCount': likeMembers.length,
        'dislikeCount': dislikeMembers.length,
      };
    }

    // Update in _currentUserTips
    final currentUserTipsIndex = _currentUserTips.indexWhere((tip) => tip['id'] == tipId);
    if (currentUserTipsIndex != -1) {
      _currentUserTips[currentUserTipsIndex] = {
        ..._currentUserTips[currentUserTipsIndex],
        'likeMembers': likeMembers,
        'dislikeMembers': dislikeMembers,
        'likeCount': likeMembers.length,
        'dislikeCount': dislikeMembers.length,
      };
    }

    notifyListeners();
  }
}