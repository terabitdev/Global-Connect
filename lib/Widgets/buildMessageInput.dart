import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../core/const/app_color.dart';
import '../core/const/app_images.dart';
import '../core/theme/app_text_style.dart';

Widget buildMessageInput({
  required TextEditingController controller,
  String hintText = 'Type a message...',
  VoidCallback? onSend,
  VoidCallback? onMediaPicker,
  bool showMediaButton = true,
  Widget? sendIcon,
  Widget? mediaIcon,
  int maxLines = 3,
  int minLines = 1,
}) {
  return SafeArea(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray20)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gray30, width: 1.5),
                ),
                child: TextField(
                  style: wsStyleBlack12400.copyWith(color: AppColors.darkGrey),
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    hintStyle: pStyleBlack12400.copyWith(
                      color: AppColors.darkGrey,
                    ),
                  ),
                  maxLines: maxLines,
                  minLines: minLines,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend?.call(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (showMediaButton && controller.text.isEmpty)
              GestureDetector(
                onTap: onMediaPicker,
                child:
                    mediaIcon ??
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.gray20,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.attach_file,
                        color: AppColors.darkGrey,
                      ),
                    ),
              ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: onSend,
              child: sendIcon ?? SvgPicture.asset(AppImages.sendButton),
            ),
          ],
        ),
      ),
    ),
  );
}
