import 'package:flutter/material.dart';

class BotCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isFavorite;
  final VoidCallback onShare;
  final VoidCallback onUpdate;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final VoidCallback onChat;

  const BotCard({
    super.key,
    required this.title,
    required this.description,
    required this.isFavorite,
    required this.onShare,
    required this.onUpdate,
    required this.onFavorite,
    required this.onDelete,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot title and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: onShare,
                  color: Colors.grey,
                  tooltip: 'Share',
                ),
                IconButton(
                  icon: const Icon(Icons.mode_edit_outlined),
                  onPressed: onUpdate,
                  color: Colors.grey,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.star_outline),
                  onPressed: onFavorite,
                  color: isFavorite ? Colors.yellow : Colors.grey,
                  tooltip: 'Favorite',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_outlined),
                  onPressed: onDelete,
                  color: Colors.grey,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),

          // Bot description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),

          // Chat now button
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 16),
              child: ElevatedButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('Chat Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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