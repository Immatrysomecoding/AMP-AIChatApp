import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/core/providers/chat_provider.dart'; // Add this import
import 'package:intl/intl.dart';
import 'dart:math' as Math;

class ChatHistoryList extends StatefulWidget {
  const ChatHistoryList({super.key});

  @override
  State<ChatHistoryList> createState() => _ChatHistoryListState();
}

class _ChatHistoryListState extends State<ChatHistoryList> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Load conversations after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversations();
    });

    _searchController.addListener(() {
      setState(() {}); // Refresh when search text changes
    });
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserTokenProvider>(
        context,
        listen: false,
      );
      final token = userProvider.user?.accessToken ?? '';

      if (token.isEmpty) {
        print("No access token available");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print("Fetching conversations with token length: ${token.length}");

      // Make a direct API call to fetch conversations
      final url = Uri.parse(
        'https://api.dev.jarvis.cx/api/v1/ai-chat/conversations?assistantId=gpt-4o-mini&assistantModel=dify',
      );

      final headers = {'x-jarvis-guid': '', 'Authorization': 'Bearer $token'};

      print("Request URL: $url");
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] ?? [];
        print("API returned ${items.length} conversations");

        List<Map<String, dynamic>> conversations = [];

        for (var item in items) {
          try {
            final id = item['id'] ?? '';
            final title = item['title'] ?? 'Conversation';
            final createdAtString = item['createdAt'] ?? '';

            // Parse the ISO date string
            DateTime createdAt;
            try {
              createdAt = DateTime.parse(createdAtString);
            } catch (e) {
              // If date parsing fails, use current time
              createdAt = DateTime.now();
              print("Date parsing error for $id: $e");
            }

            // For debugging
            print(
              "Processing conversation: ID=$id, Title=$title, Date=$createdAtString",
            );

            conversations.add({
              'id': id,
              'title': title,
              'createdAt': createdAt,
            });
          } catch (e) {
            print("Error processing conversation: $e");
          }
        }

        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });

        print("Loaded ${_conversations.length} conversations");
      } else {
        print("API error: ${response.statusCode} - ${response.reasonPhrase}");
        print("Response body: ${response.body}");

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Exception loading conversations: $e");

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectConversation(String conversationId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserTokenProvider>(
        context,
        listen: false,
      );
      final token = userProvider.user?.accessToken ?? '';

      if (token.isEmpty) {
        print("No access token available");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Add ChatProvider import if not already there
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // Load the conversation messages using the ChatProvider
      await chatProvider.loadConversation(token, conversationId);

      // Navigate to chat screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/chat');
      }
    } catch (e) {
      print("Exception selecting conversation: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversation: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter conversations based on search
    final searchQuery = _searchController.text.toLowerCase();
    final filteredConversations =
        _conversations.where((conv) {
          return searchQuery.isEmpty ||
              conv['title'].toString().toLowerCase().contains(searchQuery);
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),

          // Status text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Found ${filteredConversations.length} conversations',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),

          // Conversation list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredConversations.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredConversations.length,
                      itemBuilder: (context, index) {
                        final conversation = filteredConversations[index];
                        return _buildConversationCard(conversation);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final id = conversation['id'] ?? '';
    final title = conversation['title'] ?? 'Conversation';
    final createdAt = conversation['createdAt'] ?? DateTime.now();
    final formattedDate = _formatDate(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade800),
      ),
      child: InkWell(
        onTap: () => _selectConversation(id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.shade900.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.blue.shade400,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

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
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Forward icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
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
            color: Colors.grey.shade600,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
