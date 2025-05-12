import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aichat/core/providers/prompt_provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/core/models/Prompt.dart';
import '../Dialog/create_prompt_dialog.dart';
import 'update_prompt_dialog.dart';

class PromptLibraryOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;
  final Function(Prompt)? onPromptSelected; // New callback for prompt selection

  const PromptLibraryOverlay({
    super.key,
    required this.isVisible,
    required this.onClose,
    this.onPromptSelected, // Add this parameter
  });

  @override
  State<PromptLibraryOverlay> createState() => _PromptLibraryOverlayState();
}

class _PromptLibraryOverlayState extends State<PromptLibraryOverlay> {
  String _selectedTab = 'Public Prompts';
  String _selectedCategory = 'All';
  bool _isCreatePromptVisible = false;
  bool _isUpdatePromptVisible = false;
  String currentUserToken = '';
  Prompt? _selectedPrompt;
  String searchQuery = '';
  bool isShowingFavorites = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      final userProvider = Provider.of<UserTokenProvider>(
        context,
        listen: false,
      );
      final accessToken = userProvider.user?.accessToken ?? '';

      if (accessToken.isNotEmpty) {
        final promptProvider = Provider.of<PromptProvider>(
          context,
          listen: false,
        );
        await promptProvider.fetchPrivatePrompts(accessToken);
        await promptProvider.fetchPublicPrompts(accessToken);

        setState(() {
          currentUserToken = accessToken;
        });
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

  void _toggleUpdatePrompt(Prompt? prompt) {
    setState(() {
      _isUpdatePromptVisible = !_isUpdatePromptVisible;
    });

    if (prompt != null) {
      _selectedPrompt = prompt;
    }
  }

  List<Prompt> get filteredPrompts {
    final promptProvider = Provider.of<PromptProvider>(context);
    final prompts =
        _selectedTab == 'Public Prompts'
            ? promptProvider.publicPrompts
            : promptProvider.prompts;

    return prompts.where((prompt) {
      final matchesSearch =
          searchQuery.isEmpty ||
          prompt.title.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'All' ||
          prompt.category?.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final promptProvider = Provider.of<PromptProvider>(context);
    final List<Prompt> privatePrompts = promptProvider.prompts;
    final List<Prompt> publicPrompts = promptProvider.publicPrompts;

    return Stack(
      children: [
        // Prompt Library Panel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          right: widget.isVisible ? 0 : -MediaQuery.of(context).size.width,
          top: 0,
          bottom: 0,
          width:
              MediaQuery.of(context).size.width < 600
                  ? MediaQuery.of(context).size.width
                  : 500,
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
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isShowingFavorites ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            isShowingFavorites = !isShowingFavorites;
                          });
                          if(isShowingFavorites) {
                            if(_selectedTab == 'Public Prompts') {
                              promptProvider.fetchPublicFavoritePrompts(currentUserToken);
                            } else {
                              promptProvider.fetchPrivateFavoritePrompts(currentUserToken);
                            }
                          } else {
                            if(_selectedTab == 'Public Prompts') {
                              promptProvider.fetchPublicPrompts(currentUserToken);
                            } else {
                              promptProvider.fetchPrivatePrompts(currentUserToken);
                            }
                          }
                        },
                      ),
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
                    ),
                  ),
                ),

                // Category Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    onChanged:
                        _selectedTab == 'My Prompts'
                            ? null // Disable when in My Prompts tab
                            : (String? newValue) {
                              setState(() {
                                _selectedCategory = newValue!;
                              });
                            },
                    items:
                        <String>[
                          'All',
                          'Writing',
                          'Chatbot',
                          'Marketing',
                          'Other',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                  ),
                ),

                // Prompt items (Dynamic List)
                Expanded(
                  child:
                      publicPrompts.isEmpty && privatePrompts.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredPrompts.length,
                            itemBuilder: (context, index) {
                              final prompt = filteredPrompts[index];
                              return _selectedTab == 'Public Prompts'
                                  ? _buildPublicPromptItem(prompt)
                                  : _buildPrivatePromptItem(prompt);
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
            onSave: (title, content, description) async {
              final promptProvider = Provider.of<PromptProvider>(
                context,
                listen: false,
              );
              await promptProvider.addPrompt(
                title,
                content,
                description,
                currentUserToken,
              );
              promptProvider.fetchPrivatePrompts(currentUserToken);

              setState(() {
                _isCreatePromptVisible = false;
              });
            },
          ),

        // Update Prompt Dialog
        if (_isUpdatePromptVisible && widget.isVisible)
          UpdatePromptDialog(
            prompt: _selectedPrompt!,
            onCancel: () {
              setState(() {
                _isUpdatePromptVisible = false;
              });
            },
            onSave: (title, content, description) async {
              final promptProvider = Provider.of<PromptProvider>(
                context,
                listen: false,
              );
              await promptProvider.updatePrompt(
                _selectedPrompt?.id,
                title,
                content,
                description,
                currentUserToken,
              );
              promptProvider.fetchPrivatePrompts(currentUserToken);

              setState(() {
                _isUpdatePromptVisible = false;
              });
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

  Widget _buildPublicPromptItem(Prompt prompt) {
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
                onPressed: () async {
                  // Handle favorite toggle
                  final promptProvider = Provider.of<PromptProvider>(
                    context,
                    listen: false,
                  );

                  final wasFavorite = prompt.isFavorite; // Save original state

                  setState(() {
                    prompt.isFavorite = !prompt.isFavorite;
                  });

                  if (wasFavorite) {
                    await promptProvider.removePromptFromFavorite(
                      prompt.id,
                      currentUserToken,
                    );
                  } else {
                    await promptProvider.addPromptToFavorite(
                      prompt.id,
                      currentUserToken,
                    );
                  }

                  await promptProvider.fetchPublicPrompts(currentUserToken);
                },
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {},
                color: Colors.grey,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed:
                    widget.onPromptSelected != null
                        ? () => widget.onPromptSelected!(prompt)
                        : null,
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivatePromptItem(Prompt prompt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap:
            widget.onPromptSelected != null
                ? () => widget.onPromptSelected!(prompt)
                : null,
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
                  onPressed: () async {
                    // Handle favorite toggle
                    final promptProvider = Provider.of<PromptProvider>(
                      context,
                      listen: false,
                    );

                    final wasFavorite = prompt.isFavorite;

                    setState(() {
                      prompt.isFavorite = !prompt.isFavorite;
                    });

                    if (wasFavorite) {
                      await promptProvider.removePromptFromFavorite(
                        prompt.id,
                        currentUserToken,
                      );
                    } else {
                      await promptProvider.addPromptToFavorite(
                        prompt.id,
                        currentUserToken,
                      );
                    }

                    await promptProvider.fetchPrivatePrompts(currentUserToken);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.mode_edit_outlined),
                  onPressed: () => _toggleUpdatePrompt(prompt),
                  color: Colors.grey,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_outlined),
                  onPressed: () {
                    // Handle delete action
                    final promptProvider = Provider.of<PromptProvider>(
                      context,
                      listen: false,
                    );
                    promptProvider.deletePrompt(prompt.id, currentUserToken);
                    promptProvider.fetchPrivatePrompts(currentUserToken);
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
