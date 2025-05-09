import 'package:flutter/material.dart';

class PublishScreen extends StatefulWidget {
  @override
  _PublishScreenState createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final TextEditingController _changelogController = TextEditingController();
  Map<String, bool> selectedPlatforms = {
    'Slack': false,
    'Telegram': false,
    'Messenger': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Publish'),
        actions: [
          TextButton(
            onPressed: selectedPlatforms.containsValue(true)
                ? () {
                    // Handle publish logic
                  }
                : null,
            child: Text('Publish'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Changelog', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                ElevatedButton(onPressed: () {}, child: Text('Generate')),
              ],
            ),
            TextField(
              controller: _changelogController,
              maxLines: 5,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: "Enter this bot version's changelog",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Text('Publish to *', style: Theme.of(context).textTheme.titleMedium),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "By publishing your bot on the following platforms, you fully understand and agree to abide by Terms of service for each publishing channel.",
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            ..._buildPlatformList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlatformList() {
    final configs = {
      'Slack': 'Not Configured',
      'Telegram': 'Verified',
      'Messenger': 'Not Configured',
    };

    return selectedPlatforms.keys.map((platform) {
      return CheckboxListTile(
        title: Row(
          children: [
            Image.asset(
              'assets/${platform.toLowerCase()}.png',
              width: 24,
              height: 24,
            ),
            SizedBox(width: 8),
            Text(platform),
            SizedBox(width: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: configs[platform] == 'Verified' ? Colors.green[100] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                configs[platform]!,
                style: TextStyle(
                  color: configs[platform] == 'Verified' ? Colors.green : Colors.black87,
                  fontSize: 12,
                ),
              ),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                // Handle configure logic
              },
              child: Text('Configure'),
            )
          ],
        ),
        value: selectedPlatforms[platform],
        onChanged: (bool? value) {
          setState(() {
            selectedPlatforms[platform] = value!;
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
      );
    }).toList();
  }
}
