import 'package:aichat/core/providers/bot_provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:aichat/widgets/confirm_removal_dialog.dart';
import 'package:aichat/widgets/update_bot.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bot_card.dart';
import 'create_bot_dialog.dart';

class BotList extends StatefulWidget {
  final void Function(String id, String name, String desc, String instructions)?
  onUpdateBot;
  const BotList({super.key, this.onUpdateBot});

  @override
  State<BotList> createState() => _BotListState();
}

class _BotListState extends State<BotList> {
  String _filterValue = 'All Bots';
  final TextEditingController _searchController = TextEditingController();
  bool _isCreateBotDialogVisible = false;

  @override
  void initState() {
    super.initState();

    // Initialize the search controller
    _searchController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBots();
    }); // No await here
  }

  Future<void> _loadBots() async {
    String accessToken = getUserToken();

    if (accessToken.isNotEmpty) {
      final botProvider = Provider.of<BotProvider>(context, listen: false);
      await botProvider.fetchBots(accessToken);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleCreateBotDialog() {
    setState(() {
      _isCreateBotDialogVisible = !_isCreateBotDialogVisible;
    });
  }

  String getUserToken() {
    final userProvider = Provider.of<UserTokenProvider>(context, listen: false);
    return userProvider.user?.accessToken ?? '';
  }

  void _createBot(String name, String instructions, String description) async {
    String accessToken = getUserToken();

    final BotProvider botProvider = Provider.of<BotProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isCreateBotDialogVisible = false;
    });
    await botProvider.createBot(accessToken, name, instructions, description);
    await _loadBots();
  }

  void _confirmAndDeleteBot(String botId) {
  showDialog(
    context: context,
    builder: (context) => ConfirmRemoveDialog(
      title: "Confirm Bot Deletion",
      content: "Are you sure you want to remove this bot?",
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: () {
        Navigator.of(context).pop(); // close dialog
        _deleteBot(botId);           // perform deletion
      },
    ),
  );
}


  void _deleteBot(String botId) async {
    String accessToken = getUserToken();

    final BotProvider botProvider = Provider.of<BotProvider>(
      context,
      listen: false,
    );

    await botProvider.deleteBot(accessToken, botId);
    await _loadBots();
  }

  void _toggleFavoriteBot(String botId) async {
    String accessToken = getUserToken();

    final BotProvider botProvider = Provider.of<BotProvider>(
      context,
      listen: false,
    );

    await botProvider.toggleFavoriteBot(accessToken, botId);
    await _loadBots();
  }

  void _updateBot(String id, String name, String desc, String instructions) {
    widget.onUpdateBot?.call(id, name, desc ?? '', instructions ?? '');
  }

  @override
  Widget build(BuildContext context) {
    // Fetch the access token from the provider
    final botProvider = Provider.of<BotProvider>(context);
    final searchQuery = _searchController.text.toLowerCase();

    final filteredBots =
        botProvider.bots.where((bot) {
          // Search filter
          final matchesSearch = bot.assistantName.toLowerCase().contains(
            searchQuery,
          );

          // Filter dropdown logic
          // bool matchesFilter = true;
          // if (_filterValue == 'My Bots') {
          //   matchesFilter = bot.isMine; // Replace with your actual condition
          // } else if (_filterValue == 'Shared Bots') {
          //   matchesFilter = bot.isShared; // Replace with your actual condition
          // }

          // return matchesSearch && matchesFilter;
          return matchesSearch;
        }).toList();
    print(filteredBots);

    return Stack(
      children: [
        // Main content
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Bots',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            // Filter and Create button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Filter dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterValue,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _filterValue = newValue;
                            });
                          }
                        },
                        items:
                            <String>[
                              'All Bots',
                              'My Bots',
                              'Shared Bots',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    const Icon(Icons.filter_list, size: 16),
                                    const SizedBox(width: 8),
                                    Text(value),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Create Bot button
                  ElevatedButton.icon(
                    onPressed: _toggleCreateBotDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Create Bot'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bot list
            Expanded(
              child:
                  botProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children:
                            filteredBots.map((bot) {
                              return BotCard(
                                title: bot.assistantName,
                                description:
                                    bot.description ??
                                    'No description available',
                                isFavorite: bot.isFavorite,
                                onShare: () {},
                                onUpdate: () {
                                  _updateBot(
                                    bot.id,
                                    bot.assistantName,
                                    bot.description,
                                    bot.instructions,
                                  );
                                },
                                onFavorite: () {
                                  _toggleFavoriteBot(bot.id);
                                },
                                onDelete: () {
                                  _confirmAndDeleteBot(bot.id);
                                },
                                onChat: () {
                                  Navigator.pushNamed(context, '/chat');
                                },
                              );
                            }).toList(),
                      ),
            ),
          ],
        ),

        // Create Bot Dialog
        if (_isCreateBotDialogVisible)
          CreateBotDialog(
            onCancel: _toggleCreateBotDialog,
            onCreate: _createBot,
          ),
      ],
    );
  }
}
