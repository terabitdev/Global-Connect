import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/ChatBubble.dart';
import '../../Provider/localChatProvider.dart';
import '../../Provider/GroupChatProvider.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/services/NotificationService/NotificationService.dart';
import '../../core/utils/components/CustomButton.dart';
import '../../core/utils/routes/routes.dart';
import '../../Model/localEvenModel.dart';
import '../../Widgets/RestaurantCard.dart';
import 'MediaPreviewScreen.dart';

class LocalChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String messageType;
  final bool isRead;

  LocalChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.messageType,
    required this.isRead,
  });

  factory LocalChatMessage.fromMap(
    Map<String, dynamic> data,
    String messageId,
  ) {
    return LocalChatMessage(
      id: messageId,
      senderId: data['senderId'] ?? '',
      text: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageType: data['messageType'] ?? 'text',
      isRead: data['isRead'] ?? false,
    );
  }
}

class LocalGroupChatScreen extends StatefulWidget {
  final String? cityName;
  const LocalGroupChatScreen({super.key, this.cityName});

  @override
  State<LocalGroupChatScreen> createState() => _LocalGroupChatScreenState();
}

class _LocalGroupChatScreenState extends State<LocalGroupChatScreen> {
  final NotificationService _notificationService = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  void _initializeScreen() {
    final provider = Provider.of<LocalChatProvider>(context, listen: false);
    provider.initializeForScreen(cityName: widget.cityName);
    provider.addListener(provider.onProviderChanged);
    _notificationService.markNotificationAsRead(provider.displayCityName);
  }

