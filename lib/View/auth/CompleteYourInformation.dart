import 'package:flutter/material.dart';
import '../../Widgets/CustomAppBar.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import '../../Provider/SignupProvider.dart';
import '../../Widgets/CustomTextField.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';
import '../../core/utils/routes/routes.dart' show RoutesName;

class CompleteYourInformation extends StatefulWidget {
  const CompleteYourInformation({super.key});

  @override
  State<CompleteYourInformation> createState() =>
      _CompleteYourInformationState();
}

class _CompleteYourInformationState extends State<CompleteYourInformation> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = SignupProvider();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.loadExistingUserData();
        });
        return provider;
      },
      child: Scaffold(
        appBar: const CustomAppBar(),
        body: SafeArea(
          child: Consumer<SignupProvider>(
            builder: (context, signupProvider, child) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.screenWidth * 0.05,
                    vertical: context.screenHeight * 0.02,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete your Information',
                        style: pjsStyleBlack24700.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Please complete the missing required fields to continue using the app.',
                        style: pjsStyleBlack14400.copyWith(
                          color: AppColors.garyModern500,
                        ),
                      ),
                      const SizedBox(height: 30),

                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  signupProvider.pickImageFromGallery(),
                              child: DottedBorder(
                                borderType: BorderType.Circle,
                                dashPattern: const [8, 6],
                                color: AppColors.primary,
                                strokeWidth: 2,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                  ),
                                  child: signupProvider.profileImage != null
                                      ? ClipOval(
                                          child: Image.file(
                                            signupProvider.profileImage!,
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                          ),
                                        )
                                      : FutureBuilder<Map<String, dynamic>?>(
                                          future: signupProvider
                                              .getCurrentUserData(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData &&
                                                snapshot.data != null &&
                                                snapshot.data!['profileImageUrl'] !=
                                                    null) {
                                              return ClipOval(
                                                child: Image.network(
                                                  snapshot
                                                      .data!['profileImageUrl'],
                                                  fit: BoxFit.cover,
                                                  width: 120,
                                                  height: 120,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Icon(
                                                          Icons.camera_alt,
                                                          size: 40,
                                                          color: AppColors
                                                              .garyModern400,
                                                        );
                                                      },
                                                ),
                                              );
                                            }
                                            return Icon(
                                              Icons.camera_alt,
                                              size: 40,
                                              color: AppColors.garyModern400,
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Add Profile Picture',
                              style: pjsStyleBlack14500.copyWith(
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      CustomTextField(
                        label: 'Home City',
                        hintText: 'Enter your home city..',
                        controller: signupProvider.homeCityController,
                        focusNode: signupProvider.homeCityFocusNode,
                        onChanged: (_) {},
                      ),

                      const SizedBox(height: 20),
                      Text(
                        'Date of Birth',
                        style: pjsStyleBlack14500.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      buildDateField(context, signupProvider),
                      const SizedBox(height: 20),

                      // Nationality Dropdown
                      Text(
                        'Select Nationality',
                        style: pjsStyleBlack14500.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      buildNationalityDropdown(context, signupProvider),
                      const SizedBox(height: 20),
                      CustomTextField(
                        label: 'About',
                        hintText: 'Enter your about..',
                        controller: signupProvider.bioController,
                        focusNode: signupProvider.bioFocusNode,
                        onChanged: (_) {},
                      ),

                      const SizedBox(height: 30),

                      // Error Message Display
                      if (signupProvider.errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            signupProvider.errorMessage!,
                            style: pjsStyleBlack14400.copyWith(
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),

                      // Terms and Conditions
                      const SizedBox(height: 30),

                      CustomButton(
                        text: signupProvider.isLoading
                            ? 'Updating Profile...'
                            : 'Complete Profile',
                        onTap: signupProvider.isLoading
                            ? () {}
                            : () {
                                signupProvider.updateProfile().then((success) {
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Profile completed successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                    Navigator.pushReplacementNamed(
                                      context,
                                      RoutesName.homeMainScreen,
                                    );
                                  }
                                });
                              },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget buildDateField(BuildContext context, SignupProvider signupProvider) {
  return GestureDetector(
    onTap: () => selectDate(context, signupProvider),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.garyModern200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            signupProvider.dateOfBirthController.text.isEmpty
                ? '2000-11-24'
                : signupProvider.dateOfBirthController.text,
            style: pjsStyleBlack14400.copyWith(
              color: signupProvider.dateOfBirthController.text.isEmpty
                  ? AppColors.garyModern400
                  : AppColors.black,
            ),
          ),
          Icon(Icons.calendar_today, size: 20, color: AppColors.garyModern400),
        ],
      ),
    ),
  );
}

Widget buildNationalityDropdown(
  BuildContext context,
  SignupProvider signupProvider, {
  String? userNationality,
  VoidCallback? onChanged,
}) {
  return GestureDetector(
    onTap: () {
      showCountryPicker(
        context: context,
        showPhoneCode: false,
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
              borderSide: BorderSide(color: AppColors.garyModern200),
            ),
          ),
        ),
        onSelect: (Country country) {
          signupProvider.setNationality(country.name);
          onChanged?.call();
        },
      );
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.garyModern200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            signupProvider.selectedNationality.isNotEmpty
                ? signupProvider.selectedNationality
                : 'Select Nationality',
            style: pjsStyleBlack14400.copyWith(
              color: signupProvider.selectedNationality.isNotEmpty
                  ? AppColors.black
                  : AppColors.garyModern400,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
        ],
      ),
    ),
  );
}

Future<void> selectDate(
  BuildContext context,
  SignupProvider signupProvider,
) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: signupProvider.selectedDate ?? DateTime(2000, 11, 24),
    firstDate: DateTime(1950),
    lastDate: DateTime.now(),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.black,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null && picked != signupProvider.selectedDate) {
    signupProvider.setSelectedDate(picked);
  }
}
