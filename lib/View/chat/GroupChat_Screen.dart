
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:provider/provider.dart';
import '../../Provider/GroupChatProvider.dart';
import '../../Widgets/ChatBubble.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';
import '../../core/utils/routes/routes.dart';
import '../../core/utils/routes/routes_names.dart';
import '../../Model/localEvenModel.dart';
import '../../Widgets/RestaurantCard.dart';
import 'package:shimmer/shimmer.dart';
import 'MediaPreviewScreen.dart';



class GroupChatScreen extends StatefulWidget {
  final String groupName;
  final String groupChatRoomId;

  const GroupChatScreen({
    super.key,
    required this.groupName,
    required this.groupChatRoomId,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _shouldAutoScroll = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _initializeChat() {
    final chatProvider = context.read<GroupChatProvider>();
    chatProvider.initializeChat(widget.groupChatRoomId, groupName: widget.groupName);
    _scrollToBottom();
  }



  Future<void> _loadMoreMessages() async {
    final chatProvider = Provider.of<GroupChatProvider>(context, listen: false);
    await chatProvider.loadMoreMessages();
  }


  void _sendMessage(GroupChatProvider chatProvider) {
    if (chatProvider.messageController.text.trim().isNotEmpty) {
      chatProvider.sendMessage(widget.groupChatRoomId);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            context.read<GroupChatProvider>().clearError();
          },
        ),
      ),
    );
  }


  /// Build shimmer loading effect for group chat messages
  Widget _buildLoadingWidget() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 6, // Show 6 shimmer message placeholders
      itemBuilder: (context, index) {
        // Alternate between sent and received message styles
        final isCurrentUser = index % 3 != 0; // Mix of sent/received
        return _buildShimmerMessageBubble(isCurrentUser);
      },
    );
  }

  /// Build individual shimmer message bubble for group chat
  Widget _buildShimmerMessageBubble(bool isCurrentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            // Profile picture shimmer for received messages
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Message bubble shimmer
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sender name shimmer (for group chats)
                      if (!isCurrentUser) ...[
                        Container(
                          width: MediaQuery.of(context).size.width * 0.3,
                          height: 12,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 4),
                      ],
                      // Simulate message text lines
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.grey[300],
                      ),
                      if (DateTime.now().millisecond % 2 == 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: 16,
                          color: Colors.grey[300],
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Time shimmer
                      Container(
                        width: 40,
                        height: 10,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            // Profile picture shimmer for sent messages
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build loading more messages indicator
  Widget _buildLoadingMoreWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Profile picture shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(width: 8),
          // Message bubble shimmer
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyMessagesWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.darkGrey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: pjsStyleBlack18600.copyWith(
                color: AppColors.darkGrey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation in ${widget.groupName}!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.darkGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMessageInput(GroupChatProvider chatProvider) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray20)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gray20),
                ),
                child: TextField(
                  controller: chatProvider.messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  onSubmitted: (_) => _sendMessage(chatProvider),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!chatProvider.hasMessageText)
              GestureDetector(
                onTap: () => _showMediaPicker(context, chatProvider),
                child: SvgPicture.asset(AppImages.fileButton),
              ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: () => _sendMessage(chatProvider),
              child: SvgPicture.asset(
                AppImages.sendButton,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build timeline list with messages and events
  Widget _buildTimelineList(GroupChatProvider chatProvider) {
    final items = chatProvider.currentTimelineItems;
    final totalItems = items.length + (chatProvider.hasMoreMessages ? 1 : 0);
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Show loading indicator for older messages
        if (index == 0 && chatProvider.hasMoreMessages) {
          return chatProvider.isLoadingMore 
              ? _buildLoadingMoreWidget()
              : const SizedBox.shrink();
        }
        
        // Adjust index when loading indicator is shown
        final itemIndex = chatProvider.hasMoreMessages ? index - 1 : index;
        
        if (itemIndex >= items.length) {
          return const SizedBox.shrink();
        }
        
        final item = items[itemIndex] as Map<String, dynamic>;
        final String itemType = item['itemType'] as String;
        
        if (itemType == 'event') {
          final LocalEventModel e = item['data'] as LocalEventModel;
          return LocalEventCard(
            id: e.id,
            title: e.title,
            description: e.description,
            date: e.date,
            time: e.time,
            location: e.location,
            imageUrl: e.imageUrl,
            category: e.category,
            maxAttendees: e.maxAttendees,
            attendeesIds: e.attendeesIds,
            cityName: widget.groupChatRoomId,
            createdById: e.createdById,
            eventLatitude: e.latitude,
            eventLongitude: e.longitude,
            onTap: () {},
          );
        } else {
          final Message message = item['data'] as Message;
          final isCurrentUser = message.senderId == chatProvider.currentUserId;
          
          // Add additional properties for upload state
          final additionalProps = {
            'isOptimistic': chatProvider.isMessageOptimistic(message.id),
            'isUploading': chatProvider.isMessageUploading(message.id),
            'uploadProgress': chatProvider.getMessageUploadProgress(message.id),
            'isFailed': chatProvider.isMessageFailed(message.id),
          };

          return ChatBubble(
            message: message,
            isCurrentUser: isCurrentUser,
            additionalProps: additionalProps,
            onDeleteMessage: (messageId) {
              chatProvider.deleteMessage(messageId, widget.groupChatRoomId);
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          widget.groupName,
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
        titleOnTap: () {
          Navigator.pushNamed(
            context,
            RoutesName.groupChatSettingScreen,
            arguments: {
              'groupChatRoomId': widget.groupChatRoomId,
              'groupName': widget.groupName,
            },
          );
        },
        onSetting: (){
          Navigator.pushNamed(
            context,
            RoutesName.groupChatSettingScreen,
            arguments: {
              'groupChatRoomId': widget.groupChatRoomId,
              'groupName': widget.groupName,
            },
          );
        },
      ),
      body: Consumer<GroupChatProvider>(
        builder: (context, chatProvider, child) {
          // ✅ SHOW ERROR SNACKBAR
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (chatProvider.error != null) {
              _showErrorSnackBar(chatProvider.error!);
            }
          });

          // ✅ AUTO SCROLL WHEN NEW MESSAGES ARRIVE (only if user is at bottom)
          if (!chatProvider.isLoading && chatProvider.messages.isNotEmpty && _shouldAutoScroll) {
            _scrollToBottom();
          }

          return Column(
            children: [
              // Show subtle bottom loading indicator when uploading media
              if (chatProvider.messages.isNotEmpty && (chatProvider.isUploadingFile || chatProvider.hasPendingMessages))
                Container(
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withOpacity(0.3)),
                  ),
                ),
              
              // Messages and Events List
              Expanded(
                child: chatProvider.isLoading
                    ? _buildLoadingWidget()
                    : chatProvider.currentTimelineItems.isEmpty
                    ? _buildEmptyMessagesWidget()
                    : _buildTimelineList(chatProvider),
              ),
              Padding(
                padding:  EdgeInsets.symmetric(
                    horizontal:50,
                    vertical: 10
                ),
                child: CustomButton(
                    text: '🎉 Create Group Event',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        RoutesName.createLocalEvent,
                        arguments: {
                          'cityName': widget.groupChatRoomId,
                          'eventName':'Group Event',
                        },
                      );
                    }

                ),
              ),

              // ✅ USE NEW MESSAGE INPUT
              _buildMessageInput(chatProvider),
            ],
          );
        },
      ),
    );
  }

  void _showMediaPicker(BuildContext context, GroupChatProvider chatProvider) async {
    final file = await chatProvider.pickImageOrVideo();
    if (file != null && chatProvider.selectedFileType != null) {
      // Navigate to media preview screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaPreviewScreen(
            mediaFile: file,
            mediaType: chatProvider.selectedFileType!,
            onCancel: () {
              chatProvider.clearSelectedFile();
            },
            onSend: (caption) {
              chatProvider.sendMediaMessage(
                groupChatRoomId: widget.groupChatRoomId,
                caption: caption,
              );
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<GroupChatProvider>(context, listen: false);
      chatProvider.reset();
    });
    super.dispose();
  }
}
