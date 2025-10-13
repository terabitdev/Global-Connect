import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:global_connect/core/utils/components/CustomButton.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../Model/userModel.dart';
import '../../Model/chatRoomModel.dart';
import '../../Provider/ChatProvider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/EventCard.dart';
import '../../core/utils/routes/routes.dart';
import '../../core/services/NotificationService/NotificationService.dart';
import 'MediaPreviewScreen.dart';

class ChatScreen  extends StatefulWidget {
  final String type;
  final UserModel user;
  final String? chatroomId;

  const ChatScreen({
    super.key,
    required this.type,
    required this.user,
    this.chatroomId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  final NotificationService _notificationService = NotificationService.instance;
  late ChatController _chatController;
  
  // Real-time user status tracking
  StreamSubscription<DocumentSnapshot>? _userStatusSubscription;
  UserModel _currentUser = UserModel(
    uid: '',
    email: '',
    fullName: '',
    nationality: '',
    homeCity: '',
    createdAt: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user; // Initialize with widget user data
    _chatController = ChatController.instance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
      _initializeUserStatusListener();
    });
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;
    
    try {
      if (widget.chatroomId != null) {
        await _chatController.preloadMessagesForDisplay(widget.chatroomId!);
        print('✨ Preloaded messages for chatroom: ${widget.chatroomId}');
      }
      
      await _chatController.initializeChatroom(
        otherUserId: widget.user.uid,
        chatType: widget.type,
        existingChatroomId: widget.chatroomId,
      );
      _isInitialized = true;

      if (widget.chatroomId != null) {
        await _notificationService.markNotificationAsRead(widget.chatroomId!);
      }

      _scrollToBottom();
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  /// Initialize real-time listener for user status changes
  void _initializeUserStatusListener() {
    _userStatusSubscription?.cancel();
    
    _userStatusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final userData = snapshot.data() as Map<String, dynamic>;
        _currentUser = UserModel.fromMap(userData);
        setState(() {}); // Update UI with new user data
        print('📱 User status updated in ChatScreen: ${_currentUser.status}');
      }
    }, onError: (error) {
      print('❌ Error listening to user status in ChatScreen: $error');
    });
  }

  /// Get user status text based on online status and privacy settings
  String _getUserStatusText() {
    if (_currentUser.status == 'online' && _currentUser.appSettings.activityStatus) {
      return 'Online';
    }

    if (_currentUser.lastSeen != null) {
      return _formatLastSeen(_currentUser.lastSeen!);
    }

    return 'Offline';
  }

  /// Format lastSeen timestamp to user-friendly text
  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      // For dates older than a week, show the actual date
      return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  /// Scroll to bottom of message list
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

  /// Handle message send
  void _handleSendMessage(ChatController chatController) {
    if (chatController.messageController.text.trim().isNotEmpty) {
      chatController.sendMessage(widget.user.uid);
      _scrollToBottom();
    }
  }

  /// Build shimmer loading effect for messages
  Widget _buildLoadingWidget() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        final isCurrentUser = index % 2 == 0;
        return _buildShimmerMessageBubble(isCurrentUser, index);
      },
    );
  }

  /// Build individual shimmer message bubble
  Widget _buildShimmerMessageBubble(bool isCurrentUser, int index) {
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
                radius: 18,
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Message bubble shimmer
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isCurrentUser 
                          ? const Radius.circular(16) 
                          : const Radius.circular(4),
                      bottomRight: isCurrentUser 
                          ? const Radius.circular(4) 
                          : const Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: isCurrentUser 
                        ? CrossAxisAlignment.end 
                        : CrossAxisAlignment.start,
                    children: [
                      // Message text lines
                      Container(
                        width: double.infinity,
                        height: 14,
                        color: Colors.grey[300],
                      ),
                      if (index % 3 != 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.35,
                          height: 14,
                          color: Colors.grey[300],
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Time shimmer
                      Container(
                        width: 35,
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
                radius: 18,
                backgroundColor: Colors.grey[300],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget(ChatController chatController) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${chatController.error}',
              style: pStyleBlack14400.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                chatController.clearError();
                _isInitialized = false;
                _initializeChat();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty messages widget
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
              'Start the conversation with ${widget.user.fullName}!',
              style: pStyleBlack12400.copyWith(
                color: AppColors.darkGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build messages list
  Widget _buildMessagesList(ChatController chatController) {
    if (chatController.messages.isEmpty) {
      return _buildEmptyMessagesWidget();
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chatController.messages.length,
      itemBuilder: (context, index) {
        final message = chatController.messages[index];
        final isCurrentUser = chatController.isMessageFromCurrentUser(message);
        final profileImage = chatController.getUserProfileImage(message.sender);

        // Add additional properties for upload state
        final additionalProps = {
          'isOptimistic': chatController.isMessageOptimistic(message.id),
          'isUploading': chatController.isMessageUploading(message.id),
          'uploadProgress': chatController.getMessageUploadProgress(message.id),
          'isFailed': chatController.isMessageFailed(message.id),
        };

        return ChatBubbleFirebase(
          message: message,
          isCurrentUser: isCurrentUser,
          profileImage: profileImage.toString(),
          additionalProps: additionalProps,
          onDeleteMessage: (messageId) {
            chatController.deleteMessage(messageId);
          },
        );
      },
    );
  }


  /// Build message input area
  Widget _buildMessageInput(ChatController chatController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.gray20),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Message input field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gray20),
                ),
                child: TextField(
                  style: pStyleBlack12400,
                  controller: chatController.messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    hintStyle: pStyleBlack12400.copyWith(
                      color: AppColors.darkGrey,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSendMessage(chatController),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!chatController.hasMessageText)
              GestureDetector(
                onTap: () => _showMediaPicker(context, chatController),
                child: SvgPicture.asset(AppImages.fileButton),
              ),
            SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: () => _handleSendMessage(chatController),
              child: SvgPicture.asset(
                AppImages.sendButton,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build group event button
  Widget _buildGroupEventButton() {
    if (widget.type != 'Groups') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: CustomButton(
        text: '🎉 Create Group Event',
        onTap: () {
          Navigator.pushNamed(context, RoutesName.addEventScreen);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(widget.type);
    return Scaffold(
      appBar: CustomAppBar2(
        title: Column(
          spacing: 2,
          children: [
            Text(
              widget.user.fullName,
              style: pjsStyleBlack18600.copyWith(color: AppColors.black),
            ),
            if (_currentUser.appSettings.activityStatus)
              Text(
                _getUserStatusText(),
                style: pjsStyleBlack10600.copyWith(color: AppColors.darkGrey),
              ),
          ],

        ),

        titleOnTap: () {
          if (widget.type == 'Private' || widget.type == 'Local') {
            Navigator.pushNamed(context, RoutesName.privateChatSettingScreen,arguments: widget.user);
          }
        },
        onSetting: widget.type == 'Groups'
            ? () {
          Navigator.pushNamed(context, RoutesName.groupChatSettingScreen);
        }
            : null,
      ),
      body: Consumer<ChatController>(
        builder: (context, chatController, child) {
          // Handle error state
          if (chatController.state == ChatState.error) {
            return _buildErrorWidget(chatController);
          }

          // Always try to show messages if available (cached or real-time)
          bool hasMessages = chatController.messages.isNotEmpty;
          bool isLoading = chatController.state == ChatState.loading;

          // Auto-scroll when new messages arrive
          if (hasMessages) {
            _scrollToBottom();
          }

          return Column(
            children: [
              // Show subtle loading indicator for general loading or media uploads
              if ((isLoading && hasMessages) || chatController.isUploadingFile || 
                  chatController.messages.any((msg) => chatController.isMessageUploading(msg.id)))
                Container(
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withOpacity(0.3)),
                  ),
                ),
              
              // Messages list - show messages if available, otherwise loading or empty state
              Expanded(
                child: hasMessages 
                    ? _buildMessagesList(chatController)
                    : isLoading 
                        ? _buildLoadingWidget()
                        : _buildEmptyMessagesWidget(),
              ),
              
              _buildGroupEventButton(),
              _buildMessageInput(chatController),
            ],
          );
        },
      ),
    );
  }

  void _showMediaPicker(BuildContext context, ChatController chatController) async {
    final file = await chatController.pickImageOrVideo();
    if (file != null && chatController.selectedFileType != null) {
      // Navigate to media preview screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaPreviewScreen(
            mediaFile: file,
            mediaType: chatController.selectedFileType!,
            onCancel: () {
              chatController.clearSelectedFile();
            },
            onSend: (caption) {
              chatController.sendMediaMessage(
                receiverId: widget.user.uid,
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
    _userStatusSubscription?.cancel();

    // Reset current chat state but maintain cache and singleton
    _chatController.resetCurrentChat();
    
    super.dispose();
  }
}
