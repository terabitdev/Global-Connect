import 'package:flutter/material.dart';
import '../Provider/AddCountriesProvider.dart';
import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';

class ContinentFiltersWidget extends StatelessWidget {
  final AddCountriesProvider provider;

  const ContinentFiltersWidget({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // First row: All, Africa, Asia, Europe
        Row(
          spacing: 8,
          children: ['All', 'Africa', 'Asia', 'Europe'].map((continent) {
            return Expanded(child: _buildFilterButton(continent));
          }).toList(),
        ),
        SizedBox(height: 8),
        // Second row: North America, Oceania, South America
        Row(
          spacing: 8,
          children: ['North America', 'Oceania', 'South America'].map((continent) {
            return Expanded(child: _buildFilterButton(continent));
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String continent) {
    final bool isSelected = provider.selectedContinent == continent;

    return GestureDetector(
      onTap: () {
        provider.setSelectedContinent(continent);
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.primary,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            continent,
            style: pjsStyleBlack12600.copyWith(
              color: isSelected ? AppColors.white : AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}