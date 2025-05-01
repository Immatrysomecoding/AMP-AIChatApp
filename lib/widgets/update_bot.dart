import 'package:flutter/material.dart';

class UpdateBot extends StatelessWidget {
  const UpdateBot({
    super.key,
    required this.botId,
    required this.initialName,
    required this.initialDescription,
    required this.initialInstructions,
    required this.onBack,
  });
  final String botId;
  final String initialName;
  final String initialDescription;
  final String initialInstructions;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(initialName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            onBack();
          },
        ),
      ),
      body: Row(
        children: [
          // Knowledge Base
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Knowledge Base',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.storage),
                  title: Text("Bojack Horseman's..."),
                  trailing: Icon(Icons.delete),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('Add knowledge source'),
                  ),
                ),
              ],
            ),
          ),

          // Preview
          Expanded(
            flex: 3,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Preview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.smart_toy, size: 48, color: Colors.grey),
                const Text("No messages yet"),
                const Text("Start a conversation to test your bot!"),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText:
                                "Ask me anything, press '/' for prompts...",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Settings
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Persona & Instructions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    maxLines: 6,
                    controller: TextEditingController(
                      text: initialInstructions,
                    ),
                    decoration: InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text("Save Changes"),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "This section is where you input the prompt (instructions) for the bot. Here, you should clearly define the bot’s personality, behavior, and all the detailed guidelines it must follow.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
