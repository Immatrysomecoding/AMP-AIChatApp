import 'package:flutter/material.dart';
import 'package:aichat/core/models/Prompt.dart';

class PromptSuggestionDialog extends StatelessWidget {
  final List<Prompt> prompts;
  final Function(Prompt) onPromptSelected;
  final VoidCallback onDismiss;

  const PromptSuggestionDialog({
    Key? key,
    required this.prompts,
    required this.onPromptSelected,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use a maximum of 8 items for display
    final displayPrompts = prompts.length > 8 ? prompts.sublist(0, 8) : prompts;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Invisible barrier for tapping outside to dismiss
          Positioned.fill(
            child: GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),

          // Position at the bottom of the screen, just above the text field
          Positioned(
            left: 20,
            right: 20,
            bottom: 80, // Position above the input field - ADJUST THIS VALUE
            child: Material(
              elevation: 8,
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    displayPrompts.map((prompt) {
                      return InkWell(
                        onTap: () => onPromptSelected(prompt),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prompt.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (prompt.description != null &&
                                  prompt.description!.isNotEmpty)
                                Text(
                                  prompt.description!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
