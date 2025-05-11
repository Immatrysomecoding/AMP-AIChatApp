import 'package:flutter/material.dart';

class CreateKnowledgeBaseDialog extends StatefulWidget {
  final Function(String name, String description)? onSave;
  final Function()? onCancel;
  
  const CreateKnowledgeBaseDialog({
    super.key,
    this.onSave,
    this.onCancel,
  });

  @override
  State<CreateKnowledgeBaseDialog> createState() => _CreateKnowledgeBaseDialogState();
}

class _CreateKnowledgeBaseDialogState extends State<CreateKnowledgeBaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text("Create a Knowledge Base"),
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
          style: FilledButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave!(_nameController.text.trim(), _descController.text.trim());
              Navigator.of(context).pop();
            }
          },
          child: const Text("Create"),
        ),
      ],
    );
  }
}
