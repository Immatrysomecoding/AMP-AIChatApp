import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class LocalFileImportDialog extends StatefulWidget {
  const LocalFileImportDialog({super.key});

  @override
  State<LocalFileImportDialog> createState() => _LocalFileImportDialogState();
}

class _LocalFileImportDialogState extends State<LocalFileImportDialog> {
  PlatformFile? selectedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final allowedExtensions = [
        'c',
        'cpp',
        'docx',
        'html',
        'java',
        'json',
        'md',
        'pdf',
        'php',
        'pptx',
        'py',
        'rb',
        'tex',
        'txt',
      ];

      // Get file extension
      final fileExtension = file.name.split('.').last;

      if (allowedExtensions.contains(fileExtension)) {
        setState(() {
          selectedFile = file;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Unsupported file type (${file.name})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Import Local Files',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Upload Box
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload, size: 36, color: Colors.blue.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'Click or drag files to upload',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Supported formats: .c, .cpp, .docx, .html, .java, .json, .md, .pdf, .php,\n'
                      '.pptx, .py, .rb, .tex, .txt',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    if (selectedFile != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        selectedFile!.name,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ],
                ),
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
                      selectedFile != null
                          ? () {
                            Navigator.of(context).pop(selectedFile);
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedFile != null
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
