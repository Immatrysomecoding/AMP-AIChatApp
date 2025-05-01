import 'package:flutter/material.dart';

class ChatHistoryCard extends StatelessWidget {
  final String title;
  final String lastMessage;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ChatHistoryCard({
    super.key,
    required this.title,
    required this.lastMessage,
    this.isSelectionMode = false,
    this.isSelected = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(10),
          border:
              isSelected
                  ? Border.all(color: Colors.blue, width: 2)
                  : Border.all(color: Colors.grey.shade800),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Selection indicator or conversation icon
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Colors.blue : Colors.grey,
                    size: 24,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.blue.shade400,
                        size: 20,
                      ),
                    ),
                  ),
                ),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lastMessage,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action button (only in non-selection mode)
              if (!isSelectionMode)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onPressed: onTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
