import 'package:flutter/material.dart';
import 'bot_card.dart';

class BotList extends StatefulWidget {
  const BotList({super.key});

  @override
  State<BotList> createState() => _BotListState();
}

class _BotListState extends State<BotList> {
  String _filterValue = 'All Bots';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    items: <String>['All Bots', 'My Bots', 'Shared Bots']
                        .map<DropdownMenuItem<String>>((String value) {
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
                onPressed: () {
                  // TODO: Implement create bot functionality
                },
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
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              BotCard(
                title: 'Bot thinh',
                description: 'No description available',
                onShare: () {},
                onFavorite: () {},
                onMore: () {},
                onChat: () {
                  Navigator.pushNamed(context, '/chat');
                },
              ),

              // You can add more bot cards here as needed
            ],
          ),
        ),
      ],
    );
  }
}