import 'package:flutter/material.dart';

import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/CustomTextField.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';

class TipReviewScreen  extends StatefulWidget {
  const TipReviewScreen({super.key});

  @override
  State<TipReviewScreen> createState() => _TipReviewScreenState();
}

class _TipReviewScreenState extends State<TipReviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          'Write a review',
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            spacing: 20,
            children: [
              CustomTextField(
                label: 'Review',
                hintText: 'Enter review...',
                keyboardType: TextInputType.text,
                maxLines: 230,
                minLines: 10,
              ),
              CustomButton(text: 'Submit', onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
