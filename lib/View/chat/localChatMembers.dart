import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Provider/localChatProvider.dart';
import '../../Provider/PrivateChatProvider.dart';
import '../../Widgets/buildUserList.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
import '../../Model/userModel.dart';

class LocalChatMembers extends StatefulWidget {
  const LocalChatMembers({super.key});
  @override
  State<LocalChatMembers> createState() => _LocalChatMembersState();
}

class _LocalChatMembersState extends State<LocalChatMembers> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50,left: 20,right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.lightGrey.withValues(alpha: 0.60),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Consumer<LocalChatProvider>(
                  builder: (context, localChatProvider, child) {
                    final cityName = localChatProvider.displayCityName;
                    final memberCount = localChatProvider
                        .getCurrentCityParticipantsCount();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$cityName Local Chat Members',
                          style: pjsStyleBlack14600.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          '$memberCount members in local chat',
                          style: pjsStyleBlack12400.copyWith(
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer2<LocalChatProvider, PrivateChatProvider>(
              builder:
                  (context, localChatProvider, privateChatProvider, child) {
                    return StreamBuilder<List<UserModel>>(
                      stream: localChatProvider
                          .getCurrentCityParticipantsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          final shimmerCount = localChatProvider
                              .getCurrentCityParticipantsCount();
                          return _buildShimmerList(shimmerCount);
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading members: ${snapshot.error}',
                              style: pjsStyleBlack12400.copyWith(
                                color: AppColors.darkGrey,
                              ),
                            ),
                          );
                        }

                        final participants = snapshot.data ?? [];

                        if (participants.isEmpty) {
                          return Center(
                            child: Text(
                              'No members found',
                              style: pjsStyleBlack12400.copyWith(
                                color: AppColors.darkGrey,
                              ),
                            ),
                          );
                        }

                        return ListView(
                          children: participants.map((user) {
                            return buildUserList(
                              context,
                              user,
                              privateChatProvider,
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList(int count) {
    return ListView.builder(
      itemCount: count > 0 ? count : 6,
      itemBuilder: (context, index) {
        return buildShimmerUserCard(context);
      },
    );
  }

}
