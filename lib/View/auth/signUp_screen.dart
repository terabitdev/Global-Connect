import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';

import '../../Provider/SignupProvider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/CustomTextField.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';
import '../../core/utils/routes/routes.dart' show RoutesName;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SignupProvider(),
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
                        'Create an Account',
                        style: pjsStyleBlack24700.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Join us today and unlock endless possibilities. It\'s quick, easy, and just a step away!',
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
                                      : Icon(
                                          Icons.camera_alt,
                                          size: 40,
                                          color: AppColors.garyModern400,
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
                        label: 'Email',
                        hintText: 'Enter your email',
                        controller: signupProvider.emailController,
                        focusNode: signupProvider.emailFocusNode,
                        nextFocusNode: signupProvider.passwordFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        // Optionally add validator: signupProvider.validateEmail,
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      CustomTextField(
                        label: 'Password',
                        hintText: 'Enter your password',
                        controller: signupProvider.passwordController,
                        focusNode: signupProvider.passwordFocusNode,
                        nextFocusNode: signupProvider.confirmPasswordFocusNode,
                        isPassword: true,
                        isPasswordVisible: signupProvider.isPasswordVisible,
                        togglePasswordVisibility:
                            signupProvider.togglePasswordVisibility,
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password Field
                      CustomTextField(
                        label: 'Confirm Password',
                        hintText: 'Confirm your password',
                        controller: signupProvider.confirmPasswordController,
                        focusNode: signupProvider.confirmPasswordFocusNode,
                        isPassword: true,
                        nextFocusNode: signupProvider.fullNameFocusNode,
                        isPasswordVisible:
                            signupProvider.isConfirmPasswordVisible,
                        togglePasswordVisibility:
                            signupProvider.toggleConfirmPasswordVisibility,
                      ),
                      const SizedBox(height: 20),

                      // Full Name Field
                      CustomTextField(
                        label: 'Full Name',
                        hintText: 'Enter your full name',
                        controller: signupProvider.fullNameController,
                        focusNode: signupProvider.fullNameFocusNode,
                        nextFocusNode: signupProvider.homeCityFocusNode,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 20),
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
                        minLines: 1,
                        maxLines: 5,
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => signupProvider.toggleTermsAcceptance(),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: signupProvider.isTermsAccepted
                                    ? AppColors.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: signupProvider.isTermsAccepted
                                      ? AppColors.primary
                                      : AppColors.primary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: signupProvider.isTermsAccepted
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text:
                                    'By creating an account, you agree to our ',
                                style: pjsStyleBlack14400.copyWith(
                                  color: AppColors.black,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Terms and Conditions',
                                    style: pjsStyleBlack12400.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' and ',
                                    style: pjsStyleBlack12400.copyWith(
                                      color: AppColors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Privacy Notice',
                                    style: pjsStyleBlack12400.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '.',
                                    style: pjsStyleBlack12400.copyWith(
                                      color: AppColors.garyModern500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      CustomButton(
                        text: signupProvider.isLoading
                            ? 'Creating Account...'
                            : 'Sign Up',
                        onTap: signupProvider.isLoading
                            ? () {}
                            : () {
                                signupProvider.signUp().then((success) {
                                  if (success) {
                                    final userModel = signupProvider
                                        .createUserModelFromForm();
                                    if (userModel != null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Welcome ${userModel.fullName}! Account created successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Account created successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                    Navigator.pushNamed(
                                      context,
                                      RoutesName.loginScreen,
                                    );
                                  }
                                });
                              },
                      ),
                      const SizedBox(height: 20),

                      // Already have account
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: pjsStyleBlack14500.copyWith(
                              color: AppColors.black,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: pjsStyleBlack14600.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
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
