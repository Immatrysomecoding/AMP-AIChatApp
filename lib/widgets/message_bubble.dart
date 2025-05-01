import 'package:flutter/material.dart';
import 'package:aichat/core/models/ChatMessage.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;

  const MessageBubble({super.key, required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.only(
              bottom: 8.0,
              left: isUser ? 0 : 28,
              right: isUser ? 28 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar (only for non-user messages)
                if (!isUser) _buildAvatar(),

                if (!isUser) const SizedBox(width: 8),

                // Name
                Text(
                  isUser
                      ? 'You'
                      : message.assistant.name.isNotEmpty
                      ? message.assistant.name
                      : 'Assistant',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(width: 8),

                // Time
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Message bubble
          Container(
            margin: EdgeInsets.only(
              left: isUser ? 0 : 28,
              right: isUser ? 28 : 0,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.black87 : Colors.black,
                fontSize: 15,
              ),
            ),
          ),

          // Actions (only for AI messages)
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    onPressed: () {
                      // Copy message to clipboard
                    },
                    color: Colors.grey,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    onPressed: () {
                      // Regenerate response
                    },
                    color: Colors.grey,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isUser ? Colors.blue.shade600 : Colors.grey.shade800,
        shape: BoxShape.circle,
      ),
      child: Center(
        child:
            isUser
                ? const Text(
                  'Y',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : Icon(_getAIIcon(), color: Colors.white, size: 14),
      ),
    );
  }

  IconData _getAIIcon() {
    // Return appropriate icon based on assistant type
    if (message.assistant.id.contains('gpt')) {
      return Icons.circle;
    } else if (message.assistant.id.contains('gemini')) {
      return Icons.flight_takeoff;
    } else if (message.assistant.id.contains('claude')) {
      return Icons.auto_awesome;
    } else if (message.assistant.id.contains('deepseek')) {
      return Icons.explore;
    } else if (message.assistant.id.startsWith('bot_')) {
      return Icons.smart_toy_outlined;
    } else {
      return Icons.smart_toy;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Today, show time only
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == yesterday) {
      // Yesterday
      return 'Yesterday, ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      // Other dates
      return DateFormat('MMM d, HH:mm').format(dateTime);
    }
  }
}
