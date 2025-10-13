import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';

import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/CustomTextField.dart';

import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';

class FeedBackScreen extends StatefulWidget {
  const FeedBackScreen({super.key});

  @override
  State<FeedBackScreen> createState() => _FeedBackScreenState();
}

class _FeedBackScreenState extends State<FeedBackScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          'Feedback',
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.screenWidth * 0.05,
            vertical: context.screenHeight * 0.02,
          ),
          child: Column(
            spacing: 16,
            children: [
              CustomTextField(
                label: 'Feedback',
                hintText: 'Enter feedback...',
                maxLines: 8,
              ),
        
              CustomButton(
                text: 'Submit',
                onTap: () {
                  print('Submit button tapped');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
