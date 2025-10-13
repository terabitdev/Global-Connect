import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/CustomTextField.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/const/custamSnackBar.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';
import '../../core/utils/routes/routes.dart';
import '../../Provider/LoginProvider.dart';
import '../../Provider/LocationProvider.dart';
import '../../Provider/user_profile_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoginProvider(),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Scaffold(
          appBar: const CustomAppBar(),
          body: Consumer<LoginProvider>(
            builder: (context, loginProvider, child) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.screenWidth * 0.05,
                  vertical: context.screenHeight * 0.02,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        context.screenHeight -
                        (context.screenHeight * 0.15) -
                        MediaQuery.of(context).padding.top -
                        kToolbarHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: pjsStyleBlack24700.copyWith(color: AppColors.black),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Enter your registered account to sign in',
                          style: pjsStyleBlack14400.copyWith(
                            color: AppColors.garyModern500,
                          ),
                        ),
                        const SizedBox(height: 30),

                        CustomTextField(
                          label: 'Email',
                          hintText: 'Enter your email address..',
                          controller: loginProvider.emailController,
                          focusNode: loginProvider.emailFocusNode,
                          nextFocusNode: loginProvider.passwordFocusNode,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        CustomTextField(
                          label: 'Password',
                          hintText: 'Enter your password..',
                          controller: loginProvider.passwordController,
                          focusNode: loginProvider.passwordFocusNode,
                          isPassword: true,
                          isPasswordVisible: loginProvider.isPasswordVisible,
                          togglePasswordVisibility: loginProvider.togglePasswordVisibility,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RoutesName.forgotPasswordScreen,
                                );
                              },
                              child: Text(
                                'Forgot password?',
                                style: pjsStyleBlack14500.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Error Message Display
                        if (loginProvider.errorMessage != null)
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
                              loginProvider.errorMessage!,
                              style: pjsStyleBlack14400.copyWith(
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),

                        CustomButton(
                          text: loginProvider.isLoading ? 'Signing In...' : 'Sign In',
                          onTap: loginProvider.isLoading
                              ? () {}
                              : () async {
                            final result = await loginProvider.signIn();
                            final success = result['success'] as bool;
                            final profileComplete = result['profileComplete'] as bool;

                            if (success && mounted) {
                              // Initialize location providers after successful login
                              final locationProvider = context.read<LocationProvider>();
                              final userProfileProvider = context.read<UserProfileProvider>();

                              // Ensure UserProfileProvider starts listening to current user
                              userProfileProvider.listenToCurrentUser();

                              if (profileComplete) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  RoutesName.homeMainScreen,
                                );
                                CustomSnackBar.showSuccess(context, 'Sign In Successfully');
                              } else {
                                // Navigate to profile completion screen
                                Navigator.pushReplacementNamed(
                                  context,
                                  RoutesName.completeYourInformation,
                                );
                                CustomSnackBar.showSuccess(context, 'Please complete your profile');
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(thickness: 1, color: AppColors.input),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Or continue with',
                                style: pjsStyleBlack14400.copyWith(
                                  color: AppColors.garyModern500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(thickness: 1, color: AppColors.input),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Center(
                          child: GestureDetector(
                            onTap: loginProvider.isGoogleLoading
                                ? null
                                : () async {
                              final result = await loginProvider.signInWithGoogle();
                              final success = result['success'] as bool;
                              final profileComplete = result['profileComplete'] as bool;

                              if (success && mounted) {
                                // Initialize location providers after successful Google login
                                final locationProvider = context.read<LocationProvider>();
                                final userProfileProvider = context.read<UserProfileProvider>();

                                // Ensure UserProfileProvider starts listening to current user
                                userProfileProvider.listenToCurrentUser();

                                if (profileComplete) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    RoutesName.homeMainScreen,
                                  );
                                  CustomSnackBar.showSuccess(context, 'Sign In Successfully');
                                } else {
                                  // Navigate to profile completion screen
                                  Navigator.pushReplacementNamed(
                                    context,
                                    RoutesName.completeYourInformation,
                                  );
                                  CustomSnackBar.showSuccess(context, 'Please complete your profile');
                                }
                              }
                            },
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: loginProvider.isGoogleLoading
                                    ? AppColors.input.withOpacity(0.5)
                                    : Colors.transparent,
                              ),
                              child: loginProvider.isGoogleLoading
                                  ? const Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                              )
                                  : SvgPicture.asset(
                                AppImages.google,
                                height: 50,
                                width: 50,
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, RoutesName.signupScreen);
                          },
                          child: Center(
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have any account? ",
                                style: pjsStyleBlack14500.copyWith(
                                  color: AppColors.black,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: pjsStyleBlack14500.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: context.screenHeight * 0.05),
                      ],
                    ),
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