  @override
  void dispose() {
    final provider = Provider.of<LocalChatProvider>(context, listen: false);
    provider.removeListener(provider.onProviderChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalChatProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: () => provider.dismissKeyboard(),
          child: SafeArea(
            bottom: true,
            top: false,
            child: Scaffold(
              appBar: CustomAppBar2(
                title: Text(
                  provider.displayCityName,
                  style: pjsStyleBlack18600.copyWith(color: AppColors.black),
                ),
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Column(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          spacing: 2,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            /// City Info
                            Expanded(
                              flex: 2,
                              child: Column(
                                spacing: 3,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    '${provider.displayCityName} Local Chat',
                                    style: pjsStyleBlack10700.copyWith(
                                      color: AppColors.black,
                                    ),
                                  ),
                                  Text(
                                    'Connect with travelers in ${provider.displayCityName}',
                                    style: pjsStyleBlack9400.copyWith(
                                      color: AppColors.darkGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// Event button
                            Flexible(
                              fit: FlexFit.loose,
                              child: CustomButton(
                                backgroundColor: AppColors.white,
                                textColor: AppColors.darkGrey,
                                height: 28,
                                iconSize: 10,
                                borderColor: AppColors.garyModern200,
                                text: 'Event',
                                textStyle: pjsStyleBlack12400,
                                svgAsset: AppImages.add,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.createLocalEvent,
                                    arguments: {
                                      'cityName': provider.displayCityName,
                                      'eventName': 'Local Event',
                                    },
                                  );
                                },
                              ),
                            ),

                            const SizedBox(width: 5),

                            /// Members button
                            Flexible(
                              fit: FlexFit.loose,
                              child: CustomButton(
                                backgroundColor: AppColors.white,
                                textColor: AppColors.darkGrey,
                                height: 28,
                                iconSize: 10,
                                borderColor: AppColors.garyModern200,
                                text: 'Members',
                                textStyle: pjsStyleBlack12400,
                                svgAsset: AppImages.group,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.localChatMembers,
                                  );
                                },
                              ),
                            ),

                            // const SizedBox(width: 5),
                            //
                            // /// Settings icon
                            // // SvgPicture.asset(
                            // //   AppImages.setting,
                            // //   color: AppColors.black,
                            // //   height: 14,
                            // //   width: 14,
                            // // ),
                          ],
                        ),
                        Row(
                          spacing: 2,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            /// Event button
                            Flexible(
                              fit: FlexFit.loose,
                              child: CustomButton(
                                backgroundColor:
                                    provider.chatFilterMode == 'Countrymen'
                                    ? AppColors.primary
                                    : AppColors.white,
                                textColor:
                                    provider.chatFilterMode == 'Countrymen'
                                    ? AppColors.white
                                    : AppColors.darkGrey,
                                height: 28,
                                iconSize: 14,
                                borderColor:
                                    provider.chatFilterMode == 'Countrymen'
                                    ? AppColors.primary
                                    : AppColors.garyModern200,
                                text: 'Countrymen',
                                textStyle: pjsStyleBlack12400.copyWith(
                                  color: provider.chatFilterMode == 'Countrymen'
                                      ? AppColors.white
                                      : AppColors.darkGrey,
                                ),
                                svgAsset: AppImages.countrymen,
                                onTap: () {
                                  final provider =
                                      Provider.of<LocalChatProvider>(
                                        context,
                                        listen: false,
                                      );
                                  provider.setChatFilterMode('Countrymen');
                                },
                              ),
                            ),

                            const SizedBox(width: 5),

                            /// Members button
                            Flexible(
                              fit: FlexFit.loose,
                              child: CustomButton(
                                backgroundColor:
                                    provider.chatFilterMode == 'Global'
                                    ? AppColors.primary
                                    : AppColors.white,
                                textColor: provider.chatFilterMode == 'Global'
                                    ? AppColors.white
                                    : AppColors.darkGrey,
                                height: 28,
                                iconSize: 14,
                                borderColor: provider.chatFilterMode == 'Global'
                                    ? AppColors.primary
                                    : AppColors.garyModern200,
                                text: 'Global',
                                textStyle: pjsStyleBlack12400.copyWith(
                                  color: provider.chatFilterMode == 'Global'
                                      ? AppColors.white
                                      : AppColors.darkGrey,
                                ),
                                svgAsset: AppImages.word,
                                onTap: () {
                                  final provider =
                                      Provider.of<LocalChatProvider>(
                                        context,
                                        listen: false,
                                      );
                                  provider.setChatFilterMode('Global');
                                },
                              ),
                            ),
                          ],
                        ),
                        Divider(
                          color: AppColors.darkGrey.withOpacity(0.50),
                          thickness: 1,
                        ),
                      ],
                    ),
                  ),
                  // Messages List
                  Expanded(
                    child: provider.isLoading
                        ? _buildLoadingWidget()
                        : provider.currentTimelineItems.isEmpty
                        ? _buildEmptyState()
                        : _buildTimelineList(provider),
                  ),

                  // Error Message
                  if (provider.errorMessage != null)
                    _buildErrorMessage(provider),

                  // Message Input
                  _buildMessageInput(provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        final isCurrentUser = index % 3 != 0;
        return _buildShimmerMessageBubble(isCurrentUser);
      },
    );
  }

  Widget _buildShimmerMessageBubble(bool isCurrentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
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
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isCurrentUser) ...[
                        Container(
                          width: MediaQuery.of(context).size.width * 0.3,
                          height: 12,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 4),
                      ],
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
                      Container(width: 40, height: 10, color: Colors.grey[300]),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.darkGrey),
          SizedBox(height: 16),
          Text(
            'No messages yet',
            style: pjsStyleBlack16600.copyWith(color: AppColors.darkGrey),
          ),
          SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: pjsStyleBlack12400.copyWith(color: AppColors.darkGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList(LocalChatProvider provider) {
    final items = provider.currentTimelineItems;
    final totalItems = items.length + (provider.hasMoreMessages ? 1 : 0);

    return ListView.builder(
      controller: provider.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Show loading indicator for older messages
        if (index == 0 && provider.hasMoreMessages) {
          return provider.isLoadingMore
              ? _buildLoadingMoreWidget()
              : const SizedBox.shrink();
        }

        final itemIndex = provider.hasMoreMessages ? index - 1 : index;
        if (itemIndex >= items.length) return const SizedBox.shrink();

        final item = items[itemIndex] as Map<String, dynamic>;
        final String itemType = item['itemType'] as String;

        if (itemType == 'event') {
          final LocalEventModel e = item['data'] as LocalEventModel;
          return LocalEventCard(
            key: ValueKey('event_${e.id}'),
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
            cityName: provider.displayCityName,
            createdById: e.createdById,
            eventLatitude: e.latitude,
            eventLongitude: e.longitude,
            onTap: () {},
          );
        } else {
          final Map<String, dynamic> msg = item['data'] as Map<String, dynamic>;
          final m = LocalChatMessage.fromMap(msg, msg['messageId'] ?? '');
          final isCurrentUser = m.senderId == provider.currentUserId;

          // Handle different content sources for media messages
          String messageContent = m.text;

          // For optimistic media messages, use local file
          if (msg['isOptimistic'] == true && msg['localFile'] != null) {
            // Keep the message text as is, let ChatBubble handle local file display
            messageContent = m.text;
          }
          // For uploaded messages, use Firebase Storage URL
          else if ((m.messageType == 'image' || m.messageType == 'video') &&
              msg['imageUrl'] != null) {
            messageContent = msg['imageUrl'];
          }

          final bubbleMessage = Message(
            id: m.id,
            messageId: msg['messageId'] ?? m.id,
            senderId: m.senderId,
            senderName: '',
            senderProfileImage: '', // Will be fetched dynamically in ChatBubble
            text: messageContent,
            sentOn: m.timestamp,
            messageType: m.messageType,
            isRead: m.isRead,
          );

          // Add additional properties for special states
          final bubbleProps = {
            'isOptimistic': msg['isOptimistic'] ?? false,
            'isUploading': msg['isUploading'] ?? false,
            'uploadProgress': msg['uploadProgress'] ?? 0.0,
            'isFailed': msg['isFailed'] ?? false,
            'localFile': msg['localFile'],
            'imageUrl': msg['imageUrl'],
          };

          return ChatBubble(
            key: ValueKey('msg_${bubbleMessage.messageId ?? bubbleMessage.id}'),
            message: bubbleMessage,
            isCurrentUser: isCurrentUser,
            additionalProps: bubbleProps,
            onDeleteMessage: (messageId) {
              provider.deleteMessage(messageId, provider.displayCityName);
            },
            onRetryMessage: (messageId) {
              provider.retryFailedMessage(messageId);
            },
          );
        }
      },
    );
  }

  Widget _buildLoadingMoreWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: CircleAvatar(radius: 16, backgroundColor: Colors.grey[300]),
          ),
          const SizedBox(width: 8),
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

  // Widget _buildCreateEventButton(LocalChatProvider provider) {
  //   return Padding(
  //     padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
  //     child: CustomButton(
  //       text: '🎉 Create Local Event',
  //       onTap: () {
  //         Navigator.pushNamed(
  //           context,
  //           RoutesName.createLocalEvent,
  //           arguments: {
  //             'cityName': provider.displayCityName,
  //             'eventName': 'Local Event',
  //           },
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _buildErrorMessage(LocalChatProvider provider) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red.shade50,
      child: Text(
        provider.errorMessage!,
        style: TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMessageInput(LocalChatProvider provider) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray20)),
      ),
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
                style: pStyleBlack12400,
                controller: provider.messageController,
                focusNode: provider.messageFocusNode,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  hintStyle: pStyleBlack12400.copyWith(
                    color: AppColors.darkGrey,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => provider.handleSendMessage(),
                onTap: () => provider.onTextFieldTap(),
              ),
            ),
          ),
          SizedBox(width: 8),
          if (!provider.hasMessageText)
            GestureDetector(
              onTap: () => _showMediaPicker(context, provider),
              child: SvgPicture.asset(AppImages.fileButton),
            ),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () => provider.handleSendMessage(),
            child: SvgPicture.asset(AppImages.sendButton),
          ),
        ],
      ),
    );
  }

  void _showMediaPicker(
    BuildContext context,
    LocalChatProvider provider,
  ) async {
    final file = await provider.pickImageOrVideo();
    if (file != null && provider.selectedFileType != null) {
      // Navigate to media preview screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaPreviewScreen(
            mediaFile: file,
            mediaType: provider.selectedFileType!,
            onCancel: () {
              provider.clearSelectedFile();
            },
            onSend: (caption) {
              provider.handleSendMessage(caption: caption);
            },
          ),
        ),
      );
    }
  }
}
