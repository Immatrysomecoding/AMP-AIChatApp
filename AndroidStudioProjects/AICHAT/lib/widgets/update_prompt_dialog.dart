import 'package:flutter/material.dart';
import 'package:aichat/core/models/Prompt.dart';

class UpdatePromptDialog extends StatefulWidget {
  final Prompt prompt;
  final VoidCallback onCancel;
  final Function(String name, String content, String description) onSave;

  const UpdatePromptDialog({
    super.key,
    required this.prompt,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<UpdatePromptDialog> createState() => _UpdatePromptDialogState();
}

class _UpdatePromptDialogState extends State<UpdatePromptDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // This allows tapping outside to dismiss the dialog
      onTap: widget.onCancel,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            // This prevents taps on the dialog from closing it
            onTap: () {},
            child: Container(
              width: 600,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                          'Update Prompt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: widget.onCancel,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),

                  // Form content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Name field
                        Row(
                          children: [
                          const Text(
                            'Name',
                            style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '*',
                            style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            ),
                          ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController..text = widget.prompt.title,
                          decoration: InputDecoration(
                          hintText: 'Name of the prompt',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Prompt field
                        Row(
                          children: [
                          const Text(
                            'Prompt',
                            style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '*',
                            style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            ),
                          ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Prompt textarea
                        TextField(
                          controller: _descriptionController..text = widget.prompt.description,
                          decoration: InputDecoration(
                          hintText:
                            'Which type of prompt is this? What is it for?',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          ),
                          minLines: 1,
                          maxLines: 2,
                        ),

                        const SizedBox(height: 8),

                        // Info box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                          children: [
                            Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                            child: Text(
                              'Use square brackets [ ] to specify user input.',
                              style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              ),
                            ),
                            ),
                          ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: _contentController..text = widget.prompt.content,
                          decoration: InputDecoration(
                          hintText:
                            'e.g: Write an article about [TOPIC], make sure to include these keywords: [KEYWORDS]',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          ),
                          minLines: 5,
                          maxLines: 8,
                        ),
                      ],
                    ),
                  ),

                  // Buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Cancel button
                        OutlinedButton(
                          onPressed: widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),

                        const SizedBox(width: 12),

                        // Create button
                        ElevatedButton(
                          onPressed: () {
                            if (_nameController.text.isEmpty ||
                                _descriptionController.text.isEmpty ||
                                _contentController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please fill in all fields.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              return;
                            }

                            widget.onSave(
                              _nameController.text,
                              _contentController.text,
                              _descriptionController.text,
                            );

                            widget.onCancel();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
