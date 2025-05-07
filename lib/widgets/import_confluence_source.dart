import 'package:flutter/material.dart';

class ConfluenceImportDialog extends StatefulWidget {
  const ConfluenceImportDialog({super.key, required this.onSubmit});

  final Function? onSubmit;

  @override
  State<ConfluenceImportDialog> createState() => _ConfluenceImportDialogState();
}

class _ConfluenceImportDialogState extends State<ConfluenceImportDialog> {
  final _nameController = TextEditingController();
  final _wikiPageUrl = TextEditingController();
  final _username = TextEditingController();
  final _apiToken = TextEditingController();

  bool get isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _wikiPageUrl.text.trim().isNotEmpty &&
      _username.text.trim().isNotEmpty &&
      _apiToken.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Import Slack Source',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'Enter knowledge unit name',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _wikiPageUrl,
              decoration: const InputDecoration(
                labelText: 'Wiki Page Url *',
                hintText: 'https://your-domain.atlassian.net',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _username,
              decoration: const InputDecoration(
                labelText: 'Username *',
                hintText: 'Enter your Confluence username',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiToken,
              decoration: const InputDecoration(
                labelText: 'API Token *',
                hintText: 'Enter your Confluence API token',
              ),
              onChanged: (_) => setState(() {}),
            ),

            TextField(
              controller: _wikiPageUrl,
              decoration: const InputDecoration(
                labelText: 'Slack Bot Token *',
                hintText: 'Enter your Slack Bot Token',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Limitation:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• You can load up to 64 pages at a time'),
                  Text('• Need more? Contact us at myjarvischat@gmail.com'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed:
              isFormValid
                  ? () async {
                    final name = _nameController.text.trim();
                    final wikiPageUrl = _wikiPageUrl.text.trim();
                    final username = _username.text.trim();
                    final apiToken = _apiToken.text.trim();
                    await widget.onSubmit?.call(name, wikiPageUrl, username, apiToken);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                  : null,
          child: const Text('Import'),
        ),
      ],
    );
  }
}
