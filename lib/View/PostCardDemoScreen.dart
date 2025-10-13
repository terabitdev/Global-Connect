// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../Provider/PostCardDemoProvider.dart';
// import '../Widgets/PostCard.dart';
// import '../core/const/app_color.dart';
// import '../core/theme/app_text_style.dart';
//
// class PostCardDemoScreen extends StatelessWidget {
//   const PostCardDemoScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => PostCardDemoProvider(),
//       child: Scaffold(
//         backgroundColor: Colors.grey[50],
//         appBar: AppBar(
//           title: Text(
//             'Enhanced PostCard Demo',
//             style: pjsStyleBlack13600.copyWith(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           backgroundColor: Colors.white,
//           foregroundColor: Colors.black,
//           elevation: 0.5,
//           centerTitle: true,
//         ),
//         body: Consumer<PostCardDemoProvider>(
//           builder: (context, provider, child) {
//             final posts = PostCardDemoProvider.getSamplePosts();
//             final comments = PostCardDemoProvider.getSampleComments();
//             final users = PostCardDemoProvider.getSampleUsers();
//
//             return ListView.builder(
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               itemCount: posts.length,
//               itemBuilder: (context, index) {
//                 final post = posts[index];
//                 final postId = post['postId'] as String;
//
//                 return PostCard(
//                   postId: postId,
//                   userAvatar: post['userAvatar'] as String,
//                   userName: post['userName'] as String,
//                   userLocation: post['userLocation'] as String,
//                   locationFlag: post['locationFlag'] as String,
//                   timeAgo: post['timeAgo'] as String,
//                   postImage: post['postImage'] as String,
//                   description: post['description'] as String,
//                   hashtags: post['hashtags'] as String,
//                   initialLikeCount: (post['initialLikeCount'] as int) +
//                       provider.getPostLikeCount(postId),
//                   isLiked: (post['isLiked'] as bool) ||
//                       provider.isPostLiked(postId),
//                   comments: [
//                     ...comments,
//                     ...provider.getPostComments(postId),
//                   ],
//                   availableUsers: users,
//                   onEdit: (postId) {
//                     provider.editPost(postId);
//                     _showEditDialog(context, postId);
//                   },
//                   onDelete: (postId) {
//                     _showDeleteDialog(context, provider, postId);
//                   },
//                   onCommentAdded: (postId, comment) {
//                     provider.addComment(postId, comment);
//                   },
//                   onShare: (postId, userIds) {
//                     provider.sharePost(postId, userIds);
//                   },
//                 );
//               },
//             );
//           },
//         ),
//         floatingActionButton: FloatingActionButton.extended(
//           onPressed: () => _showFeatureInfo(context),
//           backgroundColor: AppColors.primary,
//           icon: const Icon(Icons.info_outline, color: Colors.white),
//           label: Text(
//             'Features',
//             style: pjsStyleBlack14400.copyWith(
//               color: Colors.white,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showEditDialog(BuildContext context, String postId) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Edit Post'),
//         content: Text('Edit functionality for post: $postId'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Edit post $postId'),
//                   backgroundColor: AppColors.primary,
//                 ),
//               );
//             },
//             child: const Text('Edit'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showDeleteDialog(BuildContext context, PostCardDemoProvider provider, String postId) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Post'),
//         content: const Text('Are you sure you want to delete this post?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               provider.deletePost(postId);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('Deleted post $postId'),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//             },
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showFeatureInfo(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'PostCard Features',
//               style: pjsStyleBlack13600.copyWith(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildFeatureItem(
//               icon: Icons.favorite,
//               title: 'Like Animation',
//               description: 'Tap heart to like, double-tap image for quick like',
//             ),
//             _buildFeatureItem(
//               icon: Icons.comment,
//               title: 'Comments',
//               description: 'Tap comment icon to view and add comments',
//             ),
//             _buildFeatureItem(
//               icon: Icons.share,
//               title: 'Share with Users',
//               description: 'Share posts with specific users from your network',
//             ),
//             _buildFeatureItem(
//               icon: Icons.more_vert,
//               title: 'Options Menu',
//               description: 'Three dots menu for edit and delete options',
//             ),
//             _buildFeatureItem(
//               icon: Icons.location_on,
//               title: 'Location Display',
//               description: 'User location with country flag emoji',
//             ),
//             _buildFeatureItem(
//               icon: Icons.tag,
//               title: 'Hashtags',
//               description: 'Clickable hashtags in brand color',
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () => Navigator.pop(context),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppColors.primary,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text('Got it!'),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFeatureItem({
//     required IconData icon,
//     required String title,
//     required String description,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: AppColors.primary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               icon,
//               color: AppColors.primary,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: pjsStyleBlack13600.copyWith(
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   description,
//                   style: pjsStyleBlack10500.copyWith(
//                     color: Colors.grey[600],
//                     height: 1.3,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }