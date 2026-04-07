import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../../models/CommentDto.dart';
import '../../../../../models/UserDto.dart';
import '../../../../../util/HelperUtil.dart';
import '../../../../user_info_page/UserInfoPage.dart';

class CommentHeaderRow extends StatelessWidget {
  final CommentDto comment;
  final UserDto currentUser;
  final VoidCallback onPauseVideo;

  const CommentHeaderRow({
    super.key,
    required this.comment,
    required this.currentUser,
    required this.onPauseVideo,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = comment.profilePictureUrl.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: hasImage
                  ? CachedNetworkImage(
                imageUrl: comment.profilePictureUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Image.asset(
                  "assets/images/page/empty.png",
                  fit: BoxFit.cover,
                ),
                errorWidget: (context, url, error) => Image.asset(
                  "assets/images/page/empty.png",
                  fit: BoxFit.cover,
                ),
              )
                  : Image.asset(
                "assets/images/page/empty.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (_isUploader()) return;

                onPauseVideo();

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserInfoPage(
                      userID: comment.userId,
                      viewerID: currentUser.userid!,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.username,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.orange,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      HelperUtil.getUserIcon(comment.role),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    HelperUtil.getTimeAgo(comment.timestamp ?? Timestamp.now()),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.white60,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isUploader() => currentUser.userid == comment.userId;
}