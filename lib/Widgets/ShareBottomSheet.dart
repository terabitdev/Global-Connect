import 'package:flutter/material.dart';
import 'package:global_connect/core/utils/components/CustomButton.dart';
import 'package:provider/provider.dart';
import '../Provider/PrivateChatProvider.dart';
import '../Provider/ChatProvider.dart';
import '../core/services/chat_Services.dart';
import '../Model/userModel.dart';
import '../core/const/app_color.dart';
import '../core/const/responsive_layout.dart';
import '../core/const/app_images.dart';
import '../core/theme/app_text_style.dart';
import 'CustomAppBar.dart';
import 'CustomSearchBar.dart';

class ShareBottomSheet extends StatefulWidget {
  final Function(List<String>) onShare;
  final String? postId;
  final String? postOwnerId;
  const ShareBottomSheet({
    super.key, 
    required this.onShare,
    this.postId,
    this.postOwnerId,
  });

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  final Set<String> _selectedUserIds = <String>{};
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _handleShare() async {
    if (_selectedUserIds.isNotEmpty) {
      widget.onShare(_selectedUserIds.toList());
      
      // If we have postId and postOwnerId, also share to chat
      if (widget.postId != null && widget.postOwnerId != null) {
        final chatServices = ChatServices();
        
        // Send post to each selected user's chat
        for (String userId in _selectedUserIds) {
          try {
            // Get or create chatroom
            String? chatroomId = await chatServices.getOrCreateChatroom(
              userId,
              'Private',
            );
            
            // Send the post message
            await chatServices.sendPostMessage(
              chatroomId: chatroomId,
              postId: widget.postId!,
              postOwnerId: widget.postOwnerId!,
              receiverId: userId,
            );
          } catch (e) {
            print('Error sharing post to user $userId: $e');
          }
        }
      }
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PrivateChatProvider(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            children: [
              Container(
                child: CustomAppBar2(
                  title: Text(
                    'Share',
                    style: pjsStyleBlack18600.copyWith(color: AppColors.black),
                  ),
                ),
              ),

              // Search Bar
              Consumer<PrivateChatProvider>(
                builder: (context, privateChatProvider, child) {
                  return CustomSearchBar(
                    controller: _searchController,
                    hintText: 'Search users...',
                    onChanged: (query) {
                      privateChatProvider.searchUsers(query);
                    },
                  );
                },
              ),
              SizedBox(height: context.screenHeight * 0.02),

              // Users List
              Expanded(
                child: Consumer<PrivateChatProvider>(
                  builder: (context, privateChatProvider, child) {
                    if (privateChatProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (privateChatProvider.allUsers.isEmpty) {
                      return const Center(child: Text('No users found'));
                    }

                    return ListView.builder(
                      itemCount: privateChatProvider.allUsers.length,
                      itemBuilder: (context, index) {
                        final user = privateChatProvider.allUsers[index];
                        return _buildUserTile(
                          context,
                          user,
                          privateChatProvider,
                        );
                      },
                    );
                  },
                ),
              ),

              // Share Button
              if (_selectedUserIds.isNotEmpty)
                CustomButton(
                  text: 'Share',
                  onTap: () {
                    _handleShare();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(
    BuildContext context,
    UserModel user,
    PrivateChatProvider provider,
  ) {
    final isSelected = _selectedUserIds.contains(user.uid);
    return Container(
      margin: EdgeInsets.only(bottom: context.screenHeight * 0.03),
      child: InkWell(
        onTap: () => _toggleUserSelection(user.uid),
        child: Row(
          children: [
            // Profile Image
            CircleAvatar(
              radius: context.screenWidth * 0.06,
              backgroundImage: (user.profileImageUrl?.isNotEmpty ?? false)
                  ? NetworkImage(user.profileImageUrl!)
                  : const AssetImage(AppImages.profileImage),
            ),
            SizedBox(width: context.screenWidth * 0.04),

            // User Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.fullName,
                    style: pjsStyleBlack16600.copyWith(color: AppColors.black),
                  ),
                ],
              ),
            ),

            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.primary,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
