import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? togglePasswordVisibility;
  final bool isRequired;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final String? iconPath;
  final VoidCallback? onTap;
  final bool readOnly;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.nextFocusNode,
    this.keyboardType,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.togglePasswordVisibility,
    this.isRequired = false,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.minLines = 1,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.iconPath,
    this.onTap,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: pjsStyleBlack14500.copyWith(color: AppColors.black),
            children: [
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: pjsStyleBlack14500.copyWith(color: AppColors.black),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            obscureText: isPassword ? !isPasswordVisible : false,
            validator: validator,
            onChanged: onChanged,
            enabled: enabled && onTap == null,
            readOnly: readOnly || onTap != null,
            minLines: minLines,
            maxLines: maxLines,
            textCapitalization: textCapitalization,
            textInputAction: nextFocusNode != null
                ? TextInputAction.next
                : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (nextFocusNode != null) {
                FocusScope.of(context).requestFocus(nextFocusNode);
              }
            },
            onTap: onTap,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.garyModern200),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red),
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.garyModern200.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: hintText,
              hintStyle: pjsStyleBlack14400.copyWith(
                color: AppColors.garyModern400,
              ),
              prefixIcon: prefixIcon,
              suffixIcon:
                  suffixIcon ??
                  (iconPath != null
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SvgPicture.asset(
                            iconPath!,
                            width: 10,
                            height: 10,
                          ),
                        )
                      : (isPassword
                            ? IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: AppColors.garyModern400,
                                ),
                                onPressed: togglePasswordVisibility,
                              )
                            : null)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Widget buildTextField({
  required TextEditingController controller,
  required FocusNode focusNode,
  required String hintText,
  Function(String)? onFieldSubmitted,
}) {
  return TextFormField(
    controller: controller,
    focusNode: focusNode,
    onFieldSubmitted: onFieldSubmitted,
    style: pjsStyleBlack14400.copyWith(color: AppColors.black),
    decoration: InputDecoration(
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.garyModern200),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.garyModern200.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      hintText: hintText,
      hintStyle: pjsStyleBlack14400.copyWith(color: AppColors.garyModern400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
