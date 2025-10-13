import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:global_connect/core/utils/components/CustomButton.dart';
import '../../Provider/UserTipsProvider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/TipCard.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
import 'package:provider/provider.dart';

import '../../core/utils/routes/routes.dart';

class MyTipsScreen extends StatefulWidget {
  const MyTipsScreen({super.key});

  @override
  State<MyTipsScreen> createState() => _MyTipsScreenState();
}

class _MyTipsScreenState extends State<MyTipsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          'My Tips',
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
      ),
      body: Consumer<UserTipsProvider>(
        builder: (context, tipsProvider, child) {
          // Handle loading state
          if (tipsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle error state
          if (tipsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading tips',
                    style: pjsStyleBlack18600.copyWith(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tipsProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => tipsProvider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Handle empty state
          if (tipsProvider.currentUserTips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Tips Yet',
                    style: pjsStyleBlack18600.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share your first tip to help others!',
                    textAlign: TextAlign.center,
                    style: pjsStyleBlack15700.copyWith(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: CustomButton(
                      text: 'Add Your First Tip',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          RoutesName.shareTipsScreen,
                        );
                      },
                    ),
                  ),
                  // Navigate to the AddTipScreen)
                ],
              ),
            );
          }

          // Display tips
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.screenWidth * 0.05,
              vertical: context.screenHeight * 0.02,
            ),
            child: Column(
              children: [

                // Tips list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      tipsProvider.refresh();
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: tipsProvider.currentUserTips.length,
                      itemBuilder: (context, index) {
                        final tipData = tipsProvider.currentUserTips[index];
                        final formattedTip = tipsProvider.formatTipForDisplay(
                          tipData,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: TipCard(
                            category: formattedTip['category'] ?? 'Unknown Category',
                            title: formattedTip['title'] ?? 'No Title',
                            subTitle:
                                formattedTip['description'] ?? 'No Description',
                            location:
                                formattedTip['location'] ?? 'Unknown Location',

                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
