import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:global_connect/core/const/app_images.dart';
import '../Widgets/CustomAppBar.dart';
import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:provider/provider.dart';
import '../Provider/ShareTipsScreenProvider.dart';
import '../core/utils/components/CustomButton.dart';

class ShareTipsScreen extends StatelessWidget {
  const ShareTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = MediaQuery.of(context).size.width * 0.06;
    return ChangeNotifierProvider(
      create: (_) => ShareTipsScreenProvider(),
      child: Scaffold(
        appBar: CustomAppBar2(
          title: Text(
            'Share Your Tip',
            style: pjsStyleBlack18600.copyWith(color: AppColors.black),
          ),
        ),
        body: Consumer<ShareTipsScreenProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Share a Travel Tip', style: pjsStyleBlack16600),
                  Text(
                    'Help fellow travelers by sharing your local insights and recommendations.',
                    style: pjsStyleBlack12500.copyWith(
                      color: AppColors.garyModern400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label('Tip Title'),
                  roundedCard(
                    child: TextField(
                      controller: provider.titleController,
                      style: pjsStyleBlack14400.copyWith(
                        color: AppColors.garyModern400,
                      ),
                      decoration: _inputDecoration(
                        'Give your tip a catchy title',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label('Tip Category'),
                  roundedCard(
                    child:  Theme(
                      data: Theme.of(context).copyWith(
                        focusColor: AppColors.primary,
                        hoverColor: AppColors.primary.withOpacity(0.05),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: AppColors.white,
                          value: provider.selectedCategory,
                          isExpanded: true,
                          hint: Text(
                            'Select a category..',
                            style: pjsStyleBlack14400.copyWith(
                              color: AppColors.garyModern400,
                            ),
                          ),
                          icon: SvgPicture.asset(AppImages.downButton,  color: AppColors.primary),
                          items: [
                            'All Categories',
                            'Restaurants',
                            'Nightlife',
                            'Sightseeing',
                            'Shopping',
                            'Transportation',
                            'Accommodation',
                            'Safety',
                            'Cultural',
                            'Other',
                            'Food',
                            'Warning',
                            'Tip',
                            'Life hack',
                          ]
                              .map<DropdownMenuItem<String>>((String item) {
                            return DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                style: pjsStyleBlack14400.copyWith(
                                  color: AppColors.black,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: provider.setCategory,
                        ),
                      ),
                    ),
                  ),


                  const SizedBox(height: 18),
                  Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Country'),
                            GestureDetector(
                              onTap: () => provider.selectCountry(context),
                              child: roundedCard(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        provider.countryController.text.isEmpty
                                            ? 'Select country'
                                            : provider.countryController.text,
                                        style: pjsStyleBlack14400.copyWith(
                                          color: provider.countryController.text.isEmpty
                                              ? AppColors.garyModern400
                                              : AppColors.black,
                                        ),
                                      ),
                                    ),
                                    SvgPicture.asset(AppImages.downButton,
                                        color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('City'),
                            roundedCard(
                              child: TextField(
                                controller: provider.cityController,
                                style: pjsStyleBlack14400.copyWith(
                                  color: AppColors.black,
                                ),
                                decoration: _inputDecoration('e.g., Paris'),
                                onChanged: provider.selectedCountry != null
                                    ? provider.searchCity
                                    : null,
                                enabled: provider.selectedCountry != null,
                              ),
                            ),
                            if (provider.citySuggestions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.garyModern200,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: provider.citySuggestions.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: AppColors.garyModern200,
                                  ),
                                  itemBuilder: (context, index) {
                                    final suggestion =
                                        provider.citySuggestions[index];
                                    return ListTile(
                                      title: Text(
                                        suggestion,
                                        style: pjsStyleBlack14400.copyWith(
                                          color: AppColors.black,
                                        ),
                                      ),
                                      onTap: () => provider.selectCity(suggestion),
                                      dense: true,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // const SizedBox(height: 18),
                  // _label('Restaurant Name (Optional)'),
                  // roundedCard(
                  //   child: TextField(
                  //     controller: provider.restaurantController,
                  //     style: pjsStyleBlack14400.copyWith(
                  //       color: AppColors.black,
                  //     ),
                  //     decoration: _inputDecoration(
                  //       'e.g., La Petite Maison',
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 18),
                  _label('Address'),
                  roundedCard(
                    child: TextField(
                      controller: provider.addressController,
                      style: pjsStyleBlack14400.copyWith(
                        color: AppColors.black,
                      ),
                      decoration: _inputDecoration(
                        'e.g., 123 Main Street',
                      ),
                      onChanged: provider.selectedCountry != null
                          ? provider.searchAddress
                          : null,
                      enabled: provider.selectedCountry != null,
                    ),
                  ),
                  if (provider.addressSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.garyModern200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.addressSuggestions.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: AppColors.garyModern200,
                        ),
                        itemBuilder: (context, index) {
                          final suggestion = provider.addressSuggestions[index];
                          return ListTile(
                            title: Text(
                              suggestion,
                              style: pjsStyleBlack14400.copyWith(
                                color: AppColors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => provider.selectAddress(suggestion),
                            dense: true,
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 18),
                  // Your Tip
                  _label('Your Tip'),
                  roundedCard(
                    child: TextField(
                      controller: provider.tipController,
                      maxLines: 4,
                      minLines: 3,
                      style: pjsStyleBlack14400.copyWith(
                        color: AppColors.black,
                      ),
                      decoration: _inputDecoration('Enter your tip..'),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Save Draft & Share Tip Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: provider.isSavingDraft
                              ? null
                              : () => provider.saveDraft(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: provider.isSavingDraft
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Cancel',
                                  style: pjsStyleBlack19700.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Share Tip',
                          onTap: () => provider.shareTip(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(
      text,
      style: pjsStyleBlack14500.copyWith(color: AppColors.black),
    ),
  );

  Widget roundedCard({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.garyModern200),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: child,
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: pjsStyleBlack12400.copyWith(
      color: AppColors.darkGrey.withOpacity(0.5),
    ),
    border: InputBorder.none,
    isDense: true,
    contentPadding: EdgeInsets.zero,
  );

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderShad),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: pjsStyleBlack14500.copyWith(color: AppColors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: pjsStyleBlack12500.copyWith(
                    color: AppColors.garyModern400,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

}
