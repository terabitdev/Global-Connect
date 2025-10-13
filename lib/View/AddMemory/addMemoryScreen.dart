import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/core/const/app_images.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:global_connect/core/utils/components/CustomButton.dart';
import 'package:provider/provider.dart';
import '../../Provider/AddMemoryProvider.dart';
import '../../Provider/CountryProvider.dart';
import '../../Model/createMemoryModel.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/CustomTextField.dart';
import '../../Widgets/StepItem.dart';
import '../../Widgets/buildMemoryOption.dart';
import '../../Widgets/CountryDropdown.dart';
import '../../Widgets/CitySearchField.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/CountryCodeMapper.dart';
import '../../core/const/custamSnackBar.dart';

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({super.key});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  @override
  void initState() {
    super.initState();
    // Reset form when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final memoryProvider = Provider.of<AddMemoryProvider>(context, listen: false);
      final countryProvider = Provider.of<CountryProvider>(context, listen: false);
      
      // Clear both form data and country selections
      memoryProvider.resetForm();
      countryProvider.clearAllCountries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          'Create memory',
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
      ),
      body: Column(
        children: [
          // Step Progress Indicator
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.screenWidth * 0.05,
              vertical: context.screenHeight * 0.02,
            ),
            child: Consumer<AddMemoryProvider>(
              builder: (context, provider, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (!provider.setStepWithValidation(0)) {
                          CustomSnackBar.showFailure(
                            context,
                            'Please complete the current step first',
                          );
                        }
                      },
                      child: StepItem(
                        assetPath: AppImages.basicInfo,
                        title: "Basic Info",
                        isActive: provider.isStepActive(0),
                        isCompleted: provider.isStepCompleted(0),
                      ),
                    ),
                    buildDivider(
                      isCompleted:
                          provider.isStepCompleted(0) ||
                          provider.currentStep > 0,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (!provider.setStepWithValidation(1)) {
                          CustomSnackBar.showFailure(
                            context,
                            'Please complete the current step first',
                          );
                        }
                      },
                      child: StepItem(
                        assetPath: AppImages.memorySettings,
                        title: "Settings",
                        isActive: provider.isStepActive(1),
                        isCompleted: provider.isStepCompleted(1),
                      ),
                    ),
                    buildDivider(
                      isCompleted:
                          provider.isStepCompleted(1) ||
                          provider.currentStep > 1,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (!provider.setStepWithValidation(2)) {
                          CustomSnackBar.showFailure(
                            context,
                            'Please complete the current step first',
                          );
                        }
                      },
                      child: StepItem(
                        assetPath: AppImages.cover,
                        title: "Cover",
                        isActive: provider.isStepActive(2),
                        isCompleted: provider.isStepCompleted(2),
                      ),
                    ),
                    buildDivider(
                      isCompleted:
                          provider.isStepCompleted(2) ||
                          provider.currentStep > 2,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (!provider.setStepWithValidation(3)) {
                          CustomSnackBar.showFailure(
                            context,
                            'Please complete the current step first',
                          );
                        }
                      },
                      child: StepItem(
                        assetPath: AppImages.addMedia,
                        title: "Add Media",
                        isActive: provider.isStepActive(3),
                        isCompleted: provider.isStepCompleted(3),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Step Content
          Expanded(
            child: Consumer<AddMemoryProvider>(
              builder: (context, provider, child) {
                return _buildStepContent(provider.currentStep);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(int currentStep) {
    switch (currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildTripStopsStep();
      case 2:
        return _buildCoverImageStep();
      case 3:
        return _buildAddMediaStep();
      default:
        return _buildBasicInfoStep();
    }
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.screenWidth * 0.05,
          vertical: context.screenHeight * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            Text('Basic Information', style: pjsStyleBlack16600),
            Consumer<AddMemoryProvider>(
              builder: (context, provider, child) {
                return CustomTextField(
                  label: 'Memory Name',
                  hintText: 'Enter memory name',
                  controller: provider.getController('memoryName'),
                  focusNode: provider.getFocusNode('memoryName'),
                  keyboardType: TextInputType.name,
                  onChanged: (value) => provider.setMemoryName(value),
                );
              },
            ),
            Consumer<AddMemoryProvider>(
              builder: (context, provider, child) {
                return Row(
                  spacing: 20,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Start Date',
                        hintText: 'mm/dd/yyyy',
                        controller: provider.getController('startDate'),
                        focusNode: provider.getFocusNode('startDate'),
                        keyboardType: TextInputType.datetime,
                        iconPath: AppImages.calender,
                        readOnly: true,
                        onTap: () => provider.pickStartDate(context),
                      ),
                    ),
                    Expanded(
                      child: CustomTextField(
                        label: 'End Date',
                        hintText: 'mm/dd/yyyy',
                        controller: provider.getController('endDate'),
                        focusNode: provider.getFocusNode('endDate'),
                        keyboardType: TextInputType.datetime,
                        iconPath: AppImages.calender,
                        readOnly: true,
                        onTap: () => provider.pickEndDate(context),
                      ),
                    ),
                  ],
                );
              },
            ),
            CountryDropdown(
              label: 'Country',
              hintText: 'Select your country...',
              uniqueKey: 'main_country',
              onCountrySelected: (country) {
                final provider = Provider.of<AddMemoryProvider>(
                  context,
                  listen: false,
                );
                provider.setCountry(country);
              },
            ),
            Text(
              'Privacy',
              style: pjsStyleBlack14500.copyWith(color: AppColors.black),
            ),
            Consumer<AddMemoryProvider>(
              builder: (context, provider, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.garyModern200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        buildMemoryOption(
                          context: context,
                          provider: provider,
                          value: 0,
                          title: 'Private',
                          subtitle: 'Only you can see this memory',
                          isSelected: provider.selectedTabIndex == 0,
                        ),

                        const SizedBox(height: 16),

                        buildMemoryOption(
                          context: context,
                          provider: provider,
                          value: 1,
                          title: 'Public',
                          subtitle: 'Anyone can discover and view',
                          isSelected: provider.selectedTabIndex == 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            Consumer<AddMemoryProvider>(
              builder: (context, provider, child) {
                return CustomButton(
                  text: 'Continue to settings',
                  onTap: provider.canProceedToNextStep()
                      ? () => provider.nextStep()
                      : () {
                          CustomSnackBar.showFailure(
                            context,
                            'Please fill in all required fields: Memory Name, Start Date, End Date, and Country',
                          );
                        },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripStopsStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.screenWidth * 0.05,
          vertical: context.screenHeight * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            Column(
              spacing: 5,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advanced Settings',
                  style: pjsStyleBlack16500,
                  textAlign: TextAlign.justify,
                ),
                Text(
                  'Add multiple stops to create a detailed itinerary for your multi-country trip. This is optional - you can skip this step for simple trips.',
                  style: pjsStyleBlack12500.copyWith(
                    color: AppColors.garyModern400,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    spacing: 5,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trip Stops', style: pjsStyleBlack16500),
                      Text(
                        'Add cities and places you visited during\n your trip',
                        style: pjsStyleBlack12500.copyWith(
                          color: AppColors.garyModern400,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Expanded(

                    child: CustomButton(
                      svgAsset: AppImages.add,
                      iconSize: 15,
                      text: 'Add Stop',
                      onTap: () {
                        final provider = Provider.of<AddMemoryProvider>(
                          context,
                          listen: false,
                        );
                        provider.addTripStop();
                      },
                      height: 30,
                    ),
                  ),
                ),
              ],
            ),
            Consumer<AddMemoryProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    for (int i = 0; i < provider.tripStops.length; i++)
                      _buildTripStopItem(i, provider.tripStops[i]),
                  ],
                );
              },
            ),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: CustomButton4(
                    text: 'Skip Settings',
                    onTap: () {
                      final provider = Provider.of<AddMemoryProvider>(
                        context,
                        listen: false,
                      );
                      provider.setStep(2);
                    },
                  ),
                ),
                Expanded(
                  child: CustomButton(
                    text: 'Continue to cover',
                    onTap: () {
                      final provider = Provider.of<AddMemoryProvider>(
                        context,
                        listen: false,
                      );
                      provider.nextStep();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripStopItem(int index, TripStop stop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 15,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Stop ${index + 1}', style: pjsStyleBlack16500),
            if (index > 0)
              IconButton(
                onPressed: () {
                  final provider = Provider.of<AddMemoryProvider>(
                    context,
                    listen: false,
                  );
                  provider.removeTripStop(index);
                },
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
          ],
        ),
        dividerLine(),
        CountryDropdown(
          label: 'Country',
          hintText: 'Select country...',
          uniqueKey: 'trip_stop_${index}_country',
          initialValue: stop.country,
          onCountrySelected: (country) {
            final provider = Provider.of<AddMemoryProvider>(
              context,
              listen: false,
            );
            provider.updateTripStop(index, country: country);
          },
        ),
        Consumer2<AddMemoryProvider, CountryProvider>(
          builder: (context, addMemoryProvider, countryProvider, child) {
            // Get the selected country for this trip stop to restrict city search
            final selectedCountry = countryProvider.getSelectedCountry(
              'trip_stop_${index}_country',
            );
            final countryCode = selectedCountry != null
                ? CountryCodeMapper.getCountryCode(selectedCountry)
                : null;

            return CitySearchField(
              label: 'City (Optional)',
              hintText: 'Search for city...',
              controller: addMemoryProvider.getController(
                'tripStop${index}City',
              ),
              countryCode: countryCode,
              onCitySelected: (city) =>
                  addMemoryProvider.updateTripStop(index, city: city),
            );
          },
        ),
        Consumer<AddMemoryProvider>(
          builder: (context, provider, child) {
            return Row(
              spacing: 20,
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'From',
                    hintText: 'mm/dd/yyyy',
                    controller: provider.getController('tripStop${index}From'),
                    keyboardType: TextInputType.datetime,
                    iconPath: AppImages.calender,
                    readOnly: true,
                    onTap: () => provider.pickTripStopFromDate(context, index),
                  ),
                ),
                Expanded(
                  child: CustomTextField(
                    label: 'To',
                    hintText: 'mm/dd/yyyy',
                    controller: provider.getController('tripStop${index}To'),
                    keyboardType: TextInputType.datetime,
                    iconPath: AppImages.calender,
                    readOnly: true,
                    onTap: () => provider.pickTripStopToDate(context, index),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCoverImageStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.screenWidth * 0.05,
          vertical: context.screenHeight * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            Column(
              spacing: 5,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cover Image',
                  style: pjsStyleBlack16500,
                  textAlign: TextAlign.justify,
                ),
                Text(
                  'Choose a cover image for your memory. This will be the main image displayed when sharing your trip..',
                  style: pjsStyleBlack12500.copyWith(
                    color: AppColors.garyModern400,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
            Consumer<AddMemoryProvider>(
              builder: (context, provider, child) {
                return GestureDetector(
                  onTap: () => provider.pickCoverImage(),
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(10),
                    color: AppColors.garyModern200,
                    strokeWidth: 2,
                    dashPattern: const [8, 4],
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(color: AppColors.white),
                      child: provider.coverImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                provider.coverImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 30,
                                ),
                                child: Column(
                                  spacing: 20,
                                  children: [
                                    SvgPicture.asset(AppImages.coverImage),
                                    Text(
                                      'Upload Cover Image',
                                      style: pjsStyleBlack14700.copyWith(
                                        color: AppColors.garyModern400,
                                      ),
                                    ),
                                    SizedBox(
                                      width: context.screenWidth / 2,
                                      child: CustomButton4(
                                        svgPath: AppImages.upload,
                                        text: 'Choose File',
                                        onTap: () => provider.pickCoverImage(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.garyModern200),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: RichText(
                      text: TextSpan(
                        style: pjsStyleBlack12400,
                        children: [
                          TextSpan(text: 'Note: ', style: pjsStyleBlack12600),
                          const TextSpan(
                            text:
                                'A cover image is required to publish your memory, but you can save it as a draft without one.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: CustomButton4(
                    text: 'Skip for now',
                    onTap: () {
                      final provider = Provider.of<AddMemoryProvider>(
                        context,
                        listen: false,
                      );
                      provider.nextStep();
                    },
                  ),
                ),
                Expanded(
                  child: CustomButton(
                    text: 'Continue to media',
                    onTap: () {
                      final provider = Provider.of<AddMemoryProvider>(
                        context,
                        listen: false,
                      );
                      provider.nextStep();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMediaStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.screenWidth * 0.05,
          vertical: context.screenHeight * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            Column(
              spacing: 5,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add your media',
                  style: pjsStyleBlack16500,
                  textAlign: TextAlign.justify,
                ),
                Text(
                  'Upload photos and videos from your trip. You can assign them to specific stops or keep them unassigned.',
                  style: pjsStyleBlack12500.copyWith(
                    color: AppColors.garyModern400,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    spacing: 5,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Media Library', style: pjsStyleBlack16500),
                      Text(
                        'Media Library',
                        style: pjsStyleBlack12500.copyWith(
                          color: AppColors.garyModern400,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Expanded(

                    child: CustomButton(
                      svgAsset: AppImages.upload,
                      iconSize: 15,
                      text: 'Add Media',
                      onTap: () {
                        final provider = Provider.of<AddMemoryProvider>(
                          context,
                          listen: false,
                        );
                        provider.addMediaImages();
                      },
                      height: 30,
                    ),
                  ),
                ),
              ],
            ),
            Consumer<AddMemoryProvider>(
              builder: (context, provider, child) {
                return GestureDetector(
                  onTap: () => provider.addMediaImages(),
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(10),
                    color: AppColors.garyModern200,
                    strokeWidth: 2,
                    dashPattern: const [8, 4],
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(color: AppColors.white),
                      child: provider.selectedImages.isNotEmpty
                          ? Container(
                              height: 200,
                              child: provider.selectedImages.length == 1
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        provider.selectedImages.first,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : GridView.builder(
                                      padding: const EdgeInsets.all(8),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 4,
                                        mainAxisSpacing: 4,
                                      ),
                                      itemCount: provider.selectedImages.length,
                                      itemBuilder: (context, index) {
                                        return Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(
                                                provider.selectedImages[index],
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => provider.removeImage(index),
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 30,
                                ),
                                child: Column(
                                  spacing: 20,
                                  children: [
                                    SvgPicture.asset(
                                      AppImages.upload,
                                      width: 35,
                                      height: 35,
                                    ),
                                    Text(
                                      'No media added yet. Click to upload.',
                                      style: pjsStyleBlack14700.copyWith(
                                        color: AppColors.garyModern400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
            Consumer<AddMemoryProvider>(
              builder: (context, provider, child) {
                return CustomTextField(
                  label: 'Caption',
                  hintText: 'Enter caption...',
                  controller: provider.captionController,
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  onChanged: (value) => provider.setCaption(value),
                );
              },
            ),
            SizedBox(height: context.screenHeight * 0.05),
            Consumer<AddMemoryProvider>(
              builder: (context, provider, child) {
                return Column(
                  spacing: 10,
                  children: [
                    // Show progress if uploading
                    if (provider.isLoading)
                      Column(
                        spacing: 10,
                        children: [
                          const LinearProgressIndicator(),
                          Text(
                            provider.uploadProgress,
                            style: pjsStyleBlack12400,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    
                    // Show error if any
                    if (provider.imagesError != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          provider.imagesError!,
                          style: pjsStyleBlack12400.copyWith(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    // Buttons
                    Row(
                      spacing: 10,
                      children: [
                        // Expanded(
                        //   child: CustomButton4(
                        //     text: 'Save Draft',
                        //     onTap: provider.isLoading ? null : () {
                        //       ScaffoldMessenger.of(context).showSnackBar(
                        //         const SnackBar(
                        //           content: Text('Draft functionality coming soon!'),
                        //         ),
                        //       );
                        //     },
                        //   ),
                        // ),
                        Expanded(
                          child: CustomButton(
                            text: provider.isLoading ? 'Creating...' : 'Create Memory',
                            onTap: provider.isLoading ? null : () async {
                              if (provider.canSaveMemory()) {
                                final success = await provider.saveMemory();
                                if (success && context.mounted) {
                                  CustomSnackBar.showSuccess(
                                    context,
                                    'Memory created successfully!',
                                  );
                                  Navigator.of(context).pop();
                                }
                              } else {
                                CustomSnackBar.showFailure(
                                  context,
                                  'Please fill in required fields: Memory Name, Country, Start/End Date, and at least one image',
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
