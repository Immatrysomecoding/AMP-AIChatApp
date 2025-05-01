import 'package:flutter/material.dart';

class UpdateKnowledgeBaseDialog extends StatefulWidget {
  final String currentName;
  final String currentDescription;
  final Function(String name, String description)? onSave;
  final Function()? onCancel;

  const UpdateKnowledgeBaseDialog({
    super.key,
    required this.currentName,
    required this.currentDescription,
    this.onSave,
    this.onCancel,
  });

  @override
  State<UpdateKnowledgeBaseDialog> createState() => _UpdateKnowledgeBaseDialogState();
}

class _UpdateKnowledgeBaseDialogState extends State<UpdateKnowledgeBaseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _descController = TextEditingController(text: widget.currentDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text("Update Knowledge Base"),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: "Knowledge Base Name *",
                  hintText: "Enter a unique name for your knowledge base",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLength: 500,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description",
                  hintText:
                      "Briefly describe the purpose of this knowledge base (e.g., Jarvis AI's knowledge base,...)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave!(
                _nameController.text.trim(),
                _descController.text.trim(),
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text("Update"),
        ),
      ],
    );
  }
}
