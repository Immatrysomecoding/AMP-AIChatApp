import 'package:flutter/material.dart';

class SlackImportDialog extends StatefulWidget {
  const SlackImportDialog({super.key, required this.onSubmit});

  final Function? onSubmit;

  @override
  State<SlackImportDialog> createState() => _SlackImportDialogState();
}

class _SlackImportDialogState extends State<SlackImportDialog> {
  final _nameController = TextEditingController();
  final _slackBotToken = TextEditingController();

  bool get isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _slackBotToken.text.trim().isNotEmpty;

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
              controller: _slackBotToken,
              obscureText: true,
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
                    final slackToken = _slackBotToken.text.trim();
                    await widget.onSubmit?.call(name, slackToken);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                  : null,
          child: const Text('Import'),
        ),
      ],
    );
  }
}
