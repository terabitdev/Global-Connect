import 'package:flutter/cupertino.dart';
import 'package:global_connect/core/const/responsive_layout.dart';

import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';

Widget buildPolicySection(
  BuildContext context,
  String title,
  String description, {
  List<String>? bulletPoints,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: pjsStyleBlack16500),
      SizedBox(height: context.screenHeight * 0.01),
      if (description.isNotEmpty)
        Text(
          description,
          style: pjsStyleBlack14400.copyWith(color: AppColors.garyModern500),
        ),
      if (bulletPoints != null && bulletPoints.isNotEmpty) ...[
        if (description.isNotEmpty)
          SizedBox(height: context.screenHeight * 0.01),
        ...bulletPoints
            .map(
              (point) => Padding(
                padding: EdgeInsets.only(
                  left: context.screenWidth * 0.04,
                  bottom: context.screenHeight * 0.008,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: pjsStyleBlack14400.copyWith(
                        color: AppColors.garyModern500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: pjsStyleBlack14400.copyWith(
                          color: AppColors.garyModern500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    ],
  );
}
