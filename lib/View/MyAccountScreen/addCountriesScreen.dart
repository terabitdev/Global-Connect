import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/Widgets/CustomSearchBar.dart';
import 'package:global_connect/core/const/app_images.dart';
import 'package:global_connect/core/theme/app_text_style.dart';
import 'package:provider/provider.dart';
import '../../Provider/AddCountriesProvider.dart';
import '../../Widgets/ContinentFiltersWidget.dart';
import '../../Widgets/CountriesHeaderWidget.dart';
import '../../Widgets/CountryListWidget.dart';
import '../../core/const/app_color.dart';
import '../../core/utils/components/CustomButton.dart';

class AddCountriesScreen extends StatelessWidget {
  const AddCountriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AddCountriesProvider(),
      child: const _AddCountriesScreenContent(),
    );
  }
}

class _AddCountriesScreenContent extends StatefulWidget {
  const _AddCountriesScreenContent();

  @override
  State<_AddCountriesScreenContent> createState() =>
      _AddCountriesScreenContentState();
}

class _AddCountriesScreenContentState
    extends State<_AddCountriesScreenContent> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddCountriesProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              spacing: 10,
              children: [
                CountriesHeaderWidget(
                  provider: provider,
                  searchController: _searchController,
                  onClosePressed: () => Navigator.pop(context),
                ),

                // Search bar
                if (provider.isSearchVisible)
                  CustomSearchBar(
                    controller: _searchController,
                    hintText: 'Search countries',
                    onChanged: (value) {
                      provider.updateSearchText(value);
                    },
                  ),
                if (provider.isSearchVisible)
                  ContinentFiltersWidget(provider: provider),

                // Countries search results
                if (provider.isSearchVisible &&
                    provider.filteredCountries.isNotEmpty)
                  CountryListWidget(provider: provider),

                // Divider
                Divider(thickness: 2, color: AppColors.garyModern200),

                // Added countries section
                Expanded(child: _buildAddedCountriesSection(provider)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddedCountriesSection(AddCountriesProvider provider) {
    if (provider.addedCountries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              AppImages.word,
              color: AppColors.primary,
              height: 30,
              width: 30,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'No countries added yet. Click on the map or\n search above to start adding countries.',
                style: pjsStyleBlack12500.copyWith(color: AppColors.darkGrey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with total count
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Added Countries (${provider.addedCountriesCount})',
            style: pjsStyleBlack14500,
          ),
        ),

        // Countries grouped by region
        Expanded(
          child: ListView.builder(
            itemCount: provider.addedCountriesByRegion.keys.length,
            itemBuilder: (context, index) {
              final region = provider.addedCountriesByRegion.keys.elementAt(
                index,
              );
              final countries = provider.addedCountriesByRegion[region]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Region header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      spacing: 10,
                      children: [
                        Text(
                          region,
                          style: pjsStyleBlack10500.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            '${countries.length}',
                            style: psjStyleBlack10500.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Countries in this region
                  ...countries.map(
                    (country) => _buildAddedCountryTile(provider, country),
                  ),

                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddedCountryTile(
    AddCountriesProvider provider,
    Map<String, dynamic> country,
  ) {
    final isBeingRemoved = provider.isCountryBeingRemoved(country['id']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Text(country['flag'], style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    country['name'],
                    style: pjsStyleBlack10500.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomButton(
              backgroundColor: isBeingRemoved
                  ? AppColors.garyModern200
                  : AppColors.white,
              textColor: isBeingRemoved
                  ? AppColors.garyModern400
                  : AppColors.primary,
              borderColor: isBeingRemoved
                  ? AppColors.garyModern200
                  : AppColors.primary,
              height: 25,
              text: isBeingRemoved ? 'Removing...' : 'Remove',
              onTap: isBeingRemoved
                  ? null
                  : () async {
                      final result = await provider.removeCountry(
                        country['id'],
                      );
                      if (mounted) {
                        _showMessage(
                          result,
                          isError: !result.contains('successfully'),
                        );
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}
