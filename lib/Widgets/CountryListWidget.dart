import 'package:flutter/material.dart';
import '../Provider/AddCountriesProvider.dart';
import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';
import '../core/utils/components/CustomButton.dart';

class CountryListWidget extends StatelessWidget {
  final AddCountriesProvider provider;

  const CountryListWidget({
    super.key,
    required this.provider,
  });

  void _showMessage(BuildContext context, String message, {bool isError = false}) {
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
    return Expanded(
      child: RawScrollbar(
        thumbVisibility: true,
        thickness: 4,
        minThumbLength: 100,
        radius: Radius.circular(20),
        thumbColor: AppColors.primary,
        trackColor: AppColors.primary.withValues(alpha: 0.20),
        trackRadius: Radius.circular(20),
        child: ListView.builder(
          itemCount: provider.filteredCountries.length,
          itemBuilder: (context, index) {
            final country = provider.filteredCountries[index];
            final isBeingAdded = provider.isCountryBeingAdded(country['name']!);

            return ListTile(
              leading: Text(
                country['flag']!,
                style: const TextStyle(fontSize: 20),
              ),
              title: Text(
                country['name']!,
                style: pjsStyleBlack14400,
              ),
              subtitle: Text(
                country['continent']!,
                style: pjsStyleBlack12400.copyWith(
                  color: AppColors.garyModern400,
                ),
              ),
              trailing: SizedBox(
                width: 60,
                child: CustomButton(
                  backgroundColor: isBeingAdded ? AppColors.garyModern200 : AppColors.white,
                  borderColor: isBeingAdded ? AppColors.garyModern200 : AppColors.primary,
                  textColor: isBeingAdded ? AppColors.garyModern400 : AppColors.primary,
                  height: 25,
                  text: isBeingAdded ? 'Adding...' : 'Add',
                  onTap: isBeingAdded ? null : () async {
                    final result = await provider.addCountry(
                      country['name']!,
                      country['flag']!,
                    );
                    if (context.mounted) {
                      _showMessage(
                        context,
                        result,
                        isError: !result.contains('successfully'),
                      );
                    }
                  },
                ),
              ),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
            );
          },
        ),
      ),
    );
  }
}