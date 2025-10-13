import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../core/const/app_color.dart';
import '../core/const/app_images.dart';
import '../core/theme/app_text_style.dart';
import '../Model/CommentModel.dart';
import '../Provider/PostCardProvider.dart';
import 'CustomAppBar.dart';
import 'buildMessageInput.dart';

class CommentBottomSheet extends StatefulWidget {
  final String postId;
  final String postOwnerId;

  const CommentBottomSheet({
    super.key,
    required this.postId,
    required this.postOwnerId,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() {
    if (_commentController.text.trim().isNotEmpty) {
      final comment = _commentController.text.trim();
      final provider = context.read<PostCardProvider>();
      provider.addComment(widget.postId, widget.postOwnerId, comment);
      _commentController.clear();

    }
  }

  void _deleteComment(String commentId) async {
    final provider = context.read<PostCardProvider>();
    final success = await provider.deleteComment(
      widget.postId, 
      widget.postOwnerId, 
      commentId
    );
    

  }

  

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 50,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(),
                child: CustomAppBar2(
                  title: Text(
                    'Comments',
                    style: pjsStyleBlack18600.copyWith(color: AppColors.black),
                  ),
                ),
              ),

              // Comments List
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: context.read<PostCardProvider>()
                      .getCommentsStream(widget.postId, widget.postOwnerId),
                  builder: (context, snapshot) {

                    final rawComments = snapshot.data ?? [];

                    if (rawComments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: pjsStyleBlack14400.copyWith(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to share your thoughts!',
                              style: pjsStyleBlack10500.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Preload user details for all comment authors
                    context.read<PostCardProvider>().preloadUserDetailsForComments(widget.postId);

                    final commentsWithUserDetails = rawComments.map((commentData) {
                      final userId = commentData['userId'] ?? '';
                      final userDetails = context.read<PostCardProvider>().getUserDetails(userId);

                      return CommentModel(
                        id: commentData['id'] ?? '',
                        userId: userId,
                        userName: userDetails?['fullName'] ?? 'Unknown User',
                        userAvatar: userDetails?['profileImageUrl'] ?? '',
                        comment: commentData['comment'] ?? '',
                        timestamp: commentData['createdAt'] != null
                            ? (commentData['createdAt']).toDate()
                            : DateTime.now(),
                      );
                    }).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: commentsWithUserDetails.length,
                      itemBuilder: (context, index) {
                        final comment = commentsWithUserDetails[index];
                        final provider = context.read<PostCardProvider>();
                        final isPostOwner = provider.isPostOwner(widget.postOwnerId);
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundImage: comment.userAvatar.isNotEmpty
                                    ? NetworkImage(comment.userAvatar)
                                    : null,
                                radius: 25,
                                backgroundColor: Colors.grey[200],
                                child: comment.userAvatar.isEmpty
                                    ? const Icon(Icons.person, color: Colors.grey)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            comment.userName,
                                            style: pjsStyleBlack13600.copyWith(
                                              color: AppColors.darkBlue,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              comment.getTimeAgo(),
                                              style: pjsStyleBlack10500.copyWith(
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            if (isPostOwner) ...[
                                              const SizedBox(width: 8),
                                              PopupMenuButton<String>(
                                                iconColor: AppColors.primary,
                                                onSelected: (String value) {
                                                  if (value == 'delete') {
                                                    _deleteComment(comment.id);
                                                  }
                                                },
                                                offset: const Offset(-10, 35),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                elevation: 8,
                                                surfaceTintColor: Colors.white,
                                                color: Colors.white,
                                                padding: EdgeInsets.zero,
                                                child: Padding(
                                                  padding: const EdgeInsets.only(left: 5),
                                                  child: SvgPicture.asset(
                                                    AppImages.dot,
                                                    width: 20,
                                                    height: 20,
                                                  ),
                                                ),
                                                itemBuilder: (BuildContext context) => [
                                                  PopupMenuItem<String>(

                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                       SvgPicture.asset(AppImages.delete, height: 20, width: 20),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          'Delete',
                                                          style: pjsStyleBlack14400.copyWith(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.comment,
                                      style: pjsStyleBlack12400,
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Comment Input
              buildMessageInput(
                controller: _commentController,
                hintText: 'Type a comment...',
                onSend: _submitComment,
                showMediaButton: false,
                maxLines: 5,
                minLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
