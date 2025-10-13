import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../View/post/editPostScreen.dart';
import '../core/const/app_color.dart';
import '../core/const/app_images.dart';
import '../core/theme/app_text_style.dart';
import '../Model/CommentModel.dart';
import '../Provider/PostCardProvider.dart';
import 'CommentBottomSheet.dart';
import 'ShareBottomSheet.dart';
import 'ReportDialog.dart';
import '../Provider/ReportProvider.dart';
import '../Model/ReportModel.dart';

class PostCard extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final int shareCount;
  final String userAvatar;
  final String userName;
  final String userLocation;
  final String locationFlag;
  final String timeAgo;
  final List<String> postImages;
  final String description;
  final String hashtags;
  final int initialLikeCount;
  final bool isLiked;
  final List<CommentModel> comments;
  final Function(String)? onEdit;
  final double? latitude;
  final double? longitude;
  final Function(String)? onDelete;
  final Function(String, String)? onCommentAdded;
  final Function(String, List<String>)? onShare;
  final VoidCallback? onLikePressed;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onSharePressed;

  const PostCard({
    super.key,
    this.latitude,
    this.longitude,
    required this.postId,
    required this.postOwnerId,
    required this.userAvatar,
    required this.userName,
    required this.shareCount,
    required this.userLocation,
    this.locationFlag = '🌍',
    required this.timeAgo,
    required this.postImages,
    required this.description,
    required this.hashtags,
    this.initialLikeCount = 0,
    this.isLiked = false,
    this.comments = const [],
    this.onEdit,
    this.onDelete,
    this.onCommentAdded,
    this.onShare,
    this.onLikePressed,
    this.onCommentPressed,
    this.onSharePressed,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  late PostCardProvider _postProvider;

  @override
  void initState() {
    super.initState();

    // Initialize post in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postProvider = context.read<PostCardProvider>();
      _postProvider.initializePost(
        widget.postId,
        widget.postOwnerId,
        initialLikeCount: widget.initialLikeCount,
        comments: widget.comments,
      );
    });

    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  bool get _isCurrentUserOwner {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    return currentUser?.uid == widget.postOwnerId;
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    // Use cached provider to avoid ancestor lookup on deactivated context
    _postProvider.disposePost(widget.postId);
    super.dispose();
  }

  void _toggleLike() async {
    final provider = context.read<PostCardProvider>();
    final wasLiked = provider.isLiked(widget.postId);

    // Fire-and-forget toggling (optimistic update happens inside provider)
    provider.toggleLike(widget.postId, widget.postOwnerId);

    // Trigger like animation instantly if we are liking now
    if (!wasLiked) {
      _likeAnimationController.forward().then((_) {
        _likeAnimationController.reverse();
      });
    }

    if (widget.onLikePressed != null) {
      widget.onLikePressed!();
    }
  }

  void _showComments() {
    final provider = context.read<PostCardProvider>();

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (modalContext) => ChangeNotifierProvider.value(
          value: provider,
          child: CommentBottomSheet(
            postId: widget.postId,
            postOwnerId: widget.postOwnerId,
          ),
        ),
      );
    }

    if (widget.onCommentPressed != null) {
      widget.onCommentPressed!();
    }
  }

  void _showShareOptions() {
    final provider = context.read<PostCardProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        postId: widget.postId,
        postOwnerId: widget.postOwnerId,
        onShare: (selectedUserIds) async {
          // Share post in Firestore
          await provider.sharePost(
            widget.postId,
            widget.postOwnerId,
            selectedUserIds,
          );

          if (widget.onShare != null) {
            widget.onShare!(widget.postId, selectedUserIds);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Shared with ${selectedUserIds.length} users'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        },
      ),
    );
    if (widget.onSharePressed != null) {
      widget.onSharePressed!();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<PostCardProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<String?>(
          future: provider.getCountry(widget.latitude!, widget.longitude!),
          builder: (context, snapshot) {
            String flag = "🌍";
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              flag = provider.getFlagByNationalityProxy(snapshot.data!);
            }

            return Container(
              color: Colors.white,
              child: Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.white,
                          radius: 25,
                          child: ClipOval(
                            child: widget.userAvatar.isNotEmpty
                                ? Image.network(
                                    widget.userAvatar,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.person,
                                              color: Colors.grey,
                                            ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                  )
                                : const Icon(Icons.person, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.userName,
                                      style: pjsStyleBlack13600.copyWith(
                                        color: AppColors.purple,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "$flag ${widget.userLocation}",
                                      style: pjsStyleBlack13600.copyWith(
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  // Direct ownership check for instant response
                                  PopupMenuButton<String>(
                                    onSelected: (String value) {
                                      if (value == 'edit' && widget.onEdit != null) {
                                        widget.onEdit!(widget.postId);
                                      } else if (value == 'delete' && widget.onDelete != null) {
                                        widget.onDelete!(widget.postId);
                                      } else if (value == 'report') {
                                        showDialog(
                                          context: context,
                                          builder: (context) => ChangeNotifierProvider(
                                            create: (context) => ReportProvider(),
                                            child: ReportDialog(
                                              contentId: widget.postId,
                                              contentOwnerId: widget.postOwnerId,
                                              contentType: ReportContentType.post,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    offset: const Offset(-10, 35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 8,
                                    surfaceTintColor: Colors.white,
                                    color: Colors.white,
                                    padding: const EdgeInsets.all(10),
                                    child: SvgPicture.asset(
                                      AppImages.dot,
                                      width: 30,
                                      height: 20,
                                    ),
                                    itemBuilder: (BuildContext context) => _isCurrentUserOwner
                                        ? [
                                            PopupMenuItem<String>(
                                              onTap: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  backgroundColor: Colors.white,
                                                  shape: const RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.only(
                                                      topLeft: Radius.circular(20),
                                                      topRight: Radius.circular(20),
                                                    ),
                                                  ),
                                                  builder: (BuildContext context) {
                                                    return SizedBox(
                                                      height: context.screenHeight * 0.9,
                                                      child: EditPostScreen(
                                                        postId: widget.postId,
                                                        caption: widget.description,
                                                        images: widget.postImages,
                                                        location: widget.userLocation,
                                                        latitude: widget.latitude,
                                                        longitude: widget.longitude,
                                                        hashtags: widget.hashtags,
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              value: 'edit',
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 8,
                                                  horizontal: 4,
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Edit Post',
                                                      style: pjsStyleBlack14400.copyWith(
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ]
                                        : [
                                            PopupMenuItem<String>(
                                              value: 'report',
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 8,
                                                  horizontal: 4,
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.flag_outlined,
                                                      size: 18,
                                                      color: Colors.red[600],
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Report Post',
                                                      style: pjsStyleBlack14400.copyWith(
                                                        color: Colors.red[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                  ),
                                ],
                              ),
                              Text(
                                widget.timeAgo,
                                style: pjsStyleBlack10500.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ Carousel with shimmer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth;
                        final dynamicHeight = availableWidth * 1.3;
                        
                        return CarouselSlider(
                          carouselController: _carouselController,
                          options: CarouselOptions(
                            height: dynamicHeight,
                            viewportFraction: 1.0,
                            enableInfiniteScroll: widget.postImages.length > 1,
                            onPageChanged: (index, reason) {
                              provider.updateCurrentImageIndex(widget.postId, index);
                            },
                          ),
                          items: widget.postImages.map((imagePath) {
                            return Container(
                              width: availableWidth,
                              decoration: BoxDecoration(
                                color: Colors.white,
                              ),
                              child: Image.network(
                                imagePath,
                                width: availableWidth,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  if (widget.postImages.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: widget.postImages.asMap().entries.map((
                          entry,
                        ) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  provider.currentImageIndex(widget.postId) ==
                                      entry.key
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.3),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  // ✅ Like, Comment, Share buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 5,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _toggleLike,
                          child: Column(
                            children: [
                              StreamBuilder<bool>(
                                stream: provider.getUserLikeStream(
                                  widget.postId,
                                  widget.postOwnerId,
                                ),
                                builder: (context, likeSnapshot) {
                                  return AnimatedBuilder(
                                    animation: _likeAnimation,
                                    builder: (context, child) {
                                      final isLiked =
                                          likeSnapshot.data ??
                                          provider.isLiked(widget.postId);
                                      return Transform.scale(
                                        scale: _likeAnimation.value,
                                        child: SvgPicture.asset(
                                          isLiked
                                              ? AppImages.dil2
                                              : AppImages.dil,
                                          width: 20,
                                          height: 20,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              StreamBuilder<int>(
                                stream: provider.getLikeCountStream(
                                  widget.postId,
                                  widget.postOwnerId,
                                ),
                                builder: (context, snapshot) {
                                  final likeCount =
                                      snapshot.data ??
                                      provider.likeCount(widget.postId);
                                  return Text(
                                    '$likeCount like',
                                    style: pjsStyleBlack14700.copyWith(
                                      color: likeCount > 0
                                          ? AppColors.primary
                                          : AppColors.darkGrey,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: _showComments,
                          child: Column(
                            children: [
                              SvgPicture.asset(
                                AppImages.comment,
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(height: 4),
                              StreamBuilder<List<Map<String, dynamic>>>(
                                stream: provider.getCommentsStream(
                                  widget.postId,
                                  widget.postOwnerId,
                                ),
                                builder: (context, snapshot) {
                                  final commentCount =
                                      snapshot.data?.length ?? 0;
                                  return Text(
                                    '$commentCount Comment',
                                    style: pjsStyleBlack14700.copyWith(
                                      color: commentCount > 0
                                          ? AppColors.primary
                                          : AppColors.darkGrey,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),
                        Column(
                          children: [
                            GestureDetector(
                              onTap: _showShareOptions,
                              child: SvgPicture.asset(
                                AppImages.share,
                                width: 20,
                                height: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            StreamBuilder<int>(
                              stream: provider.getShareCountStream(
                                widget.postId,
                                widget.postOwnerId,
                              ),
                              builder: (context, snapshot) {
                                final shareCount =
                                    snapshot.data ?? widget.shareCount;
                                return Text(
                                  shareCount.toString(),
                                  style: pjsStyleBlack14700.copyWith(
                                    color: shareCount > 0
                                        ? AppColors.primary
                                        : AppColors.darkGrey,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ✅ Description
                  Padding(
                    padding: const EdgeInsets.symmetric( horizontal: 28,vertical: 5),
                    child: Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.description,
                          style: pjsStyleBlack14400.copyWith(
                            color: AppColors.garyModern500,
                          ),
                          textAlign: TextAlign.justify,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,

                        ),
                        Text(
                          widget.hashtags,
                          style: pjsStyleBlack14400.copyWith(
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.justify,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Future<String?> getCountry(double latitude, double longitude) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      latitude,
      longitude,
    );
    if (placemarks.isNotEmpty) {
      return placemarks.first.country;
    }
    return null;
  } catch (e) {
    print('❌ Error fetching country: $e');
    return null;
  }
}

  // Add this method to your _PostCardState class
  Future<ImageInfo> _getImageInfo(String imageUrl) async {
    final ImageProvider provider = NetworkImage(imageUrl);
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);
    final Completer<ImageInfo> completer = Completer<ImageInfo>();
    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        completer.complete(info);
      },
      onError: (dynamic error, StackTrace? stackTrace) {
        completer.completeError(error);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
