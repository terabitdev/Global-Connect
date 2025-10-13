import 'package:flutter/material.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';

class SettingTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingTile({
    Key? key,
    required this.title,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.garyModern200),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SwitchListTile(
          title: Text(title, style: pStyleBlack14500),
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ),
    );
  }
}