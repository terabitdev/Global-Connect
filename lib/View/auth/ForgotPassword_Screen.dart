import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:global_connect/core/const/responsive_layout.dart';

import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/CustomTextField.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';
import '../../Provider/ForgotPasswordProvider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ForgotPasswordProvider(),
      child: Scaffold(
        appBar: const CustomAppBar(),
        body: Consumer<ForgotPasswordProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.screenWidth * 0.05,
                vertical: context.screenHeight * 0.02,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Forgot Password',
                    style: pjsStyleBlack24700.copyWith(color: AppColors.black),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'We will send you an email to reset your password',
                    style: pjsStyleBlack14400.copyWith(
                      color: AppColors.garyModern500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: provider.emailController,
                    focusNode: provider.emailFocusNode,
                    label: 'Email',
                    hintText: 'Enter your email address..',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      // Trigger validation on change
                      provider.notifyListeners();
                    },
                  ),
                  // // Email validation error
                  // if (provider.getEmailError() != null)
                  //   Padding(
                  //     padding: const EdgeInsets.only(top: 8),
                  //     child: Text(
                  //       provider.getEmailError()!,
                  //       style: pjsStyleBlack14400.copyWith(
                  //         color: Colors.red.shade700,
                  //       ),
                  //     ),
                  //   ),
                  const SizedBox(height: 16),
                  
                  // Error message
                  if (provider.errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        provider.errorMessage!,
                        style: pjsStyleBlack14400.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  
                  // Success message
                  if (provider.successMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        provider.successMessage!,
                        style: pjsStyleBlack14400.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  
                  CustomButton(
                    text: provider.isLoading ? 'Sending...' : 'Send Email',
                    onTap: provider.isLoading 
                        ? () {} 
                        : () {
                                                    provider.sendPasswordResetEmail().then((success) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.successMessage ?? 'Password reset email sent successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        });
                          },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
