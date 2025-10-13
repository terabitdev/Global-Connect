import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/const/app_images.dart';
import '../core/theme/app_text_style.dart';
import '../core/utils/routes/routes.dart';

class InfoCardWidget extends StatelessWidget {
  final String backgroundImage;
  final String profileImage;
  final String profileName;
  final String title;
  final String subtitle;
  final double height;

  const InfoCardWidget({
    Key? key,
    required this.backgroundImage,
    required this.profileImage,
    required this.profileName,
    required this.title,
    required this.subtitle,
    this.height = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 20),
        child: Column(
          spacing: 5,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Profile Section

            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, RoutesName.myAccountScreen);
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 32,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(profileImage),
                        backgroundColor: Colors.white,
                        radius: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    profileName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            // Spacer to push content to bottom
           // const Spacer(),
            
            // Title Section
            Text(
              title,
              style: pjsStyleBlack24900.copyWith(color: Colors.white),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            
            const SizedBox(height: 8),
            
            // Subtitle with Location Icon
            Row(
              children: [
                SvgPicture.asset(
                  AppImages.location,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    subtitle,
                    style: pjsStyleBlack14500.copyWith(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
