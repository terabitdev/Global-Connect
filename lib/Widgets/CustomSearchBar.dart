import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/core/const/app_color.dart';
import 'package:global_connect/core/const/app_images.dart';

import '../core/theme/app_text_style.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const CustomSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return // TextField
    TextField(
      controller: controller,
      onChanged: onChanged,

      style: pjsStyleBlack14400.copyWith(color: AppColors.garyModern400),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: pjsStyleBlack14400.copyWith(color: AppColors.garyModern400),
        isDense: true,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(13.0),
          child: SvgPicture.asset(AppImages.searchIcon, height: 5, width: 5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.garyModern200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.garyModern200),
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
