import 'package:flutter/material.dart';

class CommentContentText extends StatelessWidget {
  final String content;

  const CommentContentText({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 0,
                color: Colors.white,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.start,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
