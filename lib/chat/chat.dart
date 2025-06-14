import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:uuid/uuid.dart';

class ChatMessage {
  final String id;
  final Role role;
  final String content;
  final String name;
  final bool isLoading;

  ChatMessage({
    required this.role,
    required this.content,
    required this.name,
    this.isLoading = false,
  }): id = const Uuid().v4();
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
    final isUser = role == Role.user;
    final alignment = isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final mainAxisAlignment = isUser
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;
    final bubbleColor = isUser ? Colors.blueAccent : Colors.white;
    final textColor = isUser ? Colors.white : Colors.black87;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
      bottomRight: isUser
          ? const Radius.circular(4)
          : const Radius.circular(20),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  child: photo,
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: borderRadius,
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 18,
                  ),
                  child: isLoading
                      ? const SpinKitThreeBounce(color: Colors.blue, size: 24.0)
                      : Text(
                          content,
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue[100],
                  child: photo,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
