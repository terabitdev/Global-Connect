import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../Provider/CreateLocalEventProvider.dart';
import '../../../Provider/SignupProvider.dart';
import '../../../Widgets/CustomAppBar.dart';
import '../../../Widgets/CustomTextField.dart';
import '../../../core/const/app_color.dart';
import '../../../core/const/app_images.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../core/utils/components/CustomButton.dart';

class CreateLocalEvent extends StatefulWidget {
  final String cityName;
  final String eventName;
  const CreateLocalEvent({super.key, required this.cityName,required this.eventName});
  @override
  State<CreateLocalEvent> createState() => _CreateLocalEventState();
}

class _CreateLocalEventState extends State<CreateLocalEvent> {
  @override
  Widget build(BuildContext context) {
    print("City Name: ${widget.cityName}");
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          "Create ${widget.eventName}",
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
      ),
      body: Consumer2<SignupProvider, CreateLocalEventProvider>(
        builder: (context, signupProvider, createLocalEventProvider, child) {
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
                  Column(
                    spacing: 3,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Create Local Event',
                        style: pjsStyleBlack14600.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                      Text(
                        'Create an event for your local chat community to join.',
                        style: pjsStyleBlack12400.copyWith(
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => signupProvider.pickImageFromGallery(),
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
                          'Tap to Add Photo',
                          style: pjsStyleBlack14500.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Event Tile',
                    hintText: 'Enter your Event Tile..',
                    controller: createLocalEventProvider.groupNameController,
                    focusNode: createLocalEventProvider.groupNameFocus,
                    nextFocusNode: createLocalEventProvider.descriptionFocus,
                  ),
                  SizedBox(height: 16),
                  Row(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => createLocalEventProvider.pickDate(context),
                          child: AbsorbPointer(
                            child: CustomTextField(
                              label: 'Date',
                              hintText: 'Select Date',
                              controller: TextEditingController(
                                text: createLocalEventProvider.selectedDate == null
                                    ? ""
                                    : "${createLocalEventProvider.selectedDate!.day}/${createLocalEventProvider.selectedDate!.month}/${createLocalEventProvider.selectedDate!.year}",
                              ),
                              suffixIcon: Icon(
                                Icons.calendar_today,
                                color: AppColors.garyModern400,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => createLocalEventProvider.pickTime(context),
                          child: AbsorbPointer(
                            child: CustomTextField(
                              label: 'Time',
                              hintText: 'Select Time',
                              controller: TextEditingController(
                                text: createLocalEventProvider.selectedTime == null
                                    ? ""
                                    : createLocalEventProvider.selectedTime!.format(
                                  context,
                                ),
                              ),
                              suffixIcon: Icon(
                                Icons.access_time,
                                color: AppColors.garyModern400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  CustomTextField(
                    label: 'Description',
                    hintText: 'Tell people more about your event...',
                    minLines: 3,
                    maxLines: 5,
                    controller: createLocalEventProvider.descriptionController,
                    focusNode: createLocalEventProvider.descriptionFocus,
                    nextFocusNode: createLocalEventProvider.locationFocus,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Address/Location',
                    hintText: 'Where will the event take place?',
                    controller: createLocalEventProvider.locationController,
                    focusNode: createLocalEventProvider.locationFocus,
                    nextFocusNode: createLocalEventProvider.maxAttendeesFocus,
                    suffixIcon: Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    onChanged: (value) {
                      createLocalEventProvider.searchLocation(value);
                    },
                    // onFieldSubmitted: (value) {
                    //   FocusScope.of(context).requestFocus(
                    //     createLocalEventProvider.maxAttendeesFocus,
                    //   );
                    // },
                  ),
                  const SizedBox(height: 8),
                  if (createLocalEventProvider.isSearchingLocation)
                    Shimmer.fromColors(
                      baseColor: AppColors.garyModern200,
                      highlightColor: AppColors.garyModern200,
                      child: Container(
                       // height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  if (createLocalEventProvider.locationSuggestions.isNotEmpty &&
                      !createLocalEventProvider.isSearchingLocation)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                        minHeight: 50,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.garyModern200.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: createLocalEventProvider.locationSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = createLocalEventProvider.locationSuggestions[index];
                          return ListTile(
                            title: Text(
                              suggestion,
                              style: pjsStyleBlack14400.copyWith(
                                color: AppColors.black,
                              ),
                            ),
                            onTap: () {
                              createLocalEventProvider.selectLocation(suggestion);
                              FocusScope.of(context).requestFocus(
                                createLocalEventProvider.maxAttendeesFocus,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 16),
                  CustomTextField(
                    label: 'Max Participents',
                    hintText: 'Leave empty for unlimited',
                    controller: createLocalEventProvider.maxAttendeesController,
                    focusNode: createLocalEventProvider.maxAttendeesFocus,
                  ),


                  // Date Picker





                  const SizedBox(height: 16),

                  Text(
                    'Category',
                    style: pjsStyleBlack14500.copyWith(color: AppColors.black),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.garyModern200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: createLocalEventProvider.selectedCategory,
                          isExpanded: true,
                          hint: Text(
                            'Select your category..',
                            style: pjsStyleBlack14400.copyWith(
                              color: AppColors.garyModern400,
                            ),
                          ),
                          icon: SvgPicture.asset(AppImages.downButton),
                          items: createLocalEventProvider.categories
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              createLocalEventProvider.setCategory(value);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: createLocalEventProvider.isSaving
                        ? 'Saving...'
                        : 'Save Event',
                    onTap: createLocalEventProvider.isSaving
                        ? null
                        : () async {
                            final bool ok = await createLocalEventProvider.saveEvent(
                              cityName: widget.cityName,
                              imageFile: signupProvider.profileImage,
                              eventName: widget.eventName,
                            );
                            if (!mounted) return;
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Event created successfully')),
                              );
                              Navigator.of(context).pop();
                            } else {
                              final String message =
                                  createLocalEventProvider.errorMessage ?? 'Failed to create event';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
