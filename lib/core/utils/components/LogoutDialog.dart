import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../const/app_color.dart';
import '../../theme/app_text_style.dart';
import '../routes/routes.dart';
import 'CustomButton.dart';

class LogoutDialog extends StatelessWidget {
  final VoidCallback onLogout;

  const LogoutDialog({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      title: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.close, color: AppColors.black, size: 25),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Center(
                child: Text(
                  'Are you sure you want\n to logout?',
                  style: pjsStyleBlack18700,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
      content: Text(
        'Make sure you’ve saved your work or completed any ongoing tasks before logging out.',
        style: pjsStyleBlack14400.copyWith(color: AppColors.garyModern500),
        textAlign: TextAlign.center,
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: CustomButton(
                text: 'Cancel',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomButton3(
                text: 'Log Out',
                onTap: onLogout,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DeleteAccountDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const DeleteAccountDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      title: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.close, color: AppColors.black, size: 25),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Center(
                child: Text(
                  'Are you sure you want\n to Delete your Account?',
                  style: pjsStyleBlack18700,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
      content: Text(
        'Once you delete your account, your data will be permanently deleted and you will not be able to recover it.',
        style: pjsStyleBlack14400.copyWith(color: AppColors.garyModern500),
        textAlign: TextAlign.center,
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: CustomButton(
                text: 'Cancel',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomButton3(
                text: 'Confirm',
                onTap: () {
                  Navigator.pop(context);
                  onConfirm();
                  Navigator.pushNamed(context, RoutesName.onboardingScreen);


                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}



