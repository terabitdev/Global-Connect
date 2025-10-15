import 'package:flutter/material.dart';
import 'package:global_connect/core/theme/app_text_style.dart';
import 'app_color.dart';

class CustomSnackBar {
  static void showSuccess(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: pjsStyleBlack13600.copyWith(
                    color: AppColors.white
                  )
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.only(
            top: 10,
            left: 10,
            right: 10,
            bottom: 10
          ),
        ),
      );
    });
  }

  static void showFailure(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: AppColors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.only(
            top: 10,
            left: 10,
            right: 10,
            bottom: 10
          ),
        ),
      );
    });
  }

  static void showWarning(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: AppColors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor:AppColors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.only(
            top: 10,
            left: 10,
            right: 10,
            bottom: 10
          ),
        ),
      );
    });
  }
}
