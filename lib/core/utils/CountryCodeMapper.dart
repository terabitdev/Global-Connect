class CountryCodeMapper {
  static const Map<String, String> _countryCodeMap = {
    // North America
    'United States': 'US',
    'Canada': 'CA',
    'Mexico': 'MX',
    
    // Europe
    'United Kingdom': 'GB',
    'Germany': 'DE',
    'France': 'FR',
    'Italy': 'IT',
    'Spain': 'ES',
    'Netherlands': 'NL',
    'Belgium': 'BE',
    'Switzerland': 'CH',
    'Austria': 'AT',
    'Sweden': 'SE',
    'Norway': 'NO',
    'Denmark': 'DK',
    'Finland': 'FI',
    'Poland': 'PL',
    'Czech Republic': 'CZ',
    'Hungary': 'HU',
    'Romania': 'RO',
    'Greece': 'GR',
    'Portugal': 'PT',
    'Ireland': 'IE',
    'Russia': 'RU',
    'Ukraine': 'UA',
    
    // Asia
    'China': 'CN',
    'Japan': 'JP',
    'India': 'IN',
    'Pakistan': 'PK',
    'Bangladesh': 'BD',
    'Indonesia': 'ID',
    'Thailand': 'TH',
    'Vietnam': 'VN',
    'Philippines': 'PH',
    'Malaysia': 'MY',
    'Singapore': 'SG',
    'South Korea': 'KR',
    'Taiwan': 'TW',
    'Hong Kong': 'HK',
    'Sri Lanka': 'LK',
    'Nepal': 'NP',
    'Myanmar': 'MM',
    'Cambodia': 'KH',
    'Laos': 'LA',
    
    // Middle East
    'Saudi Arabia': 'SA',
    'United Arab Emirates': 'AE',
    'Qatar': 'QA',
    'Kuwait': 'KW',
    'Bahrain': 'BH',
    'Oman': 'OM',
    'Iran': 'IR',
    'Iraq': 'IQ',
    'Israel': 'IL',
    'Jordan': 'JO',
    'Lebanon': 'LB',
    'Syria': 'SY',
    'Turkey': 'TR',
    
    // Africa
    'South Africa': 'ZA',
    'Egypt': 'EG',
    'Nigeria': 'NG',
    'Kenya': 'KE',
    'Morocco': 'MA',
    'Algeria': 'DZ',
    'Tunisia': 'TN',
    'Libya': 'LY',
    'Ethiopia': 'ET',
    'Ghana': 'GH',
    'Tanzania': 'TZ',
    'Uganda': 'UG',
    'Zimbabwe': 'ZW',
    'Botswana': 'BW',
    'Namibia': 'NA',
    
    // Oceania
    'Australia': 'AU',
    'New Zealand': 'NZ',
    'Fiji': 'FJ',
    'Papua New Guinea': 'PG',
    
    // South America
    'Brazil': 'BR',
    'Argentina': 'AR',
    'Chile': 'CL',
    'Peru': 'PE',
    'Colombia': 'CO',
    'Venezuela': 'VE',
    'Ecuador': 'EC',
    'Bolivia': 'BO',
    'Paraguay': 'PY',
    'Uruguay': 'UY',
    'Guyana': 'GY',
    'Suriname': 'SR',
    
    // Central America & Caribbean
    'Guatemala': 'GT',
    'Belize': 'BZ',
    'El Salvador': 'SV',
    'Honduras': 'HN',
    'Nicaragua': 'NI',
    'Costa Rica': 'CR',
    'Panama': 'PA',
    'Jamaica': 'JM',
    'Cuba': 'CU',
    'Dominican Republic': 'DO',
    'Haiti': 'HT',
    'Trinidad and Tobago': 'TT',
    'Barbados': 'BB',
  };
  
  /// Get the ISO country code for a given country name
  /// Returns null if the country is not found in the mapping
  static String? getCountryCode(String countryName) {
    return _countryCodeMap[countryName];
  }
  
  /// Check if a country name has a mapping to ISO code
  static bool hasMapping(String countryName) {
    return _countryCodeMap.containsKey(countryName);
  }
  
  /// Get all supported countries
  static List<String> getSupportedCountries() {
    return _countryCodeMap.keys.toList()..sort();
  }
}