import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:global_connect/core/utils/components/CustomButton.dart';
import 'package:provider/provider.dart';
import '../../Provider/SignupProvider.dart';
import '../../Provider/user_profile_provider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/CustomTextField.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
import '../auth/signUp_screen.dart';
import 'dart:io';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  File? _selectedImage;
  DateTime? _selectedDate;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().listenToCurrentUser();
    });
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _hasChanges = true;
      });
      context.read<SignupProvider>().setSelectedDate(picked);
    }
  }

  Future<void> _pickImage() async {
    final File? image = await context.read<UserProfileProvider>().pickImageFromGallery();
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    final userProfileProvider = context.read<UserProfileProvider>();
    final signupProvider = context.read<SignupProvider>();

    // Get current values
    final currentUser = userProfileProvider.currentUser;
    if (currentUser == null) return;

    // Prepare update data
    String fullName = signupProvider.fullNameController.text.trim();
    String homeCity = signupProvider.homeCityController.text.trim();
    String bio = signupProvider.bioController.text.trim();
    String nationality = signupProvider.selectedNationality;
    String email = signupProvider.emailController.text.trim();

    // Use original values if empty
    if (fullName.isEmpty) fullName = currentUser.fullName ?? '';
    if (homeCity.isEmpty) homeCity = currentUser.homeCity ?? '';
    if (bio.isEmpty) bio = currentUser.bio ?? '';
    if (nationality.isEmpty) nationality = currentUser.nationality;
    if (email.isEmpty) email = currentUser.email ?? '';

    // Check if any changes were made
    bool hasChanges = _hasChanges ||
                     (fullName != currentUser.fullName) ||
                     (homeCity != currentUser.homeCity) ||
                     (bio != currentUser.bio) ||
                     (_selectedDate != null && _selectedDate != currentUser.dateOfBirth) ||
                     _selectedImage != null ||
                     (nationality != currentUser.nationality) ||
                     (email != currentUser.email);

    if (!hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save')),
      );
      return;
    }

    // Check if email changed and get password if needed
    String? password;
    if (email != currentUser.email) {
      password = await _showPasswordDialog();
      if (password == null || password.isEmpty) {
        // User cancelled or didn't provide password
        return;
      }
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final success = await userProfileProvider.updateUserProfile(
        fullName: fullName,
        dateOfBirth: _selectedDate,
        homeCity: homeCity,
        bio: bio,
        newProfileImage: _selectedImage,
        nationality: nationality,
        email: email,
        password: password,
      );

      Navigator.of(context).pop();

      if (success) {
        setState(() {
          _hasChanges = false;
          _selectedImage = null;
        });

        // Check if there's a specific message about email verification
        if (userProfileProvider.error != null && userProfileProvider.error!.contains('Verification email sent')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userProfileProvider.error!),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProfileProvider.error ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showPasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title:  Text('Confirm Password',style: pStyleBlack14500,),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text('To update your email address, please enter your current password',style: pStyleBlack12400),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Password',
              hintText: 'Enter your password..',
              controller: passwordController,
              enabled: true,

            ),
          ],
        ),
        actions: [
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: CustomButton3(
                  text: 'Cancel',
                  onTap: () {
                    Navigator.of(context).pop(null);
                  },
                ),
              ),
              Expanded(
                child: CustomButton(
                  text: 'Confirm',
                  onTap: () {
                    final password = passwordController.text.trim();
                    Navigator.of(context).pop(password.isNotEmpty ? password : null);
                  },
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      top: false,
      child: Scaffold(
        appBar: CustomAppBar2(
          title: Text(
            'Personal Data',
            style: pjsStyleBlack18600.copyWith(color: AppColors.black),
          ),

        ),
        body: Consumer2<SignupProvider, UserProfileProvider>(
          builder: (context, signupProvider, userProfileProvider, child) {
            final user = userProfileProvider.currentUser;
            if (user == null) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: context.screenHeight * 0.035,
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            // Initialize form fields with user data
            if (!_hasChanges) {
              signupProvider.fullNameController.text = user.fullName ?? '';
              signupProvider.countryController.text = userProfileProvider.currentCountry ?? '';
              signupProvider.dateOfBirthController.text = userProfileProvider.calculateAge() ?? '';
              signupProvider.homeCityController.text = user.homeCity ?? '';
              signupProvider.emailController.text = user.email ?? '';
              signupProvider.bioController.text = user.bio ?? '';
              _selectedDate = user.dateOfBirth;
              // Always sync nationality with current user's nationality
              if (user.nationality != null && user.nationality.isNotEmpty) {
                signupProvider.setNationality(user.nationality);
              } else {
                signupProvider.setNationality('Pakistani');
              }
            }

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.screenWidth * 0.05,
                vertical: context.screenHeight * 0.02,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                DottedBorder(
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
                                    child: _selectedImage != null
                                        ? ClipOval(
                                            child: Image.file(
                                              _selectedImage!,
                                              fit: BoxFit.cover,
                                              width: 120,
                                              height: 120,
                                            ),
                                          )
                                        : (user.profileImageUrl != null &&
                                              user.profileImageUrl!.isNotEmpty)
                                        ? ClipOval(
                                            child: Image.network(
                                              user.profileImageUrl!,
                                              fit: BoxFit.cover,
                                              width: 120,
                                              height: 120,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.camera_alt,
                                                      size: 40,
                                                      color:
                                                          AppColors.garyModern400,
                                                    );
                                                  },
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            size: 40,
                                            color: AppColors.garyModern400,
                                          ),
                                  ),
                                ),
                                // Edit icon overlay
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.screenHeight * 0.03),

                    CustomTextField(
                      label: 'Full Name',
                      hintText: 'Enter your full name..',
                      controller: signupProvider.fullNameController,
                      enabled: true,
                      onChanged: (value) {
                        setState(() {
                          _hasChanges = true;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      label: 'Email',
                      hintText: 'Enter your email..',
                      controller: signupProvider.emailController,
                      enabled: true,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        setState(() {
                          _hasChanges = true;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      label: 'Country',
                      hintText: 'Enter your Country..',
                      controller: signupProvider.countryController,
                      enabled: false,
                    ),
                    // SizedBox(height: 16),
                    // CustomTextField(
                    //   label: 'Age',
                    //   hintText: 'Enter your Age..',
                    //   controller: signupProvider.dateOfBirthController,
                    //   enabled: false,
                    // ),
                    SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: CustomTextField(
                          label: 'Date of Birth',
                          hintText: 'Select your Date of Birth..',
                          controller: signupProvider.dateOfBirthController,
                          suffixIcon: Icon(
                            Icons.calendar_today,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Select Nationality',
                      style: pjsStyleBlack14500.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    buildNationalityDropdown(context, signupProvider, userNationality: user.nationality, onChanged: () {
                      setState(() {
                        _hasChanges = true;
                      });
                    }),
                    SizedBox(height: 16),
                    CustomTextField(
                      label: 'Current Homecity',
                      hintText: 'Enter your Current Homecity..',
                      controller: signupProvider.homeCityController,
                      onChanged: (value) {
                        setState(() {
                          _hasChanges = true;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      label: 'Bio',
                      hintText: 'Enter your Bio..',
                      minLines: 3,
                      maxLines: 10,
                      controller: signupProvider.bioController,
                      onChanged: (value) {
                        setState(() {
                          _hasChanges = true;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    CustomButton(
                      text: 'Save Changes',
                      onTap: _saveChanges,
                    ),
                      SizedBox(height: 16),

                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
