import 'package:flutter/material.dart';

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
  final List<String> _categories = [
    'All',
    'Marketing',
    'Business',
    'SEO',
    'Writing',
    'Coding',
    'Career',
    'Chatbot',
    'Education'
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
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
                        onPressed: () {},
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

            // Categories
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        }
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                        side: BorderSide(
                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Prompt items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPromptItem(
                    'Grammar corrector',
                    'Improve your spelling and grammar by correcting errors in your writing.',
                  ),
                  _buildPromptItem(
                    'Learn Code FAST!',
                    'Teach you the code with the most understandable knowledge.',
                  ),
                  _buildPromptItem(
                    'Story generator',
                    'Write your own beautiful story.',
                  ),
                  _buildPromptItem(
                    'Essay improver',
                    'Improve your content\'s effectiveness with ease.',
                  ),
                  _buildPromptItem(
                    'Pro tips generator',
                    'Get perfect tips and advice tailored to your field with this prompt!',
                  ),
                  _buildPromptItem(
                    'Resume Editing',
                    'Provide suggestions on how to improve your resume to make it stand out.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildPromptItem(String title, String description) {
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.star_outline),
                onPressed: () {},
                color: Colors.grey,
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