import 'package:flutter/material.dart';

class ReplyContentText extends StatelessWidget {
  final String content;

  const ReplyContentText({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 14,
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