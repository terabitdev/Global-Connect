import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:global_connect/core/const/app_color.dart';

class VisitedCountriesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController searchController = TextEditingController();

  List<Map<String, String>> _searchResults = [];
  String? _selectedCountry;
  String? _selectedFlag;
  String? _selectedContinent;
  bool _isSearching = false;
  bool _isAddingCountry = false;
  Set<String> _currentlyAddingCountries = {};

  // Add visited countries state management
  Set<String> _visitedCountryCodes = {};
  Map<String, Color> _countryColorsMap = {};
  StreamSubscription<QuerySnapshot>? _visitedCountriesSubscription;

  // Selection state management
  Set<String> _selectedCountryIds = {};
  bool _isSelectionMode = false;

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

  // Country name to code mapping
  static const Map<String, String> _nameToCodeMap = {
    'united states': 'US',
    'usa': 'US',
    'america': 'US',
    'united states of america': 'US',
    'u.s.a': 'US',
    'us': 'US',
    'united kingdom': 'GB',
    'uk': 'GB',
    'britain': 'GB',
    'great britain': 'GB',
    'england': 'GB',
    'canada': 'CA',
    'france': 'FR',
    'germany': 'DE',
    'deutschland': 'DE',
    'italy': 'IT',
    'italia': 'IT',
    'spain': 'ES',
    'espana': 'ES',
    'japan': 'JP',
    'china': 'CN',
    'prc': 'CN',
    'people\'s republic of china': 'CN',
    'india': 'IN',
    'hindustan': 'IN',
    'brazil': 'BR',
    'brasil': 'BR',
    'australia': 'AU',
    'russia': 'RU',
    'russian federation': 'RU',
    'ussr': 'RU',
    'soviet union': 'RU',
    'mexico': 'MX',
    'south korea': 'KR',
    'korea': 'KR',
    'republic of korea': 'KR',
    'netherlands': 'NL',
    'holland': 'NL',
    'switzerland': 'CH',
    'sweden': 'SE',
    'norway': 'NO',
    'denmark': 'DK',
    'finland': 'FI',
    'poland': 'PL',
    'portugal': 'PT',
    'greece': 'GR',
    'hellas': 'GR',
    'turkey': 'TR',
    'turkiye': 'TR',
    'egypt': 'EG',
    'south africa': 'ZA',
    'thailand': 'TH',
    'singapore': 'SG',
    'indonesia': 'ID',
    'malaysia': 'MY',
    'philippines': 'PH',
    'vietnam': 'VN',
    'viet nam': 'VN',
    'new zealand': 'NZ',
    'argentina': 'AR',
    'chile': 'CL',
    'colombia': 'CO',
    'peru': 'PE',
    'pakistan': 'PK',
    'sudan': 'SD',
    'south sudan': 'SS',
    'morocco': 'MA',
    'algeria': 'DZ',
    'tunisia': 'TN',
    'libya': 'LY',
    'ethiopia': 'ET',
    'kenya': 'KE',
    'uganda': 'UG',
    'tanzania': 'TZ',
    'rwanda': 'RW',
    'burundi': 'BI',
    'madagascar': 'MG',
    'mauritius': 'MU',
    'seychelles': 'SC',
    'nigeria': 'NG',
    'ghana': 'GH',
    'ivory coast': 'CI',
    'cote d\'ivoire': 'CI',
    'senegal': 'SN',
    'mali': 'ML',
    'burkina faso': 'BF',
    'niger': 'NE',
    'chad': 'TD',
    'cameroon': 'CM',
    'central african republic': 'CF',
    'car': 'CF',
    'congo': 'CG',
    'democratic republic of congo': 'CD',
    'drc': 'CD',
    'congo-kinshasa': 'CD',
    'congo-brazzaville': 'CG',
    'gabon': 'GA',
    'equatorial guinea': 'GQ',
    'angola': 'AO',
    'zambia': 'ZM',
    'zimbabwe': 'ZW',
    'botswana': 'BW',
    'namibia': 'NA',
    'lesotho': 'LS',
    'swaziland': 'SZ',
    'eswatini': 'SZ',
    'mozambique': 'MZ',
    'malawi': 'MW',
    'bangladesh': 'BD',
    'sri lanka': 'LK',
    'myanmar': 'MM',
    'burma': 'MM',
    'cambodia': 'KH',
    'kampuchea': 'KH',
    'laos': 'LA',
    'nepal': 'NP',
    'bhutan': 'BT',
    'afghanistan': 'AF',
    'iran': 'IR',
    'persia': 'IR',
    'iraq': 'IQ',
    'syria': 'SY',
    'lebanon': 'LB',
    'jordan': 'JO',
    'israel': 'IL',
    'palestine': 'PS',
    'saudi arabia': 'SA',
    'ksa': 'SA',
    'uae': 'AE',
    'united arab emirates': 'AE',
    'emirates': 'AE',
    'qatar': 'QA',
    'kuwait': 'KW',
    'bahrain': 'BH',
    'oman': 'OM',
    'yemen': 'YE',
    'ukraine': 'UA',
    'belarus': 'BY',
    'moldova': 'MD',
    'romania': 'RO',
    'bulgaria': 'BG',
    'serbia': 'RS',
    'croatia': 'HR',
    'bosnia and herzegovina': 'BA',
    'bosnia': 'BA',
    'herzegovina': 'BA',
    'montenegro': 'ME',
    'albania': 'AL',
    'north macedonia': 'MK',
    'macedonia': 'MK',
    'slovenia': 'SI',
    'slovakia': 'SK',
    'slovak republic': 'SK',
    'czech republic': 'CZ',
    'czechia': 'CZ',
    'czechoslovakia': 'CZ',
    'hungary': 'HU',
    'austria': 'AT',
    'belgium': 'BE',
    'luxembourg': 'LU',
    'ireland': 'IE',
    'eire': 'IE',
    'iceland': 'IS',
    'estonia': 'EE',
    'latvia': 'LV',
    'lithuania': 'LT',
  };

  static const Map<String, String> _countryFlags = {
    'afghanistan': '🇦🇫', 'albania': '🇦🇱', 'algeria': '🇩🇿', 'andorra': '🇦🇩',
    'angola': '🇦🇴', 'argentina': '🇦🇷', 'armenia': '🇦🇲', 'australia': '🇦🇺',
    'austria': '🇦🇹', 'azerbaijan': '🇦🇿', 'bahamas': '🇧🇸', 'bahrain': '🇧🇭',
    'bangladesh': '🇧🇩', 'barbados': '🇧🇧', 'belarus': '🇧🇾', 'belgium': '🇧🇪',
    'belize': '🇧🇿', 'benin': '🇧🇯', 'bhutan': '🇧🇹', 'bolivia': '🇧🇴',
    'bosnia and herzegovina': '🇧🇦', 'bosnia': '🇧🇦', 'herzegovina': '🇧🇦',
    'botswana': '🇧🇼', 'brazil': '🇧🇷', 'brasil': '🇧🇷',
    'brunei': '🇧🇳', 'bulgaria': '🇧🇬', 'burkina faso': '🇧🇫', 'burundi': '🇧🇮',
    'cambodia': '🇰🇭', 'kampuchea': '🇰🇭', 'cameroon': '🇨🇲', 'canada': '🇨🇦', 
    'cape verde': '🇨🇻', 'central african republic': '🇨🇫', 'car': '🇨🇫',
    'chad': '🇹🇩', 'chile': '🇨🇱', 'china': '🇨🇳', 'prc': '🇨🇳',
    'people\'s republic of china': '🇨🇳', 'colombia': '🇨🇴', 'comoros': '🇰🇲', 
    'congo': '🇨🇬', 'congo-brazzaville': '🇨🇬', 'democratic republic of congo': '🇨🇩',
    'drc': '🇨🇩', 'congo-kinshasa': '🇨🇩', 'costa rica': '🇨🇷',
    'croatia': '🇭🇷', 'cuba': '🇨🇺', 'cyprus': '🇨🇾', 'czech republic': '🇨🇿',
    'czechia': '🇨🇿', 'czechoslovakia': '🇨🇿', 'denmark': '🇩🇰', 'djibouti': '🇩🇯', 
    'dominica': '🇩🇲', 'dominican republic': '🇩🇴', 'ecuador': '🇪🇨', 'egypt': '🇪🇬', 
    'el salvador': '🇸🇻', 'equatorial guinea': '🇬🇶', 'eritrea': '🇪🇷', 'estonia': '🇪🇪', 
    'eswatini': '🇸🇿', 'swaziland': '🇸🇿', 'ethiopia': '🇪🇹', 'fiji': '🇫🇯', 
    'finland': '🇫🇮', 'france': '🇫🇷', 'gabon': '🇬🇦', 'gambia': '🇬🇲', 
    'georgia': '🇬🇪', 'germany': '🇩🇪', 'deutschland': '🇩🇪', 'ghana': '🇬🇭', 
    'greece': '🇬🇷', 'hellas': '🇬🇷', 'grenada': '🇬🇩', 'guatemala': '🇬🇹',
    'guinea': '🇬🇳', 'guinea-bissau': '🇬🇼', 'guyana': '🇬🇾', 'haiti': '🇭🇹',
    'honduras': '🇭🇳', 'hungary': '🇭🇺', 'iceland': '🇮🇸', 'india': '🇮🇳',
    'hindustan': '🇮🇳', 'indonesia': '🇮🇩', 'iran': '🇮🇷', 'persia': '🇮🇷',
    'iraq': '🇮🇶', 'ireland': '🇮🇪', 'eire': '🇮🇪', 'israel': '🇮🇱', 
    'italy': '🇮🇹', 'italia': '🇮🇹', 'ivory coast': '🇨🇮', 'cote d\'ivoire': '🇨🇮',
    'jamaica': '🇯🇲', 'japan': '🇯🇵', 'jordan': '🇯🇴', 'kazakhstan': '🇰🇿', 
    'kenya': '🇰🇪', 'kiribati': '🇰🇮', 'kuwait': '🇰🇼', 'kyrgyzstan': '🇰🇬', 
    'laos': '🇱🇦', 'latvia': '🇱🇻', 'lebanon': '🇱🇧', 'lesotho': '🇱🇸', 
    'liberia': '🇱🇷', 'libya': '🇱🇾', 'liechtenstein': '🇱🇮', 'lithuania': '🇱🇹', 
    'luxembourg': '🇱🇺', 'madagascar': '🇲🇬', 'malawi': '🇲🇼', 'malaysia': '🇲🇾', 
    'maldives': '🇲🇻', 'mali': '🇲🇱', 'malta': '🇲🇹', 'marshall islands': '🇲🇭', 
    'mauritania': '🇲🇷', 'mauritius': '🇲🇺', 'mexico': '🇲🇽', 'micronesia': '🇫🇲', 
    'moldova': '🇲🇩', 'monaco': '🇲🇨', 'mongolia': '🇲🇳', 'montenegro': '🇲🇪', 
    'morocco': '🇲🇦', 'mozambique': '🇲🇿', 'myanmar': '🇲🇲', 'burma': '🇲🇲',
    'namibia': '🇳🇦', 'nauru': '🇳🇷', 'nepal': '🇳🇵', 'netherlands': '🇳🇱', 
    'holland': '🇳🇱', 'new zealand': '🇳🇿', 'nicaragua': '🇳🇮', 'niger': '🇳🇪',
    'nigeria': '🇳🇬', 'north korea': '🇰🇵', 'north macedonia': '🇲🇰', 
    'macedonia': '🇲🇰', 'norway': '🇳🇴', 'oman': '🇴🇲', 'pakistan': '🇵🇰', 
    'palau': '🇵🇼', 'panama': '🇵🇦', 'papua new guinea': '🇵🇬', 'paraguay': '🇵🇾', 
    'peru': '🇵🇪', 'philippines': '🇵🇭', 'poland': '🇵🇱', 'portugal': '🇵🇹', 
    'qatar': '🇶🇦', 'romania': '🇷🇴', 'russia': '🇷🇺', 'russian federation': '🇷🇺',
    'ussr': '🇷🇺', 'soviet union': '🇷🇺', 'rwanda': '🇷🇼', 
    'saint kitts and nevis': '🇰🇳', 'saint lucia': '🇱🇨',
    'saint vincent and the grenadines': '🇻🇨', 'samoa': '🇼🇸', 'san marino': '🇸🇲',
    'sao tome and principe': '🇸🇹', 'saudi arabia': '🇸🇦', 'ksa': '🇸🇦',
    'senegal': '🇸🇳', 'serbia': '🇷🇸', 'seychelles': '🇸🇨', 'sierra leone': '🇸🇱', 
    'singapore': '🇸🇬', 'slovakia': '🇸🇰', 'slovak republic': '🇸🇰',
    'slovenia': '🇸🇮', 'solomon islands': '🇸🇧', 'somalia': '🇸🇴',
    'south africa': '🇿🇦', 'south korea': '🇰🇷', 'korea': '🇰🇷', 
    'republic of korea': '🇰🇷', 'south sudan': '🇸🇸', 'spain': '🇪🇸', 'espana': '🇪🇸',
    'sri lanka': '🇱🇰', 'sudan': '🇸🇩', 'suriname': '🇸🇷', 'sweden': '🇸🇪',
    'switzerland': '🇨🇭', 'syria': '🇸🇾', 'taiwan': '🇹🇼', 'tajikistan': '🇹🇯',
    'tanzania': '🇹🇿', 'thailand': '🇹🇭', 'timor-leste': '🇹🇱', 'togo': '🇹🇬',
    'tonga': '🇹🇴', 'trinidad and tobago': '🇹🇹', 'tunisia': '🇹🇳', 'turkey': '🇹🇷',
    'turkiye': '🇹🇷', 'turkmenistan': '🇹🇲', 'tuvalu': '🇹🇻', 'uganda': '🇺🇬', 
    'ukraine': '🇺🇦', 'united arab emirates': '🇦🇪', 'uae': '🇦🇪', 'emirates': '🇦🇪',
    'united kingdom': '🇬🇧', 'uk': '🇬🇧', 'britain': '🇬🇧', 'great britain': '🇬🇧',
    'england': '🇬🇧', 'united states': '🇺🇸', 'usa': '🇺🇸', 'america': '🇺🇸',
    'united states of america': '🇺🇸', 'u.s.a': '🇺🇸', 'us': '🇺🇸',
    'uruguay': '🇺🇾', 'uzbekistan': '🇺🇿', 'vanuatu': '🇻🇺', 'vatican city': '🇻🇦', 
    'venezuela': '🇻🇪', 'vietnam': '🇻🇳', 'viet nam': '🇻🇳', 'yemen': '🇾🇪', 
    'zambia': '🇿🇲', 'zimbabwe': '🇿🇼'
  };

  // Getters for search functionality
  List<Map<String, String>> get searchResults => _searchResults;
  String? get selectedCountry => _selectedCountry;
  String? get selectedFlag => _selectedFlag;
  String? get selectedContinent => _selectedContinent;
  bool get isSearching => _isSearching;
  bool get isAddingCountry => _isAddingCountry;
  bool get isCountrySelected => _selectedCountry != null && _selectedFlag != null;
  Map<String, List<Map<String, String>>> get countriesByContinent => _countriesByContinent;
  
  // Get all countries as a flat list for search
  static List<Map<String, String>> get allCountries {
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

  // Getters for map functionality
  Set<String> get visitedCountryCodes => _visitedCountryCodes;
  Map<String, Color> get countryColorsMap => _countryColorsMap;

  // Getters for selection functionality
  Set<String> get selectedCountryIds => _selectedCountryIds;
  bool get isSelectionMode => _isSelectionMode;
  int get selectedCount => _selectedCountryIds.length;
  bool isCountrySelectedForDeletion(String countryId) => _selectedCountryIds.contains(countryId);
  
  // Getters for adding state
  bool isCountryBeingAdded(String countryName) => _currentlyAddingCountries.contains(countryName.toLowerCase());

  // Initialize visited countries stream
  void initializeVisitedCountriesStream([String? userId]) {
    final String? uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return;

    _visitedCountriesSubscription?.cancel();
    _visitedCountriesSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('VisitedCountries')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .listen(_processVisitedCountriesSnapshot);
  }

  // Process visited countries snapshot and update state
  void _processVisitedCountriesSnapshot(QuerySnapshot snapshot) {
    print('📊 Processing ${snapshot.docs.length} documents from Firebase');

    Set<String> newVisitedCountries = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final countryName = data['name'] as String;
      final countryCode = _getCountryCodeFromName(countryName);

      print('📍 Document: ${doc.id}');
      print('   Country Name: "$countryName"');
      print('   Country Code: $countryCode');

      if (countryCode != null) {
        newVisitedCountries.add(countryCode);
        print('   ✅ Added to visited countries');
      } else {
        print('   ❌ Country code not found - need to add mapping');
      }
    }

    print('🌍 Total visited countries: ${newVisitedCountries.length}');
    print('🌍 Visited country codes: $newVisitedCountries');

    // Only update if the data actually changed
    if (_visitedCountryCodes.length != newVisitedCountries.length ||
        !_visitedCountryCodes.containsAll(newVisitedCountries)) {
      print('🔄 Visited countries changed, updating state');
      _visitedCountryCodes = newVisitedCountries;
      _updateColorsMap();
      notifyListeners();
    } else {
      print('🔄 Visited countries unchanged, no update needed');
    }
  }

  // Convert country name to country code
  String? _getCountryCodeFromName(String countryName) {
    final normalizedName = countryName.toLowerCase().trim();
    print('🔍 Looking for country: "$countryName" (normalized: "$normalizedName")');
    final countryCode = _nameToCodeMap[normalizedName];
    print('🗺️ Found country code: $countryCode');
    return countryCode;
  }

  // Generate colors map for visited countries
  void _updateColorsMap() {
    Map<String, Color> colors = {};
    print('🎨 Generating colors for ${_visitedCountryCodes.length} countries');

    for (String countryCode in _visitedCountryCodes) {
      colors[countryCode] = AppColors.primary;
      print('🎨 Coloring $countryCode as blue');
      colors[countryCode.toLowerCase()] = AppColors.primary!;
      print('🎨 Also trying lowercase: ${countryCode.toLowerCase()}');
      colors['country_$countryCode'] = AppColors.primary!;
      colors['country_${countryCode.toLowerCase()}'] = AppColors.primary!;
    }

    print('🎨 Final colors map keys: ${colors.keys.toList()}');
    _countryColorsMap = colors;
  }

  // Handle country tap on map
  void handleCountryTap(String countryId, String countryName) {
    print('🖱️ Tapped country ID: "$countryId" Name: "$countryName"');
    print('🔍 Available visited codes: $_visitedCountryCodes');

    if (_visitedCountryCodes.contains(countryId)) {
      print('✅ This country IS visited (should be blue)');
    } else {
      print('❌ This country is NOT in visited list');
      print('💡 Try mapping this country name to your Firebase data');
    }
  }

  // Get country flag with efficient lookup
  String getCountryFlag(String countryName) {
    final normalizedName = countryName.toLowerCase().trim();

    if (_countryFlags.containsKey(normalizedName)) {
      return _countryFlags[normalizedName]!;
    }

    for (final entry in _countryFlags.entries) {
      if (normalizedName.contains(entry.key) || entry.key.contains(normalizedName)) {
        return entry.value;
      }
    }

    return '🌍';
  }

  // Get visited countries stream for UI
  Stream<QuerySnapshot> getVisitedCountriesStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('VisitedCountries')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }


  Future<bool> isCountryAlreadyVisited(String countryName) async {
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
      log('Error checking if country is visited: $e');
      return false;
    }
  }

  Future<void> searchCountries(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _isSearching = true;
    notifyListeners();

    try {
      // Get current user's visited countries to filter them out
      final currentUser = _auth.currentUser;
      Set<String> visitedCountryNames = {};
      
      if (currentUser != null) {
        try {
          final visitedSnapshot = await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('VisitedCountries')
              .get();
          
          visitedCountryNames = visitedSnapshot.docs
              .map((doc) => (doc.data()['name'] as String).toLowerCase())
              .toSet();
        } catch (e) {
          log('Error fetching visited countries for search filter: $e');
        }
      }

      // Filter countries locally instead of using API
      final normalizedQuery = query.toLowerCase().trim();
      final matches = <Map<String, String>>[];
      
      for (var country in allCountries) {
        final countryNameLower = country['name']!.toLowerCase();
        
        // Skip if country is already visited OR currently being added
        if (visitedCountryNames.contains(countryNameLower) || 
            _currentlyAddingCountries.contains(countryNameLower)) {
          continue;
        }
        
        if (countryNameLower.startsWith(normalizedQuery)) {
          matches.add({
            'name': country['name']!,
            'flag': country['flag']!,
            'continent': country['continent']!,
          });
        }
      }
      
      // If no starts-with matches, check for contains
      if (matches.isEmpty) {
        for (var country in allCountries) {
          final countryNameLower = country['name']!.toLowerCase();
          
          // Skip if country is already visited OR currently being added
          if (visitedCountryNames.contains(countryNameLower) || 
              _currentlyAddingCountries.contains(countryNameLower)) {
            continue;
          }
          
          if (countryNameLower.contains(normalizedQuery)) {
            matches.add({
              'name': country['name']!,
              'flag': country['flag']!,
              'continent': country['continent']!,
            });
          }
        }
      }
      
      // Sort results alphabetically
      matches.sort((a, b) => a['name']!.compareTo(b['name']!));
      
      // Limit to 10 results for better UX
      _searchResults = matches.take(10).toList();
      
    } catch (e) {
      _searchResults = [];
      log('Error searching countries: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void selectCountry(String countryName, String flag, [String? continent]) {
    _selectedCountry = countryName;
    _selectedFlag = flag;
    _selectedContinent = continent;
    searchController.text = countryName;
    // Don't clear search results immediately to allow user to see other options
    // _searchResults = []; // Commented out to keep results visible
    notifyListeners();
  }

  Future<String> addCountryToVisited() async {
    if (!isCountrySelected) {
      return 'Please select a country first';
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return 'Please sign in to add countries';
    }

    if (await isCountryAlreadyVisited(_selectedCountry!)) {
      return 'This country is already in your visited list';
    }

    _isAddingCountry = true;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('VisitedCountries')
          .add({
        'name': _selectedCountry!,
        'flag': _selectedFlag!,
        'addedAt': FieldValue.serverTimestamp(),
      });

      clearSelection();
      return 'Country added successfully!';
    } catch (e) {
      log('Error adding country: $e');
      return 'Failed to add country. Please try again.';
    } finally {
      _isAddingCountry = false;
      notifyListeners();
    }
  }

  Future<String> addCountryDirectly(String countryName, String flag) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return 'Please sign in to add countries';
    }

    final countryKey = countryName.toLowerCase();

    // Check if this country is currently being added (prevent rapid clicking)
    if (_currentlyAddingCountries.contains(countryKey)) {
      return 'Please wait, adding country...';
    }

    // Check if country is already visited
    if (await isCountryAlreadyVisited(countryName)) {
      return 'This country is already in your visited list';
    }

    // Mark country as being added
    _currentlyAddingCountries.add(countryKey);
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('VisitedCountries')
          .add({
        'name': countryName,
        'flag': flag,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Keep search results visible after adding
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

  // Remove country by document ID - preferred method
  Future<String> removeCountryFromVisited(String countryId) async {
    print('🔥 VisitedCountriesProvider.removeCountryFromVisited called');
    print('🆔 Country ID to delete: $countryId');
    
    final currentUser = _auth.currentUser;
    print('👤 Current user: ${currentUser?.uid ?? 'null'}');
    
    if (currentUser == null) {
      print('❌ No current user found');
      return 'Please sign in to remove countries';
    }

    try {
      final docRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('VisitedCountries')
          .doc(countryId);
      
      print('📄 Document path: users/${currentUser.uid}/VisitedCountries/$countryId');
      
      // Check if document exists first
      final docSnapshot = await docRef.get();
      print('📋 Document exists: ${docSnapshot.exists}');
      
      if (!docSnapshot.exists) {
        print('❌ Document does not exist');
        return 'Country not found in your visited list';
      }
      
      print('🗑️ Attempting to delete document...');
      await docRef.delete();
      print('✅ Document deleted successfully');

      return 'Country removed successfully!';
    } catch (e) {
      print('❌ Error removing country: $e');
      log('Error removing country: $e');
      return 'Failed to remove country: $e';
    }
  }

  // Remove country by name - alternative method
  Future<String> removeCountry(String countryName) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return 'Please sign in to remove countries';
    }

    try {
      // Find the document with the matching country name
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('VisitedCountries')
          .where('name', isEqualTo: countryName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 'Country not found in your visited list';
      }

      // Delete the found document
      await querySnapshot.docs.first.reference.delete();

      return 'Country removed successfully!';
    } catch (e) {
      log('Error removing country: $e');
      return 'Failed to remove country. Please try again.';
    }
  }

  // Selection management methods
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedCountryIds.clear();
    }
    notifyListeners();
  }

  void toggleCountrySelection(String countryId) {
    if (_selectedCountryIds.contains(countryId)) {
      _selectedCountryIds.remove(countryId);
    } else {
      _selectedCountryIds.add(countryId);
    }
    notifyListeners();
  }

  void selectAllCountries(List<String> countryIds) {
    _selectedCountryIds.addAll(countryIds);
    notifyListeners();
  }

  void deselectAllCountries() {
    _selectedCountryIds.clear();
    notifyListeners();
  }

  void exitSelectionMode() {
    _isSelectionMode = false;
    _selectedCountryIds.clear();
    notifyListeners();
  }

  // Batch delete selected countries
  Future<String> removeSelectedCountries() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return 'Please sign in to remove countries';
    }

    if (_selectedCountryIds.isEmpty) {
      return 'No countries selected';
    }

    try {
      // Delete all selected countries in a batch
      final batch = _firestore.batch();
      final userCountriesRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('VisitedCountries');

      for (String countryId in _selectedCountryIds) {
        batch.delete(userCountriesRef.doc(countryId));
      }

      await batch.commit();

      final removedCount = _selectedCountryIds.length;
      exitSelectionMode();

      return '$removedCount ${removedCount == 1 ? 'country' : 'countries'} removed successfully!';
    } catch (e) {
      log('Error removing selected countries: $e');
      return 'Failed to remove countries. Please try again.';
    }
  }

  void clearSelection() {
    _selectedCountry = null;
    _selectedFlag = null;
    _selectedContinent = null;
    searchController.clear();
    _searchResults = [];
    notifyListeners();
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    _visitedCountriesSubscription?.cancel();
    super.dispose();
  }
}