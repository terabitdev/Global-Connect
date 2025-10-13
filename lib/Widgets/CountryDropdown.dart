import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/core/const/app_images.dart';
import 'package:provider/provider.dart';
import '../Provider/CountryProvider.dart';
import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';

class CountryDropdown extends StatelessWidget {
  final String label;
  final String hintText;
  final Function(String)? onCountrySelected;
  final String? initialValue;
  final String uniqueKey;
  
  const CountryDropdown({
    Key? key,
    required this.label,
    required this.hintText,
    required this.uniqueKey,
    this.onCountrySelected,
    this.initialValue,
  }) : super(key: key);

  void _showCountryPicker(BuildContext context, CountryProvider countryProvider) {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        countryProvider.selectCountry(uniqueKey, country);
        if (onCountrySelected != null) {
          onCountrySelected!(country.name);
        }
      },
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.garyModern200,
            ),
          ),
        ),
        backgroundColor: AppColors.white,
        searchTextStyle: pjsStyleBlack14400.copyWith(color: AppColors.black),
        textStyle: pjsStyleBlack14400.copyWith(color: AppColors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CountryProvider>(
      builder: (context, countryProvider, child) {
        final selectedCountry = countryProvider.getSelectedCountry(uniqueKey) ?? initialValue;
        final selectedCountryFlag = countryProvider.getSelectedCountryFlag(uniqueKey);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: pjsStyleBlack14500.copyWith(color: AppColors.black),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showCountryPicker(context, countryProvider),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.garyModern200),
                  color: AppColors.white,
                ),
                child: Row(
                  children: [
                    if (selectedCountryFlag != null) ...[
                      Text(
                        selectedCountryFlag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        selectedCountry ?? hintText,
                        style: pjsStyleBlack14400.copyWith(
                          color: selectedCountry != null 
                              ? AppColors.black 
                              : AppColors.garyModern400,
                        ),
                      ),
                    ),
                    SvgPicture.asset(
                     AppImages.dropDown,
                      width: 10,
                      height: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}