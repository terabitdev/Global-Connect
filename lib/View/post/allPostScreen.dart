import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/core/const/app_color.dart';
import 'package:global_connect/core/const/app_images.dart';
import 'package:global_connect/core/theme/app_text_style.dart';
import 'package:provider/provider.dart';
import '../../Provider/PostProvider.dart';
import '../../Provider/user_profile_provider.dart';
import '../../Widgets/EmptyStateWidget.dart';
import '../../Widgets/FilterDropdown.dart';
import '../../Widgets/PostCard.dart';
import '../../Widgets/CustomSearchBar.dart';
import '../../Widgets/shimmer_widgets.dart';
import '../../core/utils/routes/routes.dart';

class AllPostScreen extends StatefulWidget {
  const AllPostScreen({super.key});
  @override
  State<AllPostScreen> createState() => _AllPostScreenState();
}

class _AllPostScreenState extends State<AllPostScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      postProvider.loadUserFeedPreference();
      postProvider.startListeningToPosts();
    });
  }

  void _handleLike(String postId) {
    print('Like pressed for $postId');
  }

  void _handleComment(String postId) {
    print('Comment pressed for $postId');
  }

  void _handleShare(String postId) {
    print('Share pressed for $postId');
  }




  // Helper method to format time ago
  String getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown time';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
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
    return Consumer<PostProvider>(
      builder: (context, postProvider, child) {
        return SafeArea(
          bottom: false,
          top: true,
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.start,
                // crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 20,
                children: [
                  // const HomeAppBar(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      spacing: 15,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomSearchBar(
                                controller: postProvider.searchController,
                                hintText: 'Search...',
                                onChanged: postProvider.onSearchChanged,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RoutesName.notificationScreen,
                                );
                              },
                              child: SvgPicture.asset(
                                AppImages.notification,
                                color: AppColors.primary,
                                height: 20,
                                width: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  RoutesName.privateChatScreen,
                                );
                              },
                              child: SvgPicture.asset(
                                AppImages.message,
                                height: 20,
                                width: 20,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Consumer<UserProfileProvider>(
                              builder: (context, userProfileProvider, child) {
                                final user = userProfileProvider.currentUser;
                                final isLoading = user == null;
                                return Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              RoutesName.profileScreen,
                                            );
                                          },
                                          child: CircleAvatar(
                                            backgroundColor: AppColors.white,
                                            child: isLoading
                                                ? const CircleImageShimmerWidget(
                                                    size: 60,
                                                  )
                                                : CircleAvatar(
                                                    backgroundImage:
                                                        NetworkImage(
                                                          user!.profileImageUrl
                                                              .toString(),
                                                        ),
                                                    backgroundColor:
                                                        AppColors.white,
                                                    radius: 30,
                                                  ),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text('Feed', style: pjsStyleBlack20600),
                            ),
                            Expanded(
                              child: postProvider.isLoadingFeed
                                  ? Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        border: Border.all(color: AppColors.garyModern200),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    )
                                  : FilterDropdown(
                                      selectedValue: postProvider.selectedFilter,
                                      items: const [
                                        'Following',
                                        'Connections',
                                        'Global',
                                      ],
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          postProvider.setFilter(newValue);
                                        }
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),


                  // Show posts or appropriate empty state
                  if (postProvider.isLoadingPosts && !postProvider.hasInitiallyLoaded)
                    // Show shimmer when initially loading
                    Column(
                      children: List.generate(3, (index) => 
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: PostCardShimmerWidget(),
                        ),
                      ),
                    )
                  else if (postProvider.postsError != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error loading posts',
                              style: pjsStyleBlack16600,
                            ),
                            SizedBox(height: 8),
                            Text(
                              postProvider.postsError!,
                              style: pjsStyleBlack14400,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => postProvider.refreshPosts(),
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (postProvider.filteredPosts.isEmpty && postProvider.hasInitiallyLoaded)
                    buildEmptyStateWidget(postProvider.selectedFilter)
                  else
                    // Display posts
                    Column(
                      children: postProvider.filteredPosts.map((post) {
                        // Get cached user data instead of fetching it
                        final userData = postProvider.getCachedUserData(post.userId);
                        final userName = userData?['fullName'] ?? 'Loading...';
                        final userAvatar = userData?['profileImageUrl'] ?? '';
                        final userLocation = post.location.address.isNotEmpty 
                            ? post.location.address 
                            : 'Location not available';

                        return FutureBuilder<bool>(
                          future: postProvider.isPostLiked(post.postId, post.userId),
                          builder: (context, likeSnapshot) {
                            final isLiked = likeSnapshot.data ?? false;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: PostCard(
                                postId: post.postId,
                                postOwnerId: post.userId,
                                userAvatar: userAvatar,
                                userName: userName,
                                shareCount: post.shares,
                                userLocation: userLocation,
                                locationFlag: '🌍',
                                timeAgo: getTimeAgo(post.createdAt),
                                postImages: post.images,
                                description: post.caption,
                                hashtags: post.tags.join(' '),
                                initialLikeCount: post.likes,
                                isLiked: isLiked,
                                latitude: post.location.latitude,
                                longitude: post.location.longitude,
                                comments: const [],
                                onLikePressed: () => _handleLike(post.postId),
                                onCommentPressed: () => _handleComment(post.postId),
                                onSharePressed: () => _handleShare(post.postId),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
