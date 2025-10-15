import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:global_connect/core/theme/app_text_style.dart';
import '../core/const/app_color.dart';
import '../core/const/app_images.dart';
import '../core/utils/routes/routes.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;
  final double height;
  final bool showBackButton;

  const CustomAppBar({
    Key? key,
    this.onBack,
    this.height = 100,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: height,
      title: Image.asset(AppImages.appLogo, height: 90, width: 90),
      leading: showBackButton
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  child: IconButton(
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.all(10),
                      ),
                      shape: MaterialStateProperty.all(const CircleBorder()),
                      backgroundColor: MaterialStateProperty.all(
                        AppColors.lightGrey,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: onBack ?? () => Navigator.pop(context),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

class CustomAppBar2 extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final VoidCallback? onBack;
  final VoidCallback? onAdd;
  final VoidCallback? onSetting;
  final VoidCallback? titleOnTap;
  final VoidCallback? editIconOnTap;
  final VoidCallback? deleteIconOnTap;
  const CustomAppBar2({
    super.key,
    required this.title,
    this.onBack,
    this.onAdd,
    this.editIconOnTap,
    this.deleteIconOnTap,
    this.titleOnTap,
    this.onSetting,
  });
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: CircleAvatar(
          backgroundColor: AppColors.lightGrey.withOpacity(0.60),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: onBack ?? () => Navigator.of(context).pop(),
          ),
        ),
      ),
      title: GestureDetector(
        onTap: titleOnTap,
        child: title,
      ),
      actions: [
        if (onAdd != null)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, RoutesName.createGroupChatScreen);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        '+ Group',
                        style: psjStyleBlack12400.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (onSetting != null)
          GestureDetector(
            onTap: titleOnTap,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SvgPicture.asset(AppImages.onSetting),
            ),
          ),
        if (editIconOnTap != null)
          GestureDetector(
            onTap: titleOnTap,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SvgPicture.asset(AppImages.editIcon1),
            ),
          ),
        if (deleteIconOnTap != null)
          GestureDetector(
            onTap: deleteIconOnTap,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SvgPicture.asset(AppImages.deleteIcon),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
class CustomAppBar3 extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final VoidCallback? onBack;
  final VoidCallback? onAdd;
  final String text;
  const CustomAppBar3({
    super.key,
    required this.text,
    required this.title,
    this.onBack,
    this.onAdd,


  });
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: CircleAvatar(
          backgroundColor: AppColors.lightGrey.withOpacity(0.60),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: onBack ?? () => Navigator.of(context).pop(),
          ),
        ),
      ),
      title: title,
      actions: [
        if (onAdd != null)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: onAdd,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        text,
                        style: psjStyleBlack12400.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}