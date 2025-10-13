import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Provider/SelectionProvider.dart';
import '../../Provider/user_profile_provider.dart';
import '../../Provider/UserPostsProvider.dart';
import '../../Provider/MemoryProvider.dart';
import '../../Model/AddPostModel.dart';
import '../../Model/createMemoryModel.dart';
import '../../Widgets/DonutChartPainter.dart';
import '../../Widgets/PlaceCard.dart';
import '../../Widgets/PostCard.dart';
import '../../Widgets/infoCardsScreen.dart';
import '../../Widgets/shimmer_widgets.dart';
import '../../WorldMap/WorldMapScreen.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';
import '../../core/utils/routes/routes.dart';
import 'addCountriesScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().listenToCurrentUser();
    });
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      top: false,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Consumer<UserProfileProvider>(
                builder: (context, userProfileProvider, child) {
                  final user = userProfileProvider.currentUser;
                  if (user == null) {
                    return const ProfileShimmerWidget();
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary2,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.10),
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
                              CircleAvatar(
                                backgroundColor: AppColors.lightGrey.withOpacity(
                                  0.60,
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
                              Column(
                                children: [
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
                                                    user.profileImageUrl != null
                                                    ? Image.network(
                                                        user.profileImageUrl!,
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
                                                                color: AppColors
                                                                    .white,
                                                                child: const Icon(
                                                                  Icons.person,
                                                                  size: 40,
                                                                  color:
                                                                      Colors.grey,
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
                                                  user.fullName.isNotEmpty
                                                      ? user.fullName
                                                      : 'Unknown User',
                                                  style: pjsStyleBlack15700
                                                      .copyWith(
                                                        color: AppColors.white,
                                                      ),
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  spacing: 5,
                                                  children: [
                                                    Text(
                                                      user.homeCity.isNotEmpty
                                                          ? user.homeCity
                                                          : 'Unknown City',
                                                      style: pjsStyleBlack12400
                                                          .copyWith(
                                                            color:
                                                                AppColors.white,
                                                          ),
                                                    ),
                                                    Text(
                                                      userProfileProvider
                                                          .calculateAge(),
                                                      style: pjsStyleBlack12400
                                                          .copyWith(
                                                            color:
                                                                AppColors.white,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  userProfileProvider
                                                          .isLoadingCountry
                                                      ? 'Getting location...'
                                                      : userProfileProvider
                                                                .currentCountry !=
                                                            null
                                                      ? 'Currently in ${userProfileProvider.currentCountry}'
                                                      : 'Location not available',
                                                  style: pjsStyleBlack10400
                                                      .copyWith(
                                                        color: AppColors.white,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            RoutesName.myAccountScreen,
                                          );
                                        },
                                        child: SvgPicture.asset(
                                          AppImages.setting,
                                          colorFilter: ColorFilter.mode(
                                            AppColors.white,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                "${userProfileProvider.currentUser?.bio}",
                                style: pjsStyleBlack15400.copyWith(
                                  color: AppColors.white,
                                ),
                                maxLines: 3,
                                textAlign: TextAlign.justify,
                                overflow: TextOverflow.ellipsis,
                              ),
                              CustomButton(
                                text:
                                    "${userProfileProvider.visitedCountriesCount} Countries Visited",
                                onTap: () {},
                                svgAsset: AppImages.word,
                                backgroundColor: AppColors.white.withOpacity(
                                  0.14,
                                ),
                              ),

                              Consumer<UserProfileProvider>(
                                builder: (context, userProfileProvider, child) {
                                  final user = userProfileProvider.currentUser;

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
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
                                          Text(
                                            user?.socialStats.postsCount ?? '0',
                                            style: pjsStyleBlack15700.copyWith(
                                              color: AppColors.white,
                                            ),
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
                                          Text(
                                            user?.socialStats.connectionsCount ??
                                                '0',
                                            style: pjsStyleBlack15700.copyWith(
                                              color: AppColors.white,
                                            ),
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
                                          Text(
                                            user?.socialStats.followingCount ??
                                                '0',
                                            style: pjsStyleBlack15700.copyWith(
                                              color: AppColors.white,
                                            ),
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
                                          Text(
                                            user?.socialStats.followersCount ??
                                                '0',
                                            style: pjsStyleBlack15700.copyWith(
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.screenWidth * 0.03,
                  vertical: context.screenHeight * 0.02,
                ),

                child: Column(
                  spacing: 20,
                  children: [
                    CustomButton(
                      text: 'Edit Profile',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          RoutesName.personalDataScreen,
                        );
                      },
                      height: 42,
                      textColor: AppColors.primary,
                      backgroundColor: AppColors.white,
                      borderColor: AppColors.primary,
                    ),

                    Consumer<SelectionProvider>(
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
                                          vertical: 10,
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
                                          vertical: 10,
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
                    Consumer<SelectionProvider>(
                      builder: (context, selectionProvider, child) {
                        if (selectionProvider.isSelected(0)) {
                          return Consumer<UserProfileProvider>(
                            builder: (context, userProfileProvider, child) {
                              final userPostsProvider = context
                                  .read<UserPostsProvider>();
                              final postsStream = userPostsProvider
                                  .getUserPostsStream();

                              if (postsStream == null) {
                                return const Center(
                                  child: Text(
                                    'Please log in to view posts',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                );
                              }

                              return StreamBuilder<QuerySnapshot>(
                                stream: postsStream,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
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
                                            'You haven\'t shared any posts yet',
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

                                  final currentUser =
                                      userProfileProvider.currentUser;

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
                                            currentUser?.profileImageUrl ??
                                            AppImages.bestRestaurants,
                                        userName:
                                            currentUser?.fullName ??
                                            'Unknown User',
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
                        } else {
                          return Column(
                            spacing: 15,
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
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Create Memory',
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          RoutesName.addMemoryScreen,
                                        );
                                      },
                                      height: 30,
                                    ),
                                  ),
                                ],
                              ),
                              Consumer<MemoryProvider>(
                                builder: (context, memoryProvider, child) {
                                  final memoriesStream = memoryProvider
                                      .getUserMemoriesStream();

                                  if (memoriesStream == null) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            AppImages.cameraIcon,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Please log in to view memories',
                                            style: pjsStyleBlack14500.copyWith(
                                              color: AppColors.garyModern500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return StreamBuilder<QuerySnapshot>(
                                    stream: memoriesStream,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox(
                                          height: 190,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SvgPicture.asset(
                                                AppImages.cameraIcon,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Error loading memories',
                                                style: pjsStyleBlack14500
                                                    .copyWith(
                                                      color: Colors.red,
                                                    ),
                                              ),
                                            ],
                                          ),
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
                                            const SizedBox(height: 16),
                                            SizedBox(
                                              width: context.screenWidth / 2,
                                              child: CustomButton(
                                                backgroundColor: AppColors.white,
                                                textColor: AppColors.primary,
                                                borderColor: AppColors.primary,
                                                height: 40,
                                                textStyle: pjsStyleBlack12600.copyWith(
                                                  color: AppColors.primary,
                                                ),
                                                text:
                                                    'Create Your First Memory',
                                                onTap: () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    RoutesName.addMemoryScreen,
                                                  );
                                                },
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

                              Column(
                                spacing: 15,
                                children: [
                                  Consumer<UserProfileProvider>(
                                    builder: (context, userProfileProvider, child) {
                                      return Row(
                                        children: [
                                          InfoCard(
                                            svgAsset: AppImages.word,
                                            number:
                                                "${userProfileProvider.visitedCountriesCount}",
                                            title: "Countries",
                                            subtitle:
                                                "${userProfileProvider.getFormattedPercentage().toStringAsFixed(0)}% of the world",
                                          ),
                                          SizedBox(width: 16),
                                          FutureBuilder<int>(
                                            future: userProfileProvider
                                                .getVisitedContinentsCount(),
                                            builder: (context, snapshot) {
                                              final continentsCount =
                                                  snapshot.data ?? 0;
                                              return InfoCard(
                                                svgAsset:
                                                    AppImages.locationIcon,
                                                number: "$continentsCount",
                                                title: "Continents",
                                                subtitle: "out of 7",
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  Consumer<UserProfileProvider>(
                                    builder: (context, userProfileProvider, child) {
                                      final visited = userProfileProvider
                                          .visitedCountriesCount;
                                      const explorerTarget = 30;

                                      // Calculate progress
                                      final progress =
                                          (visited / explorerTarget).clamp(
                                            0.0,
                                            1.0,
                                          );
                                      final percentage = (progress * 100)
                                          .toStringAsFixed(0);

                                      // Remaining
                                      final remaining =
                                          (explorerTarget - visited).clamp(
                                            0,
                                            explorerTarget,
                                          );

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Title + Percentage Row
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "World Progress",
                                                  style: pjsStyleBlack14700
                                                      .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                ),
                                                Text(
                                                  "$percentage%",
                                                  style: pjsStyleBlack14700
                                                      .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 12),

                                            // Progress Bar
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                minHeight: 14,
                                                backgroundColor:
                                                    Colors.grey.shade300,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.primary),
                                              ),
                                            ),

                                            const SizedBox(height: 12),

                                            // Remaining Text
                                            Text(
                                              remaining == 0
                                                  ? '🎉 You are now a World Explorer!'
                                                  : 'Visit $remaining more countries to become a world explorer',
                                              style: pjsStyleBlack14400
                                                  .copyWith(
                                                    color: AppColors.darkGrey,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  Container(
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
                                              Expanded(
                                                child: CustomButton(
                                                  height: 30,
                                                  padding: 2,
                                                  text: 'Manage',
                                                  onTap: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      RoutesName
                                                          .countriesIVisitedScreen,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 145,
                                            child: WorldMapScreen(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Consumer<UserProfileProvider>(
                                    builder:
                                        (context, userProfileProvider, child) {
                                          if (userProfileProvider.currentUser ==
                                              null)
                                            return const SizedBox();
                                          final user =
                                              userProfileProvider.currentUser;
                                          return Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: AppColors.borderShad,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.white,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  context.screenWidth * 0.05,
                                              vertical:
                                                  context.screenHeight * 0.02,
                                            ),
                                            child: Column(
                                              spacing: 10,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'About',
                                                  style: pjsStyleBlack14700
                                                      .copyWith(
                                                        color:
                                                            AppColors.primary,
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
                                                        user!.bio ?? '',
                                                        style: pjsStyleBlack10400
                                                            .copyWith(
                                                              color: AppColors
                                                                  .garyModern400,
                                                            ),
                                                        textAlign:
                                                            TextAlign.justify,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  width:
                                                      context.screenWidth * 0.2,
                                                  child: CustomButton(
                                                    height: 30,
                                                    padding: 2,
                                                    text: 'Edit',
                                                    onTap: () {
                                                      Navigator.pushNamed(
                                                        context,
                                                        RoutesName
                                                            .personalDataScreen,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
                                          ),
                                        ),
                                        builder: (BuildContext context) {
                                          return SizedBox(
                                            height: context.screenHeight * 0.9,
                                            child: AddCountriesScreen(),
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,

                                        children: [
                                          Row(
                                            spacing: 5,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                flex: 1,
                                                child: CircleAvatar(
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          8.0,
                                                        ),
                                                    child: SvgPicture.asset(
                                                      AppImages.locationIcon,
                                                      color: AppColors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 4,
                                                child: Column(
                                                  spacing: 5,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'My Countries',
                                                      style: pjsStyleBlack14700
                                                          .copyWith(
                                                            color: AppColors
                                                                .primary,
                                                          ),
                                                    ),

                                                    Text(
                                                      'and non-UN Territories',
                                                      style: pjsStyleBlack10400
                                                          .copyWith(
                                                            color: AppColors
                                                                .garyModern400,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: SvgPicture.asset(
                                                  AppImages.forward,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
