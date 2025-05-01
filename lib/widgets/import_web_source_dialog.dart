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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Row(
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
            const SizedBox(height: 12),

            // Name Field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'Enter knowledge unit name',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Web URL Field
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Web URL *',
                hintText: 'https://example.com',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Limitations box
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
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed:
                      isFormValid
                          ? () async {
                            final name = _nameController.text.trim();
                            final url = _urlController.text.trim();

                            await widget.onSubmit?.call(name, url);

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                          : null,

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFormValid
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                  ),
                  child: const Text('Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
