import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../const/app_color.dart';
import '../../theme/app_text_style.dart';

class CustomButton2 extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;

  const CustomButton2({
    Key? key,
    required this.text,
    required this.onTap,
    this.backgroundColor,
    this.textColor,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.primary,
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Center(
          child: Text(
            text,
            style: pjsStyleBlack16600.copyWith(
              color: textColor ?? AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}


class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final double? padding;
  final Color? backgroundColor;
  final Color? textColor;
  final String? svgAsset;
  final double? iconSize;
  final TextStyle? textStyle;
  final Color? borderColor;

  const CustomButton({
    Key? key,
    required this.text,
    this.onTap,
    this.height,
    this.width,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.svgAsset,
    this.iconSize,
    this.textStyle,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width:width,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.primary,
          borderRadius: BorderRadius.circular(6),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.5)
              : null,
        ),
        padding: height == null
            ? EdgeInsets.symmetric(vertical: padding ?? 12, horizontal: 10)
            : null,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              spacing: 10,
             // mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (svgAsset != null) ...[
                  SvgPicture.asset(
                    svgAsset!,
                    height: iconSize ?? 18,
                    width: iconSize ?? 18,
                    colorFilter: ColorFilter.mode(
                      textColor ?? AppColors.white,
                      BlendMode.srcIn,
                    ),
                  ),

                ],
                Flexible(
                  child: Text(
                    text,
                    style: textStyle ??
                        pjsStyleBlack14500.copyWith(
                          color: textColor ?? AppColors.white,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomButton3 extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const CustomButton3({
    Key? key,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.garyModern400.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Center(
          child: Text(
            text,
            style: pjsStyleBlack16600.copyWith(
              color: AppColors.black,
            ),
          ),
        ),
      ),
    );
  }
}
class CustomButton4 extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final String? svgPath;

  const CustomButton4({
    Key? key,
    required this.text,
    required this.onTap,
    this.svgPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (svgPath != null) ...[
              SvgPicture.asset(
                svgPath!,
                height: 20,
                width: 20,

              ),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: pjsStyleBlack16600.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
