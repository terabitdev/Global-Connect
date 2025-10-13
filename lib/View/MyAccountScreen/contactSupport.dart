import 'package:flutter/material.dart';
import 'package:global_connect/Provider/ContactSupportProvider.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';

import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/CustomTextField.dart';
import '../../core/const/app_color.dart' show AppColors;
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';

class ContactSupport extends StatelessWidget {
  const ContactSupport({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContactSupportProvider(),
      child: Consumer<ContactSupportProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: CustomAppBar2(
              title: Text(
                'Contact Support',
                style: pjsStyleBlack18600.copyWith(color: AppColors.black),
              ),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.screenWidth * 0.05,
                  vertical: context.screenHeight * 0.02,
                ),
                child: Form(
                  key: provider.formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: provider.nameController,
                        label: 'Full Name',
                        hintText: 'Enter your full name..',
                        validator: provider.validateName,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: provider.emailController,
                        label: 'Email',
                        hintText: 'Enter your email address..',
                        keyboardType: TextInputType.emailAddress,
                        validator: provider.validateEmail,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: provider.messageController,
                        label: 'Message',
                        hintText: 'Enter feedback message..',
                        minLines: 3,
                        maxLines: 50,
                        validator: provider.validateMessage,
                      ),
                      const SizedBox(height: 16),
                      provider.isLoading
                          ? const CircularProgressIndicator()
                          : CustomButton(
                              text: 'Send Message',
                              onTap: () => provider.sendEmail(context),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
