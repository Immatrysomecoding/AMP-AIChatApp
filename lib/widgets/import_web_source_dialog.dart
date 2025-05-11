import 'package:flutter/material.dart';

class WebsiteImportDialog extends StatefulWidget {
  const WebsiteImportDialog({super.key, required this.onSubmit});

  final Function? onSubmit;

  @override
  State<WebsiteImportDialog> createState() => _WebsiteImportDialogState();
}

class _WebsiteImportDialogState extends State<WebsiteImportDialog> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  bool get isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _urlController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Import Web Source',
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
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Web URL *',
                hintText: 'https://example.com',
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
          style: FilledButton.styleFrom(
            backgroundColor: isFormValid ? Colors.blue : Colors.grey.shade300,
            foregroundColor: isFormValid ? Colors.white : Colors.grey,
          ),
          onPressed:
              isFormValid
                  ? () async {
                    final name = _nameController.text.trim();
                    final url = _urlController.text.trim();
                    await widget.onSubmit?.call(name, url);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                  : null,
          child: const Text('Import'),
        ),
      ],
    );
  }
}
