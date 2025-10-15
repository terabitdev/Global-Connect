import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:global_connect/core/theme/app_text_style.dart';

import '../core/const/app_color.dart';
import '../core/const/app_images.dart';

class FilterDropdown extends StatelessWidget {
  final String selectedValue;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const FilterDropdown({
    super.key,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.garyModern200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          focusColor: AppColors.primary,
          hoverColor: AppColors.primary.withOpacity(0.05),
        ),
        child: DropdownButton<String>(
          borderRadius: BorderRadius.circular(10),
          dropdownColor: AppColors.white,
          value: selectedValue,
          isExpanded: true,
          underline: const SizedBox(),
          icon: const SizedBox(),
          selectedItemBuilder: (BuildContext context) {
            return items.map((String value) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(value, style: pjsStyleBlack14400),
                  SvgPicture.asset(
                    AppImages.dropDown,
                    height: 11,
                    width: 20,
                    color: AppColors.primary,
                  ),
                ],
              );
            }).toList();
          },
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: ColoredBox(
                color: selectedValue == value
                    ? AppColors.primary
                    : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: pjsStyleBlack14400.copyWith(
                      color: selectedValue == value
                          ? AppColors.white
                          : AppColors.black,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
