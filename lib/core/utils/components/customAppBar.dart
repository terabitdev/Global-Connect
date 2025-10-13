import 'package:flutter/material.dart';
import 'package:global_connect/core/theme/app_text_style.dart';

import '../../const/app_color.dart';

class CustomAppBarScreen extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;

  const CustomAppBarScreen({
    Key? key,
    required this.title,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Stack(
          children: [
            // Back button
            // Positioned(
            //   left: 16,
            //   top: 0,
            //   bottom: 0,
            //   child: GestureDetector(
            //     onTap: onBackPressed ?? () => Navigator.pop(context),
            //     child: Container(
            //       width: 40,
            //       height: 40,
            //       decoration:  BoxDecoration(
            //         color: AppColors.lightGrey.withAlpha(60),
            //         shape: BoxShape.circle,
            //       ),
            //       child: const Icon(
            //         Icons.arrow_back,
            //         color: Colors.black,
            //         size: 24,
            //       ),
            //     ),
            //   ),
            // ),

            // Centered title
            Center(
              child: Text(
                title,
                style: pjsStyleBlack18600
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
