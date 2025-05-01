import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aichat/core/providers/chat_provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/core/models/ChatMessage.dart';
import 'chat_history_card.dart';
import 'package:intl/intl.dart';

class ChatHistoryList extends StatefulWidget {
  const ChatHistoryList({super.key});

  @override
  State<ChatHistoryList> createState() => _ChatHistoryListState();
}

class _ChatHistoryListState extends State<ChatHistoryList> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSelectionMode = false;
  final List<String> _selectedChats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();

    _searchController.addListener(() {
      setState(() {
        // Trigger rebuild when search text changes
      });
    });
  }

  void _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserTokenProvider>(context, listen: false);
    final accessToken = userProvider.user?.accessToken ?? '';

    if (accessToken.isNotEmpty) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.fetchConversations(accessToken);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _selectConversation(String conversationId) async {
    final userProvider = Provider.of<UserTokenProvider>(context, listen: false);
    final accessToken = userProvider.user?.accessToken ?? '';

    if (accessToken.isNotEmpty) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.loadConversation(accessToken, conversationId);
      Navigator.pushReplacementNamed(context, '/chat');
    }
  }

  void _deleteSelectedConversations() async {
    if (_selectedChats.isEmpty) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Conversations'),
            content: Text(
              'Are you sure you want to delete ${_selectedChats.length} conversation(s)?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('DELETE'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final userProvider = Provider.of<UserTokenProvider>(
        context,
        listen: false,
      );
      final accessToken = userProvider.user?.accessToken ?? '';

      if (accessToken.isNotEmpty) {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);

        // Delete all selected conversations
        for (final id in _selectedChats) {
          await chatProvider.deleteConversation(accessToken, id);
        }

        // Exit selection mode
        setState(() {
          _isSelectionMode = false;
          _selectedChats.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final conversations = chatProvider.conversations;

    // Filter conversations by search query
    final filteredConversations =
        conversations.where((conversation) {
          if (_searchController.text.isEmpty) return true;

          final searchTerm = _searchController.text.toLowerCase();
          return conversation.title.toLowerCase().contains(searchTerm);
        }).toList();

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
                'Chat History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isSelectionMode)
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed:
                          _selectedChats.isNotEmpty
                              ? _deleteSelectedConversations
                              : null,
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _toggleSelectionMode,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
              hintText: 'Search conversations...',
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
          child:
              _isSelectionMode
                  ? Text(
                    'Selected ${_selectedChats.length} conversation(s)',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : Row(
                    children: [
                      Text(
                        'You have ${filteredConversations.length} conversation(s)',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed:
                            filteredConversations.isNotEmpty
                                ? _toggleSelectionMode
                                : null,
                        child: const Text(
                          'Select',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
        ),

        // Chat list
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredConversations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conversation = filteredConversations[index];
                      final isSelected = _selectedChats.contains(
                        conversation.id,
                      );

                      // Format date
                      final formattedDate = _formatDate(conversation.createdAt);

                      return ChatHistoryCard(
                        title: conversation.title,
                        lastMessage: formattedDate,
                        isSelectionMode: _isSelectionMode,
                        isSelected: isSelected,
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleChatSelection(conversation.id);
                          } else {
                            _selectConversation(conversation.id);
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _toggleSelectionMode();
                            _toggleChatSelection(conversation.id);
                          }
                        },
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'No conversations match your search'
                : 'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try a different search term'
                : 'Start a new chat to begin',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          if (!isSearching) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/chat');
              },
              icon: const Icon(Icons.add),
              label: const Text('Start a New Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedChats.clear();
    });
  }

  void _toggleChatSelection(String conversationId) {
    setState(() {
      if (_selectedChats.contains(conversationId)) {
        _selectedChats.remove(conversationId);
      } else {
        _selectedChats.add(conversationId);
      }
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today, ${DateFormat('HH:mm').format(date)}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday, ${DateFormat('HH:mm').format(date)}';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE, HH:mm').format(date); // e.g. "Monday, 14:30"
    } else {
      return DateFormat('MMM d, yyyy').format(date); // e.g. "Jan 14, 2023"
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
