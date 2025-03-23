import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ChatMessage {
  final Role role;
  final String content;
  final String name;
  final bool isLoading;

  ChatMessage({
    required this.role,
    required this.content,
    required this.name,
    this.isLoading = false,
  });
}

enum Role { user, iA }

class ChatBubble extends StatelessWidget {
  final Role role;
  final String content;
  final Widget photo;
  final bool isLoading;

  const ChatBubble({
    super.key,
    required this.role,
    required this.content,
    required this.photo,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final alignment =
        role == Role.user ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor = role == Role.user ? Colors.blue[100] : Colors.grey[300];
    final textColor = role == Role.user ? Colors.black : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment:
                role == Role.user
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
            children: [
              if (role == Role.iA) ...[photo, const SizedBox(width: 8.0)],
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child:
                      isLoading
                          ? const SpinKitThreeBounce(
                            color: Colors.blue,
                            size: 30.0,
                          )
                          : Text(content, style: TextStyle(color: textColor)),
                ),
              ),
              if (role == Role.user) ...[const SizedBox(width: 8.0), photo],
            ],
          ),
        ],
      ),
    );
  }
}
