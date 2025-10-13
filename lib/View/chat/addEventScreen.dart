import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';

import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/CustomTextField.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          'Create New Event',
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
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Event Photo', style: pjsStyleBlack14500),
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {},
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
                          child: const Icon(
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
              SizedBox(height: 16),
              CustomTextField(
                label: 'Event Title',
                hintText: 'Enter your event name..',
              ),
              SizedBox(height: 16),
              CustomTextField(
                label: 'Category',
                hintText: 'Select your category..',
              ),
              SizedBox(height: 16),
              CustomTextField(label: 'Date ', hintText: 'Enter date..'),
              SizedBox(height: 16),
              CustomTextField(label: 'Time', hintText: 'Enter time..'),
              SizedBox(height: 16),
              CustomTextField(
                label: 'Location',
                hintText: 'Enter event location..',
              ),
              SizedBox(height: 16),
              CustomTextField(
                label: 'Description',
                hintText: 'Enter event description..',
                maxLines: 4,
              ),
              SizedBox(height: 16),
              CustomTextField(
                label: 'Max Attendees',
                hintText: 'Enter attendees..',
              ),
              SizedBox(height: 16),
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: CustomButton3(
                      text: 'Save Draft',
                      onTap: () {
                        print('Cancel button tapped');
                      },
                    ),
                  ),

                  Expanded(
                    child: CustomButton(
                      text: 'Save',
                      onTap: () {
                        print('Submit Event');
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
