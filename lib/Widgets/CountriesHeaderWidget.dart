import 'package:flutter/material.dart';
import '../Provider/AddCountriesProvider.dart';
import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';
import '../core/utils/components/CustomButton.dart';

class CountriesHeaderWidget extends StatelessWidget {
  final AddCountriesProvider provider;
  final TextEditingController searchController;
  final VoidCallback onClosePressed;

  const CountriesHeaderWidget({
    super.key,
    required this.provider,
    required this.searchController,
    required this.onClosePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        // Title and counter row
        Row(
          spacing: 10,
          children: [
            Text(
              'Your Countries',
              style: pjsStyleBlack14700.copyWith(color: AppColors.primary),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                child: Center(
                  child: Text(
                    '${provider.addedCountriesCount}/${provider.allCountries.length}',
                    style: pjsStyleBlack12600.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Description and close button row
        Row(
          children: [
            Expanded(
              child: Text(
                'Click countries on the map or search below to\n manage your list',
                style: pjsStyleBlack12400.copyWith(
                  color: AppColors.garyModern400,
                ),
              ),
            ),
            GestureDetector(
              onTap: onClosePressed,
              child: Icon(
                Icons.close,
                color: AppColors.black,
                size: 25,
              ),
            ),
          ],
        ),
        // Add countries and toggle button row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                spacing: 5,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add new countries',
                    style: pjsStyleBlack13600.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomButton(
                iconSize: 15,
                text: provider.isSearchVisible ? 'Hide Search' : 'Show Search',
                onTap: () {
                  provider.toggleSearchVisibility();
                  if (!provider.isSearchVisible) {
                    searchController.clear();
                    provider.updateSearchText('');
                  }
                },
                height: 30,
              ),
            ),
          ],
        ),
      ],
    );
  }
}