import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;
  
  PlaceSuggestion({
    required this.placeId,
    required this.description,
  });
  
  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class CitySearchField extends StatefulWidget {
  final String label;
  final String hintText;
  final Function(String)? onCitySelected;
  final String? initialValue;
  final TextEditingController? controller;
  final String? countryCode; // ISO country code to restrict search
  
  const CitySearchField({
    Key? key,
    required this.label,
    required this.hintText,
    this.onCitySelected,
    this.initialValue,
    this.controller,
    this.countryCode,
  }) : super(key: key);

  @override
  State<CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends State<CitySearchField> {
  late TextEditingController _controller;
  List<PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || query.length < 2) {
      setState(() {
        _suggestions.clear();
        _isSearching = false;
      });
      return;
    }

    // Debounce the search to avoid too many API calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isSearching = true;
      });

      try {
        final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
        if (apiKey.isEmpty) {
          print('Google Maps API Key not found in .env file');
          setState(() {
            _suggestions.clear();
            _isSearching = false;
          });
          return;
        }

        // Build the API URL
        String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=${Uri.encodeComponent(query)}'
            '&types=(cities)'
            '&language=en'
            '&key=$apiKey';
        
        // Add country restriction if provided
        if (widget.countryCode != null) {
          url += '&components=country:${widget.countryCode}';
        }

        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final predictions = data['predictions'] as List;
            setState(() {
              _suggestions = predictions
                  .map<PlaceSuggestion>((json) => PlaceSuggestion.fromJson(json))
                  .toList();
              _isSearching = false;
            });
          } else {
            print('Places API Error: ${data['status']} - ${data['error_message'] ?? ''}');
            setState(() {
              _suggestions.clear();
              _isSearching = false;
            });
          }
        } else {
          print('HTTP Error: ${response.statusCode}');
          setState(() {
            _suggestions.clear();
            _isSearching = false;
          });
        }
      } catch (e) {
        print('Error searching places: $e');
        setState(() {
          _suggestions.clear();
          _isSearching = false;
        });
      }
    });
  }

  void _selectPlace(PlaceSuggestion suggestion) {
    _controller.text = suggestion.description;
    setState(() {
      _suggestions.clear();
    });
    _focusNode.unfocus();
    
    if (widget.onCitySelected != null) {
      widget.onCitySelected!(suggestion.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: pjsStyleBlack14500.copyWith(color: AppColors.black),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.garyModern200),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: pjsStyleBlack14400.copyWith(color: AppColors.garyModern400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: _isSearching 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search, color: AppColors.garyModern400),
                ),
                style: pjsStyleBlack14400.copyWith(color: AppColors.black),
                onChanged: _searchPlaces,
              ),
              if (_suggestions.isNotEmpty)
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.garyModern200),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_city,
                            color: AppColors.garyModern400,
                            size: 20,
                          ),
                          title: Text(
                            suggestion.description,
                            style: pjsStyleBlack14400.copyWith(color: AppColors.black),
                          ),
                          onTap: () => _selectPlace(suggestion),
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}