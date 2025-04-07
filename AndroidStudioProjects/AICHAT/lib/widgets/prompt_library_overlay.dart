import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aichat/core/providers/prompt_provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/core/models/Prompt.dart';
import 'create_prompt_dialog.dart';

class PromptLibraryOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;

  const PromptLibraryOverlay({
    super.key,
    required this.isVisible,
    required this.onClose,
  });

  @override
  State<PromptLibraryOverlay> createState() => _PromptLibraryOverlayState();
}

class _PromptLibraryOverlayState extends State<PromptLibraryOverlay> {
  String _selectedTab = 'Public Prompts';
  String _selectedCategory = 'All';
  bool _isCreatePromptVisible = false;

  @override
  void initState() {
  super.initState();
  Future.delayed(Duration.zero, () {
    final userProvider = Provider.of<UserTokenProvider>(context, listen: false);
    final accessToken = userProvider.user?.accessToken ?? '';

    if (accessToken.isNotEmpty) {
      final promptProvider = Provider.of<PromptProvider>(context, listen: false);
      promptProvider.fetchPrompts(accessToken);
    } else {
      print("Access token is empty. Cannot fetch prompts.");
    }
  });
}

  void _toggleCreatePrompt() {
    setState(() {
      _isCreatePromptVisible = !_isCreatePromptVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final promptProvider = Provider.of<PromptProvider>(context);
    final List<Prompt> prompts = promptProvider.prompts;

    return Stack(
      children: [
        // Prompt Library Panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          right: widget.isVisible ? 0 : -500,
          top: 0,
          bottom: 0,
          width: 500,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Prompt Library',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _toggleCreatePrompt,
                            color: Colors.blue,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: widget.onClose,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tabs
                Row(
                  children: [
                    _buildTab('Public Prompts'),
                    _buildTab('My Prompts'),
                  ],
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      hintText: 'Search...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.star_outline),
                        onPressed: () {},
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

                // Prompt items (Dynamic List)
                Expanded(
                  child: prompts.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: prompts.length,
                          itemBuilder: (context, index) {
                            final prompt = prompts[index];
                            return _buildPromptItem(prompt);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // Create Prompt Dialog
        if (_isCreatePromptVisible && widget.isVisible)
          CreatePromptDialog(
            onCancel: _toggleCreatePrompt,
            onSave: (title, content) {
              // You may call an API to add the new prompt
              _toggleCreatePrompt();
            },
          ),
      ],
    );
  }

  Widget _buildTab(String title) {
    final isSelected = _selectedTab == title;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromptItem(Prompt prompt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  prompt.title,
                  style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  prompt.content,
                  style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  prompt.isFavorite ? Icons.star : Icons.star_outline,
                  color: prompt.isFavorite ? Colors.amber : Colors.grey,
                ),
                onPressed: () {
                  // Handle favorite toggle
                },
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {},
                color: Colors.grey,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {},
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}