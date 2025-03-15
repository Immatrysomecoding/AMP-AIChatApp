import 'package:flutter/material.dart';
import 'chat_history_card.dart';

class ChatHistoryList extends StatefulWidget {
  const ChatHistoryList({super.key});

  @override
  State<ChatHistoryList> createState() => _ChatHistoryListState();
}

class _ChatHistoryListState extends State<ChatHistoryList> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSelectionMode = false;
  final List<int> _selectedChats = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedChats.clear();
    });
  }

  void _toggleChatSelection(int chatId) {
    setState(() {
      if (_selectedChats.contains(chatId)) {
        _selectedChats.remove(chatId);
      } else {
        _selectedChats.add(chatId);
      }

      if (_selectedChats.isEmpty && _isSelectionMode) {
        _isSelectionMode = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dummy chat history data
    final List<Map<String, dynamic>> chatHistory = [
      {
        'id': 1,
        'title': 'Mock-UI Design for Final Project Screens',
        'lastMessage': '4 minutes ago',
      },
      {
        'id': 2,
        'title': 'Jarvis AI App: Widget Tree and Mock-UI Requirements',
        'lastMessage': '1 hour ago',
      },
      {
        'id': 3,
        'title': 'Preparing for sysinfo system call in xv6',
        'lastMessage': '3 days ago',
      },
      {
        'id': 4,
        'title': 'Derivative of sin(x)^x',
        'lastMessage': '3 days ago',
      },
      {
        'id': 5,
        'title': 'Challenging Perspectives on Ho Chi Minh\'s Teachings',
        'lastMessage': '3 days ago',
      },
      {
        'id': 6,
        'title': 'Implementing sysinfo system call in xv6',
        'lastMessage': '5 days ago',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Your chat history',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isSelectionMode)
                TextButton(
                  onPressed: _toggleSelectionMode,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search your chats...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade800,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),

        // Selection info
        Padding(
          padding: const EdgeInsets.all(24),
          child: _isSelectionMode
              ? Text(
            'Selected ${_selectedChats.length} chats',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          )
              : Row(
            children: [
              Text(
                'You have ${chatHistory.length} previous chats with Claude',
                style: TextStyle(
                  color: Colors.grey.shade400,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _toggleSelectionMode,
                child: const Text(
                  'Select',
                  style: TextStyle(
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Chat list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: chatHistory.length,
            itemBuilder: (context, index) {
              final chat = chatHistory[index];
              final isSelected = _selectedChats.contains(chat['id']);

              return ChatHistoryCard(
                title: chat['title'],
                lastMessage: chat['lastMessage'],
                isSelectionMode: _isSelectionMode,
                isSelected: isSelected,
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleChatSelection(chat['id']);
                  } else {
                    // Navigate to chat screen
                    Navigator.pushNamed(context, '/chat');
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    _toggleSelectionMode();
                    _toggleChatSelection(chat['id']);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}