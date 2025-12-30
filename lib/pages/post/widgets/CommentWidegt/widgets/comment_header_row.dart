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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [

          // Avatar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(120),
              child: Image.network(
                comment.profilePictureUrl,
                fit: BoxFit.cover,
                width: 50,
                height: 50,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    "assets/images/page/empty.png",
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                  );
                },
              ),
            ),
          ),

          // Username + Role
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
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
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        comment.username,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 0,
                          color: Colors.orange,
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.start,
                        softWrap: true,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: HelperUtil.getUserIcon(comment.role),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Timestamp
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                HelperUtil.getTimeAgo(comment.timestamp ?? Timestamp.now()),
                style: const TextStyle(
                  fontSize: 15,
                  height: 0,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.start,
                softWrap: true,
              ),
            ),
          ),

        ],
      ),
    );
  }

  bool _isUploader() => currentUser.userid == comment.userId;

}
