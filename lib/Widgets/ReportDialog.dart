import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:global_connect/core/utils/components/CustomButton.dart';
import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';
import '../core/const/custamSnackBar.dart';
import '../Provider/ReportProvider.dart';
import '../Model/ReportModel.dart';

class ReportDialog extends StatefulWidget {
  final String contentId;
  final String contentOwnerId;
  final ReportContentType contentType;

  const ReportDialog({
    super.key,
    required this.contentId,
    required this.contentOwnerId,
    required this.contentType,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final TextEditingController _additionalDetailsController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().resetForm();
    });
  }

  @override
  void dispose() {
    _additionalDetailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final provider = context.read<ReportProvider>();
    
    // Set additional details from controller
    provider.setAdditionalDetails(_additionalDetailsController.text);
    
    // Submit report
    final success = await provider.submitReport(
      contentId: widget.contentId,
      contentOwnerId: widget.contentOwnerId,
      contentType: widget.contentType,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        CustomSnackBar.showSuccess(
          context, 
          'Report submitted successfully'
        );
      } else {
        // Error is handled by provider and will be shown in UI
        CustomSnackBar.showFailure(
          context,
          provider.errorMessage ?? 'Failed to submit report'
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, child) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Report Content',
                    style: pjsStyleBlack18700.copyWith(color: AppColors.black),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Why are you reporting this ${widget.contentType.name}?',
                    style: pjsStyleBlack14400.copyWith(
                      color: AppColors.garyModern500,
                    ),
                  ),
                  const SizedBox(height: 8),
            
                  // Report reasons with reduced spacing
                  Column(
                    children: provider.reportReasons.map((reason) {
                      return RadioListTile<String>(
                        value: reason,
                        groupValue: provider.selectedReason,
                        onChanged: (value) {
                          provider.setSelectedReason(value);
                        },
                        title: Text(reason, style: pjsStyleBlack12400),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -3),
                      );
                    }).toList(),
                  ),
            
                  const SizedBox(height: 12),
            
                  Text(
                    'Additional details (optional)',
                    style: pjsStyleBlack14600.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _additionalDetailsController,
                    maxLines: 3,
                    onChanged: provider.setAdditionalDetails,
                    decoration: InputDecoration(
                      hintText: 'Provide more details about your report...',
                      hintStyle: pjsStyleBlack14400.copyWith(
                        color: AppColors.garyModern400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.garyModern200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.garyModern200),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
            
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage!,
                      style: pjsStyleBlack12400.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ],
            
                  const SizedBox(height: 18),
            
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          backgroundColor: AppColors.white,
                          textColor: AppColors.black,
                          borderColor: AppColors.greyScale100,
                          onTap: provider.isSubmitting 
                              ? null 
                              : () => Navigator.pop(context),
                        ),
                      ),
            
                      const SizedBox(width: 5),
                      Expanded(
                        child: CustomButton(
                          text: provider.isSubmitting 
                              ? 'Submitting...' 
                              : 'Submit Report',
                          backgroundColor: AppColors.red,
                          textColor: AppColors.white,
                          onTap: provider.isSubmitting ? null : _submitReport,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
