import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';
import '../core/const/responsive_layout.dart';
import '../Provider/SharedPostProvider.dart';
import '../Model/AddPostModel.dart';
import '../Model/userModel.dart';
import 'SharedPostShimmer.dart';

class SharedPostWidget  extends StatelessWidget {
  final String postId;
  final String postOwnerId;
  final bool isCurrentUser;

  const SharedPostWidget({
    Key? key,
    required this.postId,
    required this.postOwnerId,
    required this.isCurrentUser,
  }) : super(key: key);

  String _getCountryFlag(String? country) {
    if (country == null || country.isEmpty) return '🌍';
    
    // Map of countries to flag emojis
    final Map<String, String> countryFlags = {
      'United States': '🇺🇸',
      'USA': '🇺🇸',
      'United Kingdom': '🇬🇧',
      'UK': '🇬🇧',
      'Canada': '🇨🇦',
      'Australia': '🇦🇺',
      'Germany': '🇩🇪',
      'France': '🇫🇷',
      'Spain': '🇪🇸',
      'Italy': '🇮🇹',
      'Brazil': '🇧🇷',
      'India': '🇮🇳',
      'China': '🇨🇳',
      'Japan': '🇯🇵',
      'Mexico': '🇲🇽',
      'Pakistan': '🇵🇰',
      'Portugal': '🇵🇹',
      // Add more as needed
    };
    
    return countryFlags[country] ?? '🌍';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SharedPostProvider>(
      builder: (context, provider, child) {
        final postKey = '${postOwnerId}_$postId';
        final state = provider.getPostState(postKey);
        final postData = provider.getPostData(postKey);
        final error = provider.getPostError(postKey);

        // Load post data if not already loaded
        if (state == SharedPostState.loading && postData == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.loadSharedPost(postId, postOwnerId);
          });
        }

        switch (state) {
          case SharedPostState.loading:
            return SharedPostShimmer(isCurrentUser: isCurrentUser);
            
          case SharedPostState.loaded:
            if (postData != null) {
              return _buildPostContent(context, postData.post, postData.user);
            }
            return _buildPostUnavailableWidget(context);
            
          case SharedPostState.error:
            return _buildErrorWidget(context, error ?? 'Unknown error');
            
          case SharedPostState.notFound:
            return _buildPostUnavailableWidget(context);
            
          default:
            return SharedPostShimmer(isCurrentUser: isCurrentUser);
        }
      },
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.white.withOpacity(0.95) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildPostUnavailableWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.post_add_outlined,
            size: 32,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Post is no longer available',
            style: pStyleBlack12400.copyWith(color: AppColors.darkGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent(BuildContext context, AddPost post, UserModel user) {
    // Extract user data from user model
    final userName = user.fullName;
    final userAvatar = user.profileImageUrl ?? '';
    final userCountry = user.currentCountry ?? user.nationality;
    
    // Extract post data from post model
    final userLocation = post.location.address;
    final postImages = post.images;
    final description = post.caption;
    final createdAt = post.createdAt;
    
    // Calculate time ago
    String timeAgo = '2 hours ago';
    if (createdAt != null) {
      timeAgo = getTimeAgo(createdAt);
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: context.screenWidth * 0.75,
      ),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.white.withOpacity(0.95) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with user info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  child: userAvatar.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            userAvatar,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 24,
                                color: Colors.grey[600],
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 24,
                          color: Colors.grey[600],
                        ),
                ),
                const SizedBox(width: 10),
                
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and location
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              userName,
                              style: pStyleBlack14600.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (userCountry.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              _getCountryFlag(userCountry),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                userCountry,
                                style: pStyleBlack12400.copyWith(
                                  color: AppColors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      // Time ago
                      const SizedBox(height: 2),
                      Text(
                        timeAgo,
                        style: pStyleBlack10400.copyWith(
                          color: AppColors.primary
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Post Image
          if (postImages.isNotEmpty)
            Container(
              constraints: BoxConstraints(
                maxHeight: context.screenHeight * 0.3,
              ),
              width: double.infinity,
              child: ClipRRect(
                child: Image.network(
                  postImages[0],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, 
                            size: 40, 
                            color: Colors.grey[400]
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Image could not be loaded',
                            style: pStyleBlack12400.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // Description/Caption
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                description,
                style: pjsStyleBlack14500.copyWith(
                  height: 1.4,
                  color: AppColors.garyModern500
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.justify,
              ),
            ),
          
          // Shared Post Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.share,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Shared Post',
                  style: pjsStyleBlack14700.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 32,
            color: Colors.red[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load post',
            style: pStyleBlack12600.copyWith(color: Colors.red[700]),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: pStyleBlack10400.copyWith(color: Colors.red[600]),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
String getTimeAgo(DateTime dateTime) {
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