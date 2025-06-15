// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:projectx/service/tasks.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui';

class ChatMessage {
  final String id;
  final Role role;
  final String? content;
  final List<Task>? tasks;
  final String name;
  final bool isLoading;

  ChatMessage({
    required this.role,
    this.content,
    this.tasks,
    required this.name,
    this.isLoading = false,
  }) : id = const Uuid().v4(),
       assert(
         content != null || tasks != null,
         'Message must have content or a list of tasks.',
       ),
       assert(
         content == null || tasks == null,
         'Message cannot have both content and tasks.',
       );
}

enum Role { user, iA }

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.tasks != null) {
      return _TasksListBubble(tasks: message.tasks!);
    }

    final theme = Theme.of(context);
    final isUser = message.role == Role.user;
    final alignment = isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bubbleColor = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surface.withOpacity(0.5);
    final textColor = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final borderRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              enabled: !isUser,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: borderRadius,
                  border: !isUser
                      ? Border.all(color: Colors.white.withOpacity(0.2))
                      : null,
                ),
                child: message.isLoading
                    ? SpinKitThreeBounce(color: textColor, size: 18)
                    : Text(
                        message.content ?? '',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksListBubble extends StatelessWidget {
  final List<Task> tasks;

  const _TasksListBubble({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Suas Tarefas Pendentes",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                ListView.builder(
                  itemCount: tasks.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return CheckboxListTile(
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: task.note != null
                          ? Text(
                              task.note!,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            )
                          : null,
                      value: task.isCompleted,
                      onChanged: (bool? value) {},
                      activeColor: theme.colorScheme.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
