import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Provider/SelectionProvider.dart';
import '../Provider/UserDetailProvider.dart';
import '../Provider/UserPostsProvider.dart';
import '../Provider/MemoryProvider.dart';
import '../Model/AddPostModel.dart';
import '../Model/connectionModel.dart';
import '../Widgets/PlaceCard.dart';
import '../Widgets/PostCard.dart';
import '../Widgets/shimmer_widgets.dart';
import '../WorldMap/WorldMapScreen.dart';
import '../core/const/app_color.dart';
import '../core/const/app_images.dart';
import '../core/const/custamSnackBar.dart';
import '../core/theme/app_text_style.dart';
import '../core/utils/components/CustomButton.dart';
import '../core/utils/routes/routes.dart';
import '../Model/userModel.dart';
import '../core/services/firebase_services.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel user;
  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<UserDetailProvider>();
      provider.resetForNewUser();
      provider.checkFollowingStatus(widget.user.uid);
      provider.checkConnectionStatus(widget.user.uid);
    });
  }

  int getAgeFromUser(UserModel user) {
    if (user.dateOfBirth == null) return 0;
    final now = DateTime.now();
    int age = now.year - user.dateOfBirth!.year;
    if (now.month < user.dateOfBirth!.month ||
        (now.month == user.dateOfBirth!.month &&
            now.day < user.dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown time';
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

  Widget _buildPostsSection() {
    return Consumer<UserPostsProvider>(
      builder: (context, userPostsProvider, child) {
        final postsStream = userPostsProvider
            .getSpecificUserPostsStream(widget.user.uid);

        if (postsStream == null) {
          return const Center(
            child: Text(
              'Unable to load posts',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: postsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return ListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return const PostCardShimmerWidget();
                },
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              );
            }

            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    SvgPicture.asset(
                      AppImages.cameraIcon,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No posts yet',
                      style: pjsStyleBlack16600,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.user.fullName} hasn\'t shared any posts yet',
                      style: pjsStyleBlack14400.copyWith(
                        color: AppColors.garyModern400,
                      ),
                    ),
                  ],
                ),
              );
            }

            final posts = snapshot.data!.docs.map((doc) {
              return AddPost.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            }).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];

                return PostCard(
                  shareCount: post.shares,
                  latitude: post.location.latitude,
                  longitude: post.location.longitude,
                  postId: post.postId,
                  postOwnerId: post.userId,
                  userAvatar:
                      widget.user.profileImageUrl ??
                      AppImages.bestRestaurants,
                  userName: widget.user.fullName,
                  userLocation:
                      post.location.address.isNotEmpty
                      ? post.location.address
                      : 'Unknown Location',
                  timeAgo: _getTimeAgo(post.createdAt),
                  postImages: post.images,
                  description: post.caption,
                  hashtags: post.tags.join(' '),
                  initialLikeCount: post.likes,
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      top: false,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary2,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50, bottom: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        Column(
                          spacing: 5,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.lightGrey.withValues(
                                alpha: 0.60,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            Row(
                              spacing: 10,
                              children: [
                                Expanded(
                                  child: Row(
                                    spacing: 10,
                                    children: [
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child:
                                              widget.user.profileImageUrl !=
                                                  null
                                              ? Image.network(
                                                  widget.user.profileImageUrl!,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (
                                                        context,
                                                        child,
                                                        loadingProgress,
                                                      ) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }
                                                        return const CircleImageShimmerWidget(
                                                          size: 80,
                                                        );
                                                      },
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          color:
                                                              AppColors.white,
                                                          child: const Icon(
                                                            Icons.person,
                                                            size: 40,
                                                            color: Colors.grey,
                                                          ),
                                                        );
                                                      },
                                                )
                                              : Container(
                                                  color: AppColors.white,
                                                  child: const Icon(
                                                    Icons.person,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.user.fullName.isNotEmpty
                                                ? widget.user.fullName
                                                : 'Unknown User',
                                            style: pjsStyleBlack15700.copyWith(
                                              color: AppColors.white,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Row(
                                            spacing: 5,
                                            children: [
                                              Text(
                                                widget.user.homeCity.isNotEmpty
                                                    ? widget.user.homeCity
                                                    : 'Unknown City',
                                                style: pjsStyleBlack12400
                                                    .copyWith(
                                                      color: AppColors.white,
                                                    ),
                                              ),
                                              Text(
                                                '${getAgeFromUser(widget.user)} years',
                                                style: pjsStyleBlack12400
                                                    .copyWith(
                                                      color: AppColors.white,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            widget.user.currentCountry != null
                                                ? 'Currently in ${widget.user.currentCountry}'
                                                : 'Location not available',
                                            style: pjsStyleBlack10400.copyWith(
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          widget.user.bio ?? 'No bio available',
                          style: pjsStyleBlack15400.copyWith(
                            color: AppColors.white,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        StreamBuilder<int>(
                          stream: FirebaseServices.instance
                              .getVisitedCountriesCountStream(widget.user.uid),
                          builder: (context, snapshot) {
                            final visitedCount = snapshot.data ?? 0;
                            return CustomButton(
                              text: '$visitedCount Countries Visited',
                              onTap: () {},
                              svgAsset: AppImages.word,
                              backgroundColor: AppColors.white.withValues(
                                alpha: 0.14,
                              ),
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              spacing: 5,
                              children: [
                                Text(
                                  'Posts',
                                  style: pjsStyleBlack15700.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                                StreamBuilder<String>(
                                  stream: FirebaseServices.instance
                                      .getPostsCountStream(widget.user.uid),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.data ??
                                          widget.user.socialStats.postsCount,
                                      style: pjsStyleBlack15700.copyWith(
                                        color: AppColors.white,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Column(
                              spacing: 5,
                              children: [
                                Text(
                                  'Connects',
                                  style: pjsStyleBlack15700.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                                StreamBuilder<String>(
                                  stream: FirebaseServices.instance
                                      .getConnectionsCountStream(
                                        widget.user.uid,
                                      ),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.data ??
                                          widget
                                              .user
                                              .socialStats
                                              .connectionsCount,
                                      style: pjsStyleBlack15700.copyWith(
                                        color: AppColors.white,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Column(
                              spacing: 5,
                              children: [
                                Text(
                                  'Following',
                                  style: pjsStyleBlack15700.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                                StreamBuilder<String>(
                                  stream: FirebaseServices.instance
                                      .getFollowingCountStream(widget.user.uid),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.data ??
                                          widget
                                              .user
                                              .socialStats
                                              .followingCount,
                                      style: pjsStyleBlack15700.copyWith(
                                        color: AppColors.white,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Column(
                              spacing: 5,
                              children: [
                                Text(
                                  'Followers',
                                  style: pjsStyleBlack15700.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                                StreamBuilder<String>(
                                  stream: FirebaseServices.instance
                                      .getFollowersCountStream(widget.user.uid),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.data ??
                                          widget
                                              .user
                                              .socialStats
                                              .followersCount,
                                      style: pjsStyleBlack15700.copyWith(
                                        color: AppColors.white,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: context.screenHeight * 0.02,
                ),
                child: Column(
                  spacing: 10,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.screenWidth * 0.03,
                      ),
                      child: Row(
                        spacing: 5,
                        children: [
                          Consumer<UserDetailProvider>(
                            builder: (context, userDetailProvider, child) {
                              final buttonText = userDetailProvider
                                  .getConnectionButtonText();
                              final isPending =
                                  userDetailProvider.connectionStatus ==
                                  ConnectionStatus.pending;
                              final isConnected =
                                  userDetailProvider.connectionStatus ==
                                  ConnectionStatus.accepted;
                              final isLongText = buttonText.length > 10;
                              return Flexible(
                                flex: isLongText ? 2 : 1,
                                fit: FlexFit.loose,
                                child: CustomButton(
                                  text: buttonText,
                                  onTap: () async {
                                    final currentStatus =
                                        userDetailProvider.connectionStatus;
                                    try {
                                      await userDetailProvider.toggleConnection(
                                        widget.user,
                                      );

                                      if (context.mounted) {
                                        switch (currentStatus) {
                                          case ConnectionStatus.none:
                                            CustomSnackBar.showSuccess(
                                              context,
                                              'Connection request sent!',
                                            );
                                            break;
                                          case ConnectionStatus.pending:
                                            CustomSnackBar.showWarning(
                                              context,
                                              'Connection request cancelled',
                                            );
                                            break;
                                          case ConnectionStatus.accepted:
                                            CustomSnackBar.showWarning(
                                              context,
                                              'Connection removed',
                                            );
                                            break;
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        CustomSnackBar.showFailure(
                                          context,
                                          'Error: ${e.toString()}',
                                        );
                                      }
                                    }
                                  },
                                  backgroundColor: isConnected
                                      ? AppColors.primary
                                      : isPending
                                      ? AppColors.primary
                                      : AppColors.primary,
                                  textColor: AppColors.white,
                                  height: 40,
                                ),
                              );
                            },
                          ),

                          // Follow Button - flexible width
                          Flexible(
                            fit: FlexFit.loose,
                            child: Consumer<UserDetailProvider>(
                              builder: (context, userDetailProvider, child) {
                                if (!userDetailProvider.hasCheckedStatus &&
                                    userDetailProvider.isLoading) {
                                  return CustomButton(
                                    text: 'Follow',
                                    onTap: null,
                                    backgroundColor: AppColors.white,
                                    borderColor: AppColors.primary,
                                    textColor: AppColors.primary,
                                    height: 40,
                                  );
                                }

                                final buttonText = userDetailProvider.getFollowButtonText();
                                final isFollowing = userDetailProvider.isFollowing;

                                return CustomButton(
                                  text: buttonText,
                                  onTap: () {
                                    userDetailProvider.toggleFollow(widget.user);
                                  },
                                  backgroundColor: isFollowing
                                      ? AppColors.primary
                                      : AppColors.white,
                                  borderColor: AppColors.primary,
                                  textColor: isFollowing
                                      ? AppColors.white
                                      : AppColors.primary,
                                  height: 40,
                                );
                              },
                            ),
                          ),

                          // Message Button - flexible width
                          Flexible(
                            fit: FlexFit.loose,
                            child: CustomButton(
                              text: 'Message',
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RoutesName.chatScreen,
                                  arguments: {'user': widget.user, 'type': 'Private'},
                                );
                                print('Message button tapped');
                              },
                              backgroundColor: AppColors.white,
                              borderColor: AppColors.garyModern400,
                              textColor: AppColors.black,
                              height: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.screenWidth * 0.03,
                      ),
                      child: Consumer<SelectionProvider>(
                        builder: (context, selectionProvider, child) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: 1,
                                    child: GestureDetector(
                                      onTap: () async {
                                        selectionProvider.selectOption(0);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        curve: Curves.easeInOut,
                                        decoration: BoxDecoration(
                                          color: selectionProvider.isSelected(0)
                                              ? AppColors.primary
                                              : AppColors.white,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Posts',
                                                style: pjsStyleBlack14700
                                                    .copyWith(
                                                      color:
                                                          selectionProvider
                                                              .isSelected(0)
                                                          ? AppColors.white
                                                          : AppColors.darkGrey,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    flex: 1,
                                    child: GestureDetector(
                                      onTap: () async {
                                        selectionProvider.selectOption(1);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        curve: Curves.easeInOut,
                                        decoration: BoxDecoration(
                                          color: selectionProvider.isSelected(1)
                                              ? AppColors.primary
                                              : AppColors.white,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Travel',
                                                style: pjsStyleBlack14700
                                                    .copyWith(
                                                      color:
                                                          selectionProvider
                                                              .isSelected(1)
                                                          ? AppColors.white
                                                          : AppColors.darkGrey,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Consumer<SelectionProvider>(
                      builder: (context, selectionProvider, child) {
                        if (selectionProvider.isSelected(0)) {
                          // Check privacy settings
                          final isPrivateAccount = widget.user.appSettings.privateAccount;
                          
                          if (!isPrivateAccount) {
                            // Public account - show posts normally
                            return _buildPostsSection();
                          } else {
                            // Private account - check mutual follow
                            return Consumer<UserDetailProvider>(
                              builder: (context, userDetailProvider, child) {
                                return FutureBuilder<bool>(
                                  future: userDetailProvider.checkMutualFollow(widget.user.uid),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: 3,
                                        itemBuilder: (context, index) {
                                          return const PostCardShimmerWidget();
                                        },
                                      );
                                    }
                                    
                                    final hasMutualFollow = snapshot.data ?? false;
                                    
                                    if (hasMutualFollow) {
                                      // Mutual follow exists - show posts
                                      return _buildPostsSection();
                                    } else {
                                      // No mutual follow - show privacy message
                                      return Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 40),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.lock_outline,
                                                size: 64,
                                                color: AppColors.garyModern400,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'This account is private',
                                                style: pjsStyleBlack16600.copyWith(
                                                  color: AppColors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Follow each other to see posts',
                                                style: pjsStyleBlack14400.copyWith(
                                                  color: AppColors.garyModern400,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            );
                          }
                        } else {
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.screenWidth * 0.03,
                            ),
                            child: Column(
                              spacing: 15,
                              children: [
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(widget.user.uid)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    bool showTravelMap = true;
                                    if (snapshot.hasData && snapshot.data != null) {
                                      final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                      if (userData != null && userData.containsKey('appSettings')) {
                                        final appSettings = userData['appSettings'] as Map<String, dynamic>?;
                                        showTravelMap = appSettings?['showTravelStats'] ?? true;
                                      }
                                    }
                                    if (!showTravelMap) {
                                      return const SizedBox.shrink();
                                    }

                                    return Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Travel Memories',
                                                style: pjsStyleBlack16500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 16,
                                        ),
                                        Consumer<MemoryProvider>(
                                          builder: (context, memoryProvider, child) {
                                            final memoriesStream = memoryProvider
                                                .getSpecificUserMemoriesStream(
                                              widget.user.uid,
                                            );

                                            if (memoriesStream == null) {
                                              return Column(
                                                children: [
                                                  SvgPicture.asset(AppImages.cameraIcon),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'No Travel Memories yet.',
                                                    style: pjsStyleBlack14500.copyWith(
                                                      color: AppColors.garyModern500,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }

                                            return StreamBuilder<QuerySnapshot>(
                                              stream: memoriesStream,
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const TravelMemoryShimmerWidget();
                                                }

                                                if (snapshot.hasError) {
                                                  return Column(
                                                    children: [
                                                      SvgPicture.asset(
                                                        AppImages.cameraIcon,
                                                        color: AppColors.primary,
                                                      ),
                                                      const SizedBox(height: 16),
                                                      Text(
                                                        'Error loading memories',
                                                        style: pjsStyleBlack14500
                                                            .copyWith(color: Colors.red),
                                                      ),
                                                    ],
                                                  );
                                                }

                                                if (!snapshot.hasData ||
                                                    snapshot.data!.docs.isEmpty) {
                                                  return Column(
                                                    children: [
                                                      SvgPicture.asset(
                                                        AppImages.cameraIcon,
                                                      ),
                                                      const SizedBox(height: 16),
                                                      Text(
                                                        'No Travel Memories yet.',
                                                        style: pjsStyleBlack14500
                                                            .copyWith(
                                                          color:
                                                          AppColors.garyModern500,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }

                                                final memories = memoryProvider
                                                    .convertSnapshotToMemories(
                                                  snapshot.data!,
                                                );

                                                return SizedBox(
                                                  height: 190,
                                                  child: ListView.builder(
                                                    scrollDirection: Axis.horizontal,
                                                    itemCount: memories.length,
                                                    itemBuilder: (context, index) {
                                                      final memory = memories[index];
                                                      return Padding(
                                                        padding: const EdgeInsets.only(
                                                          left: 8,
                                                          bottom: 5,
                                                        ),
                                                        child: PlaceCard(
                                                          onTap: () {
                                                            Navigator.pushNamed(
                                                              context,
                                                              RoutesName
                                                                  .travelMemoryScreen,
                                                              arguments: memory,
                                                            );
                                                          },
                                                          imageUrl:
                                                          memory.coverImageUrl ??
                                                              (memory
                                                                  .mediaImageUrls
                                                                  .isNotEmpty
                                                                  ? memory
                                                                  .mediaImageUrls
                                                                  .first
                                                                  : AppImages.onBoarding),
                                                          isNetworkImage:
                                                          memory.coverImageUrl !=
                                                              null ||
                                                              memory
                                                                  .mediaImageUrls
                                                                  .isNotEmpty,
                                                          name: memory.memoryName,
                                                          location: memory.country,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),


                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(widget.user.uid)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    bool showTravelMap = true;
                                    if (snapshot.hasData && snapshot.data != null) {
                                      final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                      if (userData != null && userData.containsKey('appSettings')) {
                                        final appSettings = userData['appSettings'] as Map<String, dynamic>?;
                                        showTravelMap = appSettings?['showTravelMap'] ?? true;
                                      }
                                    }
                                    if (!showTravelMap) {
                                      return const SizedBox.shrink();
                                    }

                                    return Container(
                                      width: double.infinity,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.borderShad,
                                          width: 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 10,
                                          left: 10,
                                          right: 10,
                                          bottom: 5,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              spacing: 5,
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    'Countries Visited',
                                                    style: pjsStyleBlack20700
                                                        .copyWith(
                                                          color: AppColors.black,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: 145,
                                              child: WorldMapScreen(
                                                userId: widget.user.uid,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.borderShad,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.screenWidth * 0.05,
                                    vertical: context.screenHeight * 0.02,
                                  ),
                                  child: Column(
                                    spacing: 10,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'About',
                                        style: pjsStyleBlack14700.copyWith(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Row(
                                        spacing: 3,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              widget.user.bio ??
                                                  'No bio available',
                                              style: pjsStyleBlack10400.copyWith(
                                                color: AppColors.garyModern400,
                                              ),
                                              textAlign: TextAlign.justify,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
