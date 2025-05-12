import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aichat/core/models/Prompt.dart';
import 'package:aichat/core/providers/prompt_provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';

class PromptInputOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onClose;
  final Prompt prompt;
  final Function(String) onSubmit;

  const PromptInputOverlay({
    super.key,
    required this.isVisible,
    required this.onClose,
    required this.prompt,
    required this.onSubmit,
  });

  @override
  State<PromptInputOverlay> createState() => _PromptInputOverlayState();
}

class _PromptInputOverlayState extends State<PromptInputOverlay> {
  final Map<String, TextEditingController> _inputControllers = {};
  String _selectedLanguage = 'Auto';
  bool _isFavorite = false;
  bool _isViewingPrompt = false;
  late TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.prompt.content);
    _parsePromptForInputs();

    // Initialize language from prompt if available
    if (widget.prompt.language != null && widget.prompt.language!.isNotEmpty) {
      _selectedLanguage = widget.prompt.language!;
    }

    // Initialize favorite status
    _isFavorite = widget.prompt.isFavorite;
  }

  @override
  void didUpdateWidget(PromptInputOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prompt.id != widget.prompt.id) {
      // Clear old controllers and parse new inputs if prompt changed
      _disposeControllers();
      _promptController.text = widget.prompt.content;
      _parsePromptForInputs();

      // Update language
      if (widget.prompt.language != null &&
          widget.prompt.language!.isNotEmpty) {
        setState(() {
          _selectedLanguage = widget.prompt.language!;
        });
      } else {
        setState(() {
          _selectedLanguage = 'Auto';
        });
      }

      // Update favorite status
      setState(() {
        _isFavorite = widget.prompt.isFavorite;
      });
    }
  }

  void _parsePromptForInputs() {
    // Parse the prompt content to identify all [PLACEHOLDERS]
    final regex = RegExp(r'\[(.*?)\]');
    final matches = regex.allMatches(_promptController.text);

    // Create a controller for each unique placeholder
    final Set<String> placeholders = {};
    for (final match in matches) {
      final placeholder = match.group(1)!;
      if (!placeholders.contains(placeholder)) {
        placeholders.add(placeholder);
        _inputControllers[placeholder] = TextEditingController();
      }
    }
  }

  void _disposeControllers() {
    for (var controller in _inputControllers.values) {
      controller.dispose();
    }
    _inputControllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    _promptController.dispose();
    super.dispose();
  }

  String _buildFullPrompt() {
    String fullPrompt = _promptController.text;

    // Replace each placeholder with user input
    _inputControllers.forEach((placeholder, controller) {
      final userInput =
          controller.text.trim().isEmpty ? placeholder : controller.text.trim();
      fullPrompt = fullPrompt.replaceAll('[$placeholder]', userInput);
    });

    return fullPrompt;
  }

  void _submitPrompt() {
    final fullPrompt = _buildFullPrompt();
    widget.onSubmit(fullPrompt);

    // Clear inputs after submission
    for (var controller in _inputControllers.values) {
      controller.clear();
    }

    widget.onClose();
  }

  void _toggleFavorite() async {
    final userProvider = Provider.of<UserTokenProvider>(context, listen: false);
    final accessToken = userProvider.user?.accessToken ?? '';

    if (accessToken.isEmpty) return;

    final promptProvider = Provider.of<PromptProvider>(context, listen: false);

    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      if (_isFavorite) {
        await promptProvider.addPromptToFavorite(widget.prompt.id, accessToken);
      } else {
        await promptProvider.removePromptFromFavorite(
          widget.prompt.id,
          accessToken,
        );
      }

      // Refresh prompts after updating favorite
      await promptProvider.fetchPublicPrompts(accessToken);
      await promptProvider.fetchPrivatePrompts(accessToken);
    } catch (e) {
      print('Error toggling favorite: $e');
      // Revert UI state if operation failed
      setState(() {
        _isFavorite = !_isFavorite;
      });
    }
  }

  void _toggleViewPrompt() {
    setState(() {
      _isViewingPrompt = !_isViewingPrompt;
    });
  }

  void _goBackOrClose() {
    if (_isViewingPrompt) {
      setState(() {
        _isViewingPrompt = false;
      });
    } else {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Full screen overlay with semi-transparent background
          GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),

          // Bottom prompt overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main prompt panel
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: _goBackOrClose,
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_back_ios, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isViewingPrompt
                                        ? "Back to ${widget.prompt.title}"
                                        : widget.prompt.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                if (!_isViewingPrompt)
                                  IconButton(
                                    icon: Icon(
                                      _isFavorite
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 22,
                                    ),
                                    onPressed: _toggleFavorite,
                                    color:
                                        _isFavorite
                                            ? Colors.amber
                                            : Colors.grey,
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: widget.onClose,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (_isViewingPrompt)
                        // Prompt editing view
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Edit Prompt Template",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: TextField(
                                      controller: _promptController,
                                      maxLines: null,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText:
                                            "Edit prompt template here...",
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
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
                                        'Use square brackets [ ] to specify user input. This edit is temporary and will not be saved.',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      // Re-parse for inputs if template changed
                                      _disposeControllers();
                                      _parsePromptForInputs();
                                      _toggleViewPrompt();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text("Apply Changes"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        // Main prompt input screen
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Prompt info
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                "Writing · ${widget.prompt.userName}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                widget.prompt.description ?? "",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),

                            // Language selector
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Row(
                                children: [
                                  Text(
                                    "Output Language",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButton<String>(
                                      value: _selectedLanguage,
                                      underline: const SizedBox(),
                                      isDense: true,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      items:
                                          <String>[
                                            'Auto',
                                            'English',
                                            'Arabic',
                                            'Chinese (Hong Kong)',
                                            'Chinese (Simplified)',
                                            'Spanish',
                                          ].map<DropdownMenuItem<String>>((
                                            String value,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedLanguage =
                                              newValue ?? 'Auto';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Input fields for each placeholder
                            if (_inputControllers.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildInputFields(),
                                ),
                              ),

                            // View Prompt button
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: InkWell(
                                onTap: _toggleViewPrompt,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "View & Edit Prompt",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Send button
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ElevatedButton(
                                onPressed: _submitPrompt,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Send',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Transform.rotate(
                                      angle: 0.8, // About 45 degrees
                                      child: const Icon(Icons.send, size: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                    ],
                  ),
                ),

                // Cover the text input field area
                Container(
                  height: 60,
                  color: Colors.white, // Same as your app background
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInputFields() {
    final List<Widget> fields = [];

    _inputControllers.forEach((placeholder, controller) {
      fields.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: placeholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onSubmitted: (_) => _submitPrompt(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    });

    return fields;
  }
}
