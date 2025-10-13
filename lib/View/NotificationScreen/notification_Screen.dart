import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../../Model/notification_Model.dart';
import '../../Model/connectionNotificationModel.dart';
import '../../Provider/notificationScreenProvider.dart';
import '../../core/utils/components/CustomButton.dart';
import '../../core/services/firebase_services.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../core/const/app_color.dart';
import '../../core/const/custamSnackBar.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/routes/routes.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

// Separate widget for notifications list to minimize rebuilds
class _NotificationsList extends StatefulWidget {
  const _NotificationsList();

  @override
  State<_NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends State<_NotificationsList> {
  bool _hasInitiallyLoaded = false;
  List<ConnectionNotificationModel> _lastConnectionNotifications = [];
  List<NotificationModel> _lastEventNotifications = [];

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationScreenProvider >(
      builder: (context, provider, _) {
        return StreamBuilder<List<ConnectionNotificationModel>>(
          stream: provider.getConnectionNotificationsStream(),
          builder: (context, connectionSnapshot) {
            return StreamBuilder<List<NotificationModel>>(
              stream: provider.getNotificationsStream(),
              builder: (context, eventSnapshot) {
                // Check if we have data from either stream
                final hasConnectionData = connectionSnapshot.hasData;
                final hasEventData = eventSnapshot.hasData;

                // Get current data or use last known data
                final connectionNotifications = connectionSnapshot.hasData 
                    ? connectionSnapshot.data! 
                    : _lastConnectionNotifications;
                final eventNotifications = eventSnapshot.hasData 
                    ? eventSnapshot.data! 
                    : _lastEventNotifications;

                // Update cached data when new data arrives
                if (connectionSnapshot.hasData) {
                  _lastConnectionNotifications = connectionSnapshot.data!;
                }
                if (eventSnapshot.hasData) {
                  _lastEventNotifications = eventSnapshot.data!;
                }

                // Mark as loaded once we get data from at least one stream
                if ((hasConnectionData || hasEventData) &&
                    !_hasInitiallyLoaded) {
                  _hasInitiallyLoaded = true;
                }

                // Only show shimmer on very first load before any data arrives AND we have no cached data
                // BUT NOT when we're performing operations (like accepting connections, following back)
                if (!_hasInitiallyLoaded &&
                    _lastConnectionNotifications.isEmpty &&
                    _lastEventNotifications.isEmpty &&
                    !provider.isPerformingOperation &&
                    (connectionSnapshot.connectionState == ConnectionState.waiting ||
                        eventSnapshot.connectionState == ConnectionState.waiting)) {
                  return _buildNotificationShimmer();
                }

                // If no notifications at all (including cached)
                if (connectionNotifications.isEmpty &&
                    eventNotifications.isEmpty &&
                    _hasInitiallyLoaded) {
                  return const Center(child: Text('No notifications yet.'));
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ListView(
                    key: ValueKey('notifications_${connectionNotifications.length}_${eventNotifications.length}'),
                    children: [
                      // Connection Notifications
                      if (connectionNotifications.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Social Activity',
                            style: pjsStyleBlack16600.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        ...connectionNotifications.map(
                          (notification) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            key: ValueKey('connection_${notification.id}'),
                            child: _ConnectionNotificationTile(
                              notification: notification,
                            ),
                          ),
                        ),
                      ],

                      // Event Notifications
                      if (eventNotifications.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Events & Updates',
                            style: pjsStyleBlack16600.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        ...eventNotifications.map((notification) => 
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            key: ValueKey('event_${notification.eventId}_${notification.createdAt.millisecondsSinceEpoch}'),
                            child: _EventNotificationTile(notification: notification),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationShimmer() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.gray20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Shimmer(
            duration: const Duration(seconds: 1),
            interval: const Duration(milliseconds: 800),
            color: Colors.white,
            colorOpacity: 0.9,
            enabled: true,
            direction: ShimmerDirection.fromLTRB(),
            child: ListTile(
              title: Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              trailing: Container(
                height: 12,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Separate widget for connection notifications to minimize rebuilds
class _ConnectionNotificationTile extends StatelessWidget {
  final ConnectionNotificationModel notification;

  const _ConnectionNotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: FirebaseServices.instance.getUserInfoForNotification(
        notification.fromUserId,
      ),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildConnectionShimmerTile();
        }

        final userInfo =
            userSnapshot.data ?? {'name': 'Unknown User', 'image': ''};
        final userName = userInfo['name']!;
        final userImage = userInfo['image']!;

        // Generate title and message based on notification type
        String title, message;
        if (notification.type == 'connection_request') {
          title = 'New Connection Request';
          message = '$userName wants to connect with you';
        } else if (notification.type == 'follow') {
          title = 'New Follower';
          message = '$userName started following you';
        } else if (notification.type == 'follow_back') {
          title = 'Followed You Back';
          message = '$userName followed you back';
        } else if (notification.type == 'like') {
          title = 'New Like';
          message = '$userName liked your post';
        } else if (notification.type == 'comment') {
          title = 'Comment your post';
          final commentText = notification.commentText;
          if (commentText != null && commentText.isNotEmpty) {
            message = commentText;
          } else {
            message = '$userName commented on your post';
          }
        } else {
          title = 'Connection Accepted';
          message = '$userName accepted your connection request';
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 5, backgroundColor: AppColors.primary),
                    const SizedBox(width: 10),
                    // User avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: userImage.isNotEmpty
                          ? NetworkImage(userImage)
                          : null,
                      backgroundColor: AppColors.lightGrey,
                      child: userImage.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Notification content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                flex: 2,
                                child: Text(
                                  userName,
                                  style: pjsStyleBlack14600.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                flex: 3,
                                child: Text(
                                  title,
                                  style: pjsStyleBlack14500.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  message,
                                  style: pjsStyleBlack12500.copyWith(
                                    color: AppColors.darkBlue600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              // Time
                              Flexible(
                                child: Text(
                                  _getTimeAgo(notification.createdAt),
                                  style: pjsStyleBlack12500.copyWith(
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Post preview for like/comment notifications
                    if (notification.type == 'like' ||
                        notification.type == 'comment') ...[
                      if (notification.postImageUrl != null &&
                          notification.postImageUrl!.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () async {
                            Navigator.pushNamed(
                              context,
                              RoutesName.profileScreen,
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              notification.postImageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.image,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        GestureDetector(
                          onTap: () async {
                            Navigator.pushNamed(
                              context,
                              RoutesName.profileScreen,
                            );
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.text_fields,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
                // Action buttons for connection requests
                if (notification.type == 'connection_request' &&
                    notification.status == 'pending') ...[
                  const SizedBox(height: 12),
                  Consumer<NotificationScreenProvider>(
                    builder: (context, provider, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Accept',
                              onTap: provider.isAccepting
                                  ? null
                                  : () async {
                                      try {
                                        await provider.acceptConnectionRequest(
                                          notification,
                                        );
                                        if (context.mounted) {
                                          CustomSnackBar.showSuccess(
                                            context,
                                            'Connection request accepted',
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          CustomSnackBar.showFailure(
                                            context,
                                            'Couldn\'t accept connection request',
                                          );
                                        }
                                      }
                                    },
                              backgroundColor: AppColors.primary,
                              textColor: AppColors.white,
                              height: 32,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomButton(
                              text: 'Decline',
                              onTap: () async {
                                try {
                                  await provider.declineConnectionRequest(
                                    notification,
                                  );
                                  if (context.mounted) {
                                    CustomSnackBar.showWarning(
                                      context,
                                      'Connection request declined',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    CustomSnackBar.showFailure(
                                      context,
                                      'Couldn\'t decline connection request',
                                    );
                                  }
                                }
                              },
                              backgroundColor: AppColors.white,
                              borderColor: AppColors.garyModern400,
                              textColor: AppColors.garyModern400,
                              height: 32,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ] else if (notification.status == 'accepted') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Connected',
                      style: pjsStyleBlack12500.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                // Action buttons for follow notifications
                if (notification.type == 'follow') ...[
                  const SizedBox(height: 12),
                  Consumer<NotificationScreenProvider>(
                    builder: (context, notifProvider, _) {
                      final cached = notifProvider.getFollowStatus(
                        notification.fromUserId,
                      );
                      final isLoading = notifProvider.isFollowStatusLoading(
                        notification.fromUserId,
                      );
                      final isFollowing = cached ?? false;

                      // Load status after frame is built to avoid setState during build
                      if (cached == null && !isLoading) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          notifProvider.ensureFollowStatusLoaded(
                            notification.fromUserId,
                          );
                        });
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: isLoading
                                  ? 'Please wait…'
                                  : (isFollowing ? 'Unfollow' : 'Follow Back'),
                              onTap: isLoading
                                  ? null
                                  : () async {
                                      try {
                                        if (isFollowing) {
                                          await notifProvider.unfollowUser(
                                            notification.fromUserId,
                                          );
                                          if (context.mounted) {
                                            CustomSnackBar.showWarning(
                                              context,
                                              'You unfollowed',
                                            );
                                          }
                                        } else {
                                          await notifProvider.followBackUser(
                                            notification.fromUserId,
                                          );
                                          if (context.mounted) {
                                            CustomSnackBar.showSuccess(
                                              context,
                                              'You followed back',
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          CustomSnackBar.showFailure(
                                            context,
                                            'Action failed, please try again',
                                          );
                                        }
                                      }
                                    },
                              backgroundColor: isFollowing
                                  ? AppColors.white
                                  : AppColors.primary,
                              borderColor: isFollowing
                                  ? AppColors.garyModern400
                                  : null,
                              textColor: isFollowing
                                  ? AppColors.garyModern400
                                  : AppColors.white,
                              height: 32,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomButton(
                              text: 'View Profile',
                              onTap: () async {
                                try {
                                  final provider =
                                      Provider.of<NotificationScreenProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final userData = await provider.getUserData(
                                    notification.fromUserId,
                                  );
                                  if (context.mounted && userData != null) {
                                    Navigator.pushNamed(
                                      context,
                                      RoutesName.userDetailScreen,
                                      arguments: {'user': userData},
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    CustomSnackBar.showFailure(
                                      context,
                                      'Couldn\'t load profile',
                                    );
                                  }
                                }
                              },
                              backgroundColor: AppColors.white,
                              borderColor: AppColors.primary,
                              textColor: AppColors.primary,
                              height: 32,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionShimmerTile() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Shimmer(
        duration: const Duration(seconds: 1),
        interval: const Duration(milliseconds: 800),
        color: Colors.white,
        colorOpacity: 0.9,
        enabled: true,
        direction: ShimmerDirection.fromLTRB(),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 10,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// // Separate widget for event notifications
class _EventNotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _EventNotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(notification.eventName, style: pjsStyleBlack14500),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(notification.message, style: pjsStyleBlack12500),
            Text(
              notification.eventTime,
              style: pjsStyleBlack14500.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        trailing: Text(
          '${notification.createdAt.hour}:${notification.createdAt.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 12),
        ),
        onTap: () {
          Navigator.pushNamed(context, RoutesName.festivalsEvents);
        },
      ),
    );
  }
}

//
class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          'Notifications',
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(children: [Expanded(child: _NotificationsList())]),
      ),
    );
  }
}
