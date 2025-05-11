import 'package:aichat/core/providers/knowledge_provider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';

class LocalFileImportDialog extends StatefulWidget {
  const LocalFileImportDialog({super.key});

  @override
  State<LocalFileImportDialog> createState() => _LocalFileImportDialogState();
}

class _LocalFileImportDialogState extends State<LocalFileImportDialog> {
  List<PlatformFile> selectedFiles = [];

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null && result.files.isNotEmpty) {
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

      final validFiles =
          result.files.where((file) {
            final extension = file.name.split('.').last.toLowerCase();
            return allowedExtensions.contains(extension);
          }).toList();

      final invalidFiles = result.files.where((file) {
        final extension = file.name.split('.').last.toLowerCase();
        return !allowedExtensions.contains(extension);
      });

      if (invalidFiles.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Some files were not added due to unsupported format.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }

      final provider = Provider.of<KnowledgeProvider>(context, listen: false);
      final token =
          Provider.of<UserTokenProvider>(
            context,
            listen: false,
          ).user?.accessToken;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User token is not available.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } else {
        for (var file in validFiles) {
          // Upload file and wait for response
          final uploadedId = await provider.uploadLocalFile(token, file);

          // Check and log response
          if (uploadedId.isNotEmpty) {
            debugPrint('Upload successful for ${file.name}. ID: $uploadedId');

            setState(() {
              selectedFiles.add(file);
            });
          } else {
            debugPrint('Upload failed for ${file.name}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload failed for ${file.name}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
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

            // Upload box
            GestureDetector(
              onTap: _pickFiles,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 36,
                      color: Colors.blue.shade400,
                    ),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List of selected files
            if (selectedFiles.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selected Files:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: selectedFiles.length,
                  itemBuilder: (context, index) {
                    final file = selectedFiles[index];
                    return ListTile(
                      title: Text(file.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            selectedFiles.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed:
                      selectedFiles.isNotEmpty
                          ? () {
                            Navigator.of(context).pop(selectedFiles);
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        selectedFiles.isNotEmpty
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
