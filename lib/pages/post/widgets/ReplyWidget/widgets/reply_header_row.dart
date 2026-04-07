import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../../models/ReplyDto.dart';
import '../../../../../models/UserDto.dart';
import '../../../../../util/HelperUtil.dart';
import '../../../../user_info_page/UserInfoPage.dart';

class ReplyHeaderRow extends StatelessWidget {
  final ReplyDto reply;
  final UserDto currentUser;
  final VoidCallback onPauseVideo;

  const ReplyHeaderRow({
    super.key,
    required this.reply,
    required this.currentUser,
    required this.onPauseVideo,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = reply.profilePictureUrl.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: hasImage
                  ? CachedNetworkImage(
                imageUrl: reply.profilePictureUrl,
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
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (_isUploader()) return;
                onPauseVideo();

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserInfoPage(
                      userID: reply.userId,
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
                          reply.username,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      HelperUtil.getUserIcon(reply.role),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    HelperUtil.getTimeAgo(reply.timestamp ?? Timestamp.now()),
                    style: const TextStyle(
                      fontSize: 12,
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

  bool _isUploader() => currentUser.userid == reply.userId;
}