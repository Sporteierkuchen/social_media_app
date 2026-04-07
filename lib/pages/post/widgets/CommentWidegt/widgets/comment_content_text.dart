import 'package:flutter/material.dart';

class CommentContentText extends StatelessWidget {
  final String content;

  const CommentContentText({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.normal,
            height: 1.35,
          ),
          textAlign: TextAlign.start,
          softWrap: true,
        ),
      ),
    );
  }
}