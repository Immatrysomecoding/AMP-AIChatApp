import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final String selectedItem;

  const Sidebar({
    super.key,
    this.selectedItem = 'Chat',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
      ),
      child: Column(
        children: [
          // Logo section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.account_circle,
                  color: Colors.blue,
                  size: 36,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Jarvis',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {},
                  color: Colors.blue.shade700,
                ),
              ],
            ),
          ),

          // Navigation options
          _buildNavOption(
            icon: Icons.chat_bubble,
            label: 'Chat',
            isSelected: selectedItem == 'Chat',
            onTap: () {
              if (selectedItem != 'Chat') {
                Navigator.pushReplacementNamed(context, '/chat');
              }
            },
          ),

          _buildNavOption(
            icon: Icons.smart_toy_outlined,
            label: 'BOT',
            isSelected: selectedItem == 'BOT',
            onTap: () {
              if (selectedItem != 'BOT') {
                Navigator.pushReplacementNamed(context, '/bot');
              }
            },
          ),

          _buildNavOption(
            icon: Icons.group_outlined,
            label: 'Group',
            isSelected: selectedItem == 'Group',
            onTap: () {
              // Navigate to group screen
            },
          ),

          const Spacer(),

          // Bottom icons
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.blue.shade100),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined),
                  onPressed: () {},
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.email_outlined),
                  onPressed: () {},
                  color: Colors.grey,
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () {},
                  color: Colors.grey,
                ),
                IconButton(
                  icon: const Icon(Icons.star_outline),
                  onPressed: () {},
                  color: Colors.grey,
                ),
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: () {},
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.blue.shade100)
              : null,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}