import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddCountriesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController searchController = TextEditingController();

  // Search toggle state
  bool _isSearchVisible = true;
  bool get isSearchVisible => _isSearchVisible;

  // Selected continent filter
  String _selectedContinent = 'All';
  String get selectedContinent => _selectedContinent;

  // Search text
  String _searchText = '';
  String get searchText => _searchText;

  // All countries data
  List<Map<String, String>> _allCountries = [];
  List<Map<String, String>> get allCountries => _allCountries;

  // Filtered countries based on search and continent
  List<Map<String, String>> _filteredCountries = [];
  List<Map<String, String>> get filteredCountries => _filteredCountries;

  // Added countries by user (stored in Firebase)
  List<Map<String, dynamic>> _addedCountries = [];
  List<Map<String, dynamic>> get addedCountries => _addedCountries;

  // Loading states
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  bool _isAddingCountry = false;
  bool get isAddingCountry => _isAddingCountry;

  Set<String> _currentlyAddingCountries = {};
  Set<String> _currentlyRemovingCountries = {};

  // Available continents
  final List<String> continents = [
    'All',
    'Africa',
    'Asia',
    'Europe',
    'North America',
    'Oceania',
    'South America',
  ];

  // Complete list of all countries organized by continent
  static const Map<String, List<Map<String, String>>> _countriesByContinent = {
    'Africa': [
      {'name': 'Algeria', 'flag': '🇩🇿', 'code': 'DZ'},
      {'name': 'Angola', 'flag': '🇦🇴', 'code': 'AO'},
      {'name': 'Benin', 'flag': '🇧🇯', 'code': 'BJ'},
      {'name': 'Botswana', 'flag': '🇧🇼', 'code': 'BW'},
      {'name': 'Burkina Faso', 'flag': '🇧🇫', 'code': 'BF'},
      {'name': 'Burundi', 'flag': '🇧🇮', 'code': 'BI'},
      {'name': 'Cameroon', 'flag': '🇨🇲', 'code': 'CM'},
      {'name': 'Cape Verde', 'flag': '🇨🇻', 'code': 'CV'},
      {'name': 'Central African Republic', 'flag': '🇨🇫', 'code': 'CF'},
      {'name': 'Chad', 'flag': '🇹🇩', 'code': 'TD'},
      {'name': 'Comoros', 'flag': '🇰🇲', 'code': 'KM'},
      {'name': 'Congo', 'flag': '🇨🇬', 'code': 'CG'},
      {'name': 'Democratic Republic of Congo', 'flag': '🇨🇩', 'code': 'CD'},
      {'name': 'Djibouti', 'flag': '🇩🇯', 'code': 'DJ'},
      {'name': 'Egypt', 'flag': '🇪🇬', 'code': 'EG'},
      {'name': 'Equatorial Guinea', 'flag': '🇬🇶', 'code': 'GQ'},
      {'name': 'Eritrea', 'flag': '🇪🇷', 'code': 'ER'},
      {'name': 'Eswatini', 'flag': '🇸🇿', 'code': 'SZ'},
      {'name': 'Ethiopia', 'flag': '🇪🇹', 'code': 'ET'},
      {'name': 'Gabon', 'flag': '🇬🇦', 'code': 'GA'},
      {'name': 'Gambia', 'flag': '🇬🇲', 'code': 'GM'},
      {'name': 'Ghana', 'flag': '🇬🇭', 'code': 'GH'},
      {'name': 'Guinea', 'flag': '🇬🇳', 'code': 'GN'},
      {'name': 'Guinea-Bissau', 'flag': '🇬🇼', 'code': 'GW'},
      {'name': 'Ivory Coast', 'flag': '🇨🇮', 'code': 'CI'},
      {'name': 'Kenya', 'flag': '🇰🇪', 'code': 'KE'},
      {'name': 'Lesotho', 'flag': '🇱🇸', 'code': 'LS'},
      {'name': 'Liberia', 'flag': '🇱🇷', 'code': 'LR'},
      {'name': 'Libya', 'flag': '🇱🇾', 'code': 'LY'},
      {'name': 'Madagascar', 'flag': '🇲🇬', 'code': 'MG'},
      {'name': 'Malawi', 'flag': '🇲🇼', 'code': 'MW'},
      {'name': 'Mali', 'flag': '🇲🇱', 'code': 'ML'},
      {'name': 'Mauritania', 'flag': '🇲🇷', 'code': 'MR'},
      {'name': 'Mauritius', 'flag': '🇲🇺', 'code': 'MU'},
      {'name': 'Morocco', 'flag': '🇲🇦', 'code': 'MA'},
      {'name': 'Mozambique', 'flag': '🇲🇿', 'code': 'MZ'},
      {'name': 'Namibia', 'flag': '🇳🇦', 'code': 'NA'},
      {'name': 'Niger', 'flag': '🇳🇪', 'code': 'NE'},
      {'name': 'Nigeria', 'flag': '🇳🇬', 'code': 'NG'},
      {'name': 'Rwanda', 'flag': '🇷🇼', 'code': 'RW'},
      {'name': 'Sao Tome and Principe', 'flag': '🇸🇹', 'code': 'ST'},
      {'name': 'Senegal', 'flag': '🇸🇳', 'code': 'SN'},
      {'name': 'Seychelles', 'flag': '🇸🇨', 'code': 'SC'},
      {'name': 'Sierra Leone', 'flag': '🇸🇱', 'code': 'SL'},
      {'name': 'Somalia', 'flag': '🇸🇴', 'code': 'SO'},
      {'name': 'South Africa', 'flag': '🇿🇦', 'code': 'ZA'},
      {'name': 'South Sudan', 'flag': '🇸🇸', 'code': 'SS'},
      {'name': 'Sudan', 'flag': '🇸🇩', 'code': 'SD'},
      {'name': 'Tanzania', 'flag': '🇹🇿', 'code': 'TZ'},
      {'name': 'Togo', 'flag': '🇹🇬', 'code': 'TG'},
      {'name': 'Tunisia', 'flag': '🇹🇳', 'code': 'TN'},
      {'name': 'Uganda', 'flag': '🇺🇬', 'code': 'UG'},
      {'name': 'Zambia', 'flag': '🇿🇲', 'code': 'ZM'},
      {'name': 'Zimbabwe', 'flag': '🇿🇼', 'code': 'ZW'},
    ],
    'Asia': [
      {'name': 'Afghanistan', 'flag': '🇦🇫', 'code': 'AF'},
      {'name': 'Armenia', 'flag': '🇦🇲', 'code': 'AM'},
      {'name': 'Azerbaijan', 'flag': '🇦🇿', 'code': 'AZ'},
      {'name': 'Bahrain', 'flag': '🇧🇭', 'code': 'BH'},
      {'name': 'Bangladesh', 'flag': '🇧🇩', 'code': 'BD'},
      {'name': 'Bhutan', 'flag': '🇧🇹', 'code': 'BT'},
      {'name': 'Brunei', 'flag': '🇧🇳', 'code': 'BN'},
      {'name': 'Cambodia', 'flag': '🇰🇭', 'code': 'KH'},
      {'name': 'China', 'flag': '🇨🇳', 'code': 'CN'},
      {'name': 'Georgia', 'flag': '🇬🇪', 'code': 'GE'},
      {'name': 'India', 'flag': '🇮🇳', 'code': 'IN'},
      {'name': 'Indonesia', 'flag': '🇮🇩', 'code': 'ID'},
      {'name': 'Iran', 'flag': '🇮🇷', 'code': 'IR'},
      {'name': 'Iraq', 'flag': '🇮🇶', 'code': 'IQ'},
      {'name': 'Israel', 'flag': '🇮🇱', 'code': 'IL'},
      {'name': 'Japan', 'flag': '🇯🇵', 'code': 'JP'},
      {'name': 'Jordan', 'flag': '🇯🇴', 'code': 'JO'},
      {'name': 'Kazakhstan', 'flag': '🇰🇿', 'code': 'KZ'},
      {'name': 'Kuwait', 'flag': '🇰🇼', 'code': 'KW'},
      {'name': 'Kyrgyzstan', 'flag': '🇰🇬', 'code': 'KG'},
      {'name': 'Laos', 'flag': '🇱🇦', 'code': 'LA'},
      {'name': 'Lebanon', 'flag': '🇱🇧', 'code': 'LB'},
      {'name': 'Malaysia', 'flag': '🇲🇾', 'code': 'MY'},
      {'name': 'Maldives', 'flag': '🇲🇻', 'code': 'MV'},
      {'name': 'Mongolia', 'flag': '🇲🇳', 'code': 'MN'},
      {'name': 'Myanmar', 'flag': '🇲🇲', 'code': 'MM'},
      {'name': 'Nepal', 'flag': '🇳🇵', 'code': 'NP'},
      {'name': 'North Korea', 'flag': '🇰🇵', 'code': 'KP'},
      {'name': 'Oman', 'flag': '🇴🇲', 'code': 'OM'},
      {'name': 'Pakistan', 'flag': '🇵🇰', 'code': 'PK'},
      {'name': 'Palestine', 'flag': '🇵🇸', 'code': 'PS'},
      {'name': 'Philippines', 'flag': '🇵🇭', 'code': 'PH'},
      {'name': 'Qatar', 'flag': '🇶🇦', 'code': 'QA'},
      {'name': 'Saudi Arabia', 'flag': '🇸🇦', 'code': 'SA'},
      {'name': 'Singapore', 'flag': '🇸🇬', 'code': 'SG'},
      {'name': 'South Korea', 'flag': '🇰🇷', 'code': 'KR'},
      {'name': 'Sri Lanka', 'flag': '🇱🇰', 'code': 'LK'},
      {'name': 'Syria', 'flag': '🇸🇾', 'code': 'SY'},
      {'name': 'Taiwan', 'flag': '🇹🇼', 'code': 'TW'},
      {'name': 'Tajikistan', 'flag': '🇹🇯', 'code': 'TJ'},
      {'name': 'Thailand', 'flag': '🇹🇭', 'code': 'TH'},
      {'name': 'Timor-Leste', 'flag': '🇹🇱', 'code': 'TL'},
      {'name': 'Turkey', 'flag': '🇹🇷', 'code': 'TR'},
      {'name': 'Turkmenistan', 'flag': '🇹🇲', 'code': 'TM'},
      {'name': 'United Arab Emirates', 'flag': '🇦🇪', 'code': 'AE'},
      {'name': 'Uzbekistan', 'flag': '🇺🇿', 'code': 'UZ'},
      {'name': 'Vietnam', 'flag': '🇻🇳', 'code': 'VN'},
      {'name': 'Yemen', 'flag': '🇾🇪', 'code': 'YE'},
    ],
    'Europe': [
      {'name': 'Albania', 'flag': '🇦🇱', 'code': 'AL'},
      {'name': 'Andorra', 'flag': '🇦🇩', 'code': 'AD'},
      {'name': 'Austria', 'flag': '🇦🇹', 'code': 'AT'},
      {'name': 'Belarus', 'flag': '🇧🇾', 'code': 'BY'},
      {'name': 'Belgium', 'flag': '🇧🇪', 'code': 'BE'},
      {'name': 'Bosnia and Herzegovina', 'flag': '🇧🇦', 'code': 'BA'},
      {'name': 'Bulgaria', 'flag': '🇧🇬', 'code': 'BG'},
      {'name': 'Croatia', 'flag': '🇭🇷', 'code': 'HR'},
      {'name': 'Cyprus', 'flag': '🇨🇾', 'code': 'CY'},
      {'name': 'Czech Republic', 'flag': '🇨🇿', 'code': 'CZ'},
      {'name': 'Denmark', 'flag': '🇩🇰', 'code': 'DK'},
      {'name': 'Estonia', 'flag': '🇪🇪', 'code': 'EE'},
      {'name': 'Finland', 'flag': '🇫🇮', 'code': 'FI'},
      {'name': 'France', 'flag': '🇫🇷', 'code': 'FR'},
      {'name': 'Germany', 'flag': '🇩🇪', 'code': 'DE'},
      {'name': 'Greece', 'flag': '🇬🇷', 'code': 'GR'},
      {'name': 'Hungary', 'flag': '🇭🇺', 'code': 'HU'},
      {'name': 'Iceland', 'flag': '🇮🇸', 'code': 'IS'},
      {'name': 'Ireland', 'flag': '🇮🇪', 'code': 'IE'},
      {'name': 'Italy', 'flag': '🇮🇹', 'code': 'IT'},
      {'name': 'Kosovo', 'flag': '🇽🇰', 'code': 'XK'},
      {'name': 'Latvia', 'flag': '🇱🇻', 'code': 'LV'},
      {'name': 'Liechtenstein', 'flag': '🇱🇮', 'code': 'LI'},
      {'name': 'Lithuania', 'flag': '🇱🇹', 'code': 'LT'},
      {'name': 'Luxembourg', 'flag': '🇱🇺', 'code': 'LU'},
      {'name': 'Malta', 'flag': '🇲🇹', 'code': 'MT'},
      {'name': 'Moldova', 'flag': '🇲🇩', 'code': 'MD'},
      {'name': 'Monaco', 'flag': '🇲🇨', 'code': 'MC'},
      {'name': 'Montenegro', 'flag': '🇲🇪', 'code': 'ME'},
      {'name': 'Netherlands', 'flag': '🇳🇱', 'code': 'NL'},
      {'name': 'North Macedonia', 'flag': '🇲🇰', 'code': 'MK'},
      {'name': 'Norway', 'flag': '🇳🇴', 'code': 'NO'},
      {'name': 'Poland', 'flag': '🇵🇱', 'code': 'PL'},
      {'name': 'Portugal', 'flag': '🇵🇹', 'code': 'PT'},
      {'name': 'Romania', 'flag': '🇷🇴', 'code': 'RO'},
      {'name': 'Russia', 'flag': '🇷🇺', 'code': 'RU'},
      {'name': 'San Marino', 'flag': '🇸🇲', 'code': 'SM'},
      {'name': 'Serbia', 'flag': '🇷🇸', 'code': 'RS'},
      {'name': 'Slovakia', 'flag': '🇸🇰', 'code': 'SK'},
      {'name': 'Slovenia', 'flag': '🇸🇮', 'code': 'SI'},
      {'name': 'Spain', 'flag': '🇪🇸', 'code': 'ES'},
      {'name': 'Sweden', 'flag': '🇸🇪', 'code': 'SE'},
      {'name': 'Switzerland', 'flag': '🇨🇭', 'code': 'CH'},
      {'name': 'Ukraine', 'flag': '🇺🇦', 'code': 'UA'},
      {'name': 'United Kingdom', 'flag': '🇬🇧', 'code': 'GB'},
      {'name': 'Vatican City', 'flag': '🇻🇦', 'code': 'VA'},
    ],
    'North America': [
      {'name': 'Antigua and Barbuda', 'flag': '🇦🇬', 'code': 'AG'},
      {'name': 'Bahamas', 'flag': '🇧🇸', 'code': 'BS'},
      {'name': 'Barbados', 'flag': '🇧🇧', 'code': 'BB'},
      {'name': 'Belize', 'flag': '🇧🇿', 'code': 'BZ'},
      {'name': 'Canada', 'flag': '🇨🇦', 'code': 'CA'},
      {'name': 'Costa Rica', 'flag': '🇨🇷', 'code': 'CR'},
      {'name': 'Cuba', 'flag': '🇨🇺', 'code': 'CU'},
      {'name': 'Dominica', 'flag': '🇩🇲', 'code': 'DM'},
      {'name': 'Dominican Republic', 'flag': '🇩🇴', 'code': 'DO'},
      {'name': 'El Salvador', 'flag': '🇸🇻', 'code': 'SV'},
      {'name': 'Grenada', 'flag': '🇬🇩', 'code': 'GD'},
      {'name': 'Guatemala', 'flag': '🇬🇹', 'code': 'GT'},
      {'name': 'Haiti', 'flag': '🇭🇹', 'code': 'HT'},
      {'name': 'Honduras', 'flag': '🇭🇳', 'code': 'HN'},
      {'name': 'Jamaica', 'flag': '🇯🇲', 'code': 'JM'},
      {'name': 'Mexico', 'flag': '🇲🇽', 'code': 'MX'},
      {'name': 'Nicaragua', 'flag': '🇳🇮', 'code': 'NI'},
      {'name': 'Panama', 'flag': '🇵🇦', 'code': 'PA'},
      {'name': 'Saint Kitts and Nevis', 'flag': '🇰🇳', 'code': 'KN'},
      {'name': 'Saint Lucia', 'flag': '🇱🇨', 'code': 'LC'},
      {'name': 'Saint Vincent and the Grenadines', 'flag': '🇻🇨', 'code': 'VC'},
      {'name': 'Trinidad and Tobago', 'flag': '🇹🇹', 'code': 'TT'},
      {'name': 'United States', 'flag': '🇺🇸', 'code': 'US'},
    ],
    'South America': [
      {'name': 'Argentina', 'flag': '🇦🇷', 'code': 'AR'},
      {'name': 'Bolivia', 'flag': '🇧🇴', 'code': 'BO'},
      {'name': 'Brazil', 'flag': '🇧🇷', 'code': 'BR'},
      {'name': 'Chile', 'flag': '🇨🇱', 'code': 'CL'},
      {'name': 'Colombia', 'flag': '🇨🇴', 'code': 'CO'},
      {'name': 'Ecuador', 'flag': '🇪🇨', 'code': 'EC'},
      {'name': 'Guyana', 'flag': '🇬🇾', 'code': 'GY'},
      {'name': 'Paraguay', 'flag': '🇵🇾', 'code': 'PY'},
      {'name': 'Peru', 'flag': '🇵🇪', 'code': 'PE'},
      {'name': 'Suriname', 'flag': '🇸🇷', 'code': 'SR'},
      {'name': 'Uruguay', 'flag': '🇺🇾', 'code': 'UY'},
      {'name': 'Venezuela', 'flag': '🇻🇪', 'code': 'VE'},
    ],
    'Oceania': [
      {'name': 'Australia', 'flag': '🇦🇺', 'code': 'AU'},
      {'name': 'Fiji', 'flag': '🇫🇯', 'code': 'FJ'},
      {'name': 'Kiribati', 'flag': '🇰🇮', 'code': 'KI'},
      {'name': 'Marshall Islands', 'flag': '🇲🇭', 'code': 'MH'},
      {'name': 'Micronesia', 'flag': '🇫🇲', 'code': 'FM'},
      {'name': 'Nauru', 'flag': '🇳🇷', 'code': 'NR'},
      {'name': 'New Zealand', 'flag': '🇳🇿', 'code': 'NZ'},
      {'name': 'Palau', 'flag': '🇵🇼', 'code': 'PW'},
      {'name': 'Papua New Guinea', 'flag': '🇵🇬', 'code': 'PG'},
      {'name': 'Samoa', 'flag': '🇼🇸', 'code': 'WS'},
      {'name': 'Solomon Islands', 'flag': '🇸🇧', 'code': 'SB'},
      {'name': 'Tonga', 'flag': '🇹🇴', 'code': 'TO'},
      {'name': 'Tuvalu', 'flag': '🇹🇻', 'code': 'TV'},
      {'name': 'Vanuatu', 'flag': '🇻🇺', 'code': 'VU'},
    ],
  };

  AddCountriesProvider() {
    _initializeCountries();
    _loadAddedCountries();
  }

  // Get all countries as a flat list
  List<Map<String, String>> get allCountriesFlat {
    List<Map<String, String>> countries = [];
    _countriesByContinent.forEach((continent, countryList) {
      for (var country in countryList) {
        countries.add({
          'name': country['name']!,
          'flag': country['flag']!,
          'code': country['code']!,
          'continent': continent,
        });
      }
    });
    countries.sort((a, b) => a['name']!.compareTo(b['name']!));
    return countries;
  }

  void _initializeCountries() {
    _allCountries = allCountriesFlat;
    _filteredCountries = _allCountries;
    notifyListeners();
  }

  // Load added countries from Firebase
  Future<void> _loadAddedCountries() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('VisitedCountries')
          .orderBy('addedAt', descending: true)
          .get();

      _addedCountries = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'flag': data['flag'] ?? '🌍',
          'addedAt': data['addedAt'],
          'continent': _getCountryContinent(data['name'] ?? ''),
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      log('Error loading added countries: $e');
    }
  }

  String _getCountryContinent(String countryName) {
    for (var entry in _countriesByContinent.entries) {
      final continent = entry.key;
      final countries = entry.value;
      
      for (var country in countries) {
        if (country['name']?.toLowerCase() == countryName.toLowerCase()) {
          return continent;
        }
      }
    }
    return 'Unknown';
  }

  void toggleSearchVisibility() {
    _isSearchVisible = !_isSearchVisible;
    notifyListeners();
  }

  void setSelectedContinent(String continent) {
    _selectedContinent = continent;
    _filterCountries();
    notifyListeners();
  }

  void updateSearchText(String text) {
    _searchText = text;
    searchController.text = text;
    _filterCountries();
    notifyListeners();
  }

  void _filterCountries() {
    List<Map<String, String>> filtered = _allCountries;

    // Get already added country names to exclude them
    Set<String> addedCountryNames = _addedCountries
        .map((country) => country['name'].toString().toLowerCase())
        .toSet();

    // Filter by continent
    if (_selectedContinent != 'All') {
      filtered = filtered.where((country) {
        return country['continent'] == _selectedContinent;
      }).toList();
    }

    // Filter by search text
    if (_searchText.isNotEmpty) {
      filtered = filtered.where((country) {
        return country['name']!.toLowerCase().contains(_searchText.toLowerCase());
      }).toList();
    }

    // Exclude already added countries
    filtered = filtered.where((country) {
      return !addedCountryNames.contains(country['name']!.toLowerCase()) &&
             !_currentlyAddingCountries.contains(country['name']!.toLowerCase());
    }).toList();

    _filteredCountries = filtered;
  }

  // Check if country is already added
  Future<bool> isCountryAlreadyAdded(String countryName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('VisitedCountries')
          .where('name', isEqualTo: countryName)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      log('Error checking if country is added: $e');
      return false;
    }
  }

  // Add country to Firebase
  Future<String> addCountry(String countryName, String flag) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return 'Please sign in to add countries';
    }

    final countryKey = countryName.toLowerCase();

    // Check if this country is currently being added (prevent rapid clicking)
    if (_currentlyAddingCountries.contains(countryKey)) {
      return 'Please wait, adding country...';
    }

    // Check if country is already added
    if (await isCountryAlreadyAdded(countryName)) {
      return 'This country is already added';
    }

    // Mark country as being added
    _currentlyAddingCountries.add(countryKey);
    notifyListeners();

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('VisitedCountries')
          .add({
        'name': countryName,
        'flag': flag,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Add to local list
      _addedCountries.insert(0, {
        'id': docRef.id,
        'name': countryName,
        'flag': flag,
        'addedAt': DateTime.now(),
        'continent': _getCountryContinent(countryName),
      });

      // Refresh the filtered countries to exclude newly added country
      _filterCountries();
      
      return 'Country added successfully!';
    } catch (e) {
      log('Error adding country: $e');
      return 'Failed to add country. Please try again.';
    } finally {
      // Remove from adding list
      _currentlyAddingCountries.remove(countryKey);
      notifyListeners();
    }
  }

  // Remove country from Firebase
  Future<String> removeCountry(String countryId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return 'Please sign in to remove countries';
    }

    final countryKey = countryId.toLowerCase();

    // Check if this country is currently being removed (prevent rapid clicking)
    if (_currentlyRemovingCountries.contains(countryKey)) {
      return 'Please wait, removing country...';
    }

    // Mark country as being removed
    _currentlyRemovingCountries.add(countryKey);
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('VisitedCountries')
          .doc(countryId)
          .delete();

      // Remove from local list
      _addedCountries.removeWhere((country) => country['id'] == countryId);

      // Refresh the filtered countries to include newly removed country
      _filterCountries();
      
      return 'Country removed successfully!';
    } catch (e) {
      log('Error removing country: $e');
      return 'Failed to remove country. Please try again.';
    } finally {
      // Remove from removing list
      _currentlyRemovingCountries.remove(countryKey);
      notifyListeners();
    }
  }

  // Check if country is being added
  bool isCountryBeingAdded(String countryName) {
    return _currentlyAddingCountries.contains(countryName.toLowerCase());
  }

  // Check if country is being removed
  bool isCountryBeingRemoved(String countryId) {
    return _currentlyRemovingCountries.contains(countryId.toLowerCase());
  }

  // Get countries grouped by region with counts
  Map<String, List<Map<String, dynamic>>> get addedCountriesByRegion {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var country in _addedCountries) {
      final continent = country['continent'].toString();
      if (!grouped.containsKey(continent)) {
        grouped[continent] = [];
      }
      grouped[continent]!.add(country);
    }
    
    return grouped;
  }

  // Get region count for a specific region
  int getRegionCount(String region) {
    return _addedCountries
        .where((country) => country['continent'] == region)
        .length;
  }

  // Get total added countries count
  int get addedCountriesCount => _addedCountries.length;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}