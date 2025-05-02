import 'package:aichat/core/models/Prompt.dart';

class PromptUtils {
  /// Extract all placeholders from prompt content
  /// Returns a list of unique placeholder names without brackets
  static List<String> extractPlaceholders(String promptContent) {
    final regex = RegExp(r'\[(.*?)\]');
    final matches = regex.allMatches(promptContent);

    final Set<String> uniquePlaceholders = {};
    for (final match in matches) {
      if (match.group(1) != null) {
        uniquePlaceholders.add(match.group(1)!);
      }
    }

    return uniquePlaceholders.toList();
  }

  /// Check if a prompt has placeholders that need user input
  static bool hasPlaceholders(Prompt prompt) {
    return extractPlaceholders(prompt.content).isNotEmpty;
  }

  /// Fill a prompt template with values
  /// values: Map of placeholder name (without brackets) to replacement value
  /// If a placeholder doesn't have a value, it remains unchanged
  static String fillPromptTemplate(
    String promptContent,
    Map<String, String> values,
  ) {
    String filledContent = promptContent;

    values.forEach((placeholder, value) {
      if (value.isNotEmpty) {
        filledContent = filledContent.replaceAll('[$placeholder]', value);
      }
    });

    return filledContent;
  }

  /// Get the display name for a language code
  static String getLanguageDisplayName(String? languageCode) {
    if (languageCode == null || languageCode.isEmpty) {
      return 'Auto';
    }

    // Map language codes to display names
    final Map<String, String> languageMap = {
      'en': 'English',
      'ar': 'Arabic',
      'zh-HK': 'Chinese (Hong Kong)',
      'zh-CN': 'Chinese (Simplified)',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'pt': 'Portuguese',
      'ru': 'Russian',
      // Add more languages as needed
    };

    return languageMap[languageCode] ?? languageCode;
  }

  /// Get language code from display name
  static String getLanguageCode(String displayName) {
    // Map display names to language codes
    final Map<String, String> displayToCode = {
      'English': 'en',
      'Arabic': 'ar',
      'Chinese (Hong Kong)': 'zh-HK',
      'Chinese (Simplified)': 'zh-CN',
      'Spanish': 'es',
      'French': 'fr',
      'German': 'de',
      'Italian': 'it',
      'Japanese': 'ja',
      'Korean': 'ko',
      'Portuguese': 'pt',
      'Russian': 'ru',
      // Add more languages as needed
    };

    return displayToCode[displayName] ??
        'en'; // Default to English if not found
  }

  /// Format the content of the prompt for display
  /// This highlights placeholders in a different color/style
  static String formatPromptContent(String content) {
    // In a real implementation, you might return styled text
    // For now, we're just returning the original content
    return content;
  }
}
