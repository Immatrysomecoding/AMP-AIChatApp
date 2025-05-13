import 'package:aichat/core/models/EmailRequest.dart';
import 'package:aichat/core/models/EmailResponse.dart';
import 'package:aichat/core/providers/chat_provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AiEmailAssistantScreen extends StatefulWidget {
  const AiEmailAssistantScreen({super.key});

  @override
  _AiEmailAssistantScreenState createState() => _AiEmailAssistantScreenState();
}

class _AiEmailAssistantScreenState extends State<AiEmailAssistantScreen> {
  final emailController = TextEditingController();
  final mainIdeaController = TextEditingController();
  final subjectController = TextEditingController();
  final senderController = TextEditingController();
  final receiverController = TextEditingController();
  String? _selectedImprovedAction;
  EmailResponse? _lastResponse;

  String selectedAction = 'full';
  String selectedLanguage = 'vietnamese';
  String selectedLength = 'long';
  String selectedFormality = 'neutral';
  String selectedTone = 'friendly';

  String responseText = '';

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Email Assistant"),
        backgroundColor: Colors.white,
        automaticallyImplyLeading:
                    false,
      ),
      // color: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      "Original Email",
                      emailController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Flexible(
                          child: RadioListTile(
                            fillColor: WidgetStateProperty.all(Colors.blue),
                            title: Text(
                              "Full Reply",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            value: 'full',
                            groupValue: selectedAction,
                            dense: true,
                            onChanged:
                                (val) => setState(() => selectedAction = val!),
                          ),
                        ),
                        Flexible(
                          child: RadioListTile(
                            fillColor: WidgetStateProperty.all(Colors.blue),
                            title: Text(
                              "Ideas",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            value: 'ideas',
                            groupValue: selectedAction,
                            dense: true,
                            onChanged:
                                (val) => setState(() => selectedAction = val!),
                          ),
                        ),
                      ],
                    ),
                    _buildTextField("Main Idea", mainIdeaController),
                    const Divider(),
                    _buildTextField("Subject", subjectController),
                    _buildTextField("Sender", senderController),
                    _buildTextField("Receiver", receiverController),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      "Language",
                      selectedLanguage,
                      ['vietnamese', 'english'],
                      (val) => setState(() => selectedLanguage = val!),
                    ),
                    if (selectedAction == 'full') ...[
                      _buildDropdown(
                        "Length",
                        selectedLength,
                        ['short', 'medium', 'long'],
                        (val) => setState(() => selectedLength = val!),
                      ),
                      _buildDropdown(
                        "Formality",
                        selectedFormality,
                        ['formal', 'neutral', 'informal'],
                        (val) => setState(() => selectedFormality = val!),
                      ),
                      _buildDropdown(
                        "Tone",
                        selectedTone,
                        ['friendly', 'serious', 'excited'],
                        (val) => setState(() => selectedTone = val!),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _sendRequest,
                        child: const Text("Submit"),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Response:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      responseText,
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    if (_lastResponse != null) _buildImprovedActionButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImprovedActionButtons() {
    if (_lastResponse == null || _lastResponse!.improvedActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Try an improvement:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              _lastResponse!.improvedActions.map((action) {
                final isSelected = _selectedImprovedAction == action;

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.blueAccent : null,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedImprovedAction = action;
                    });
                    _sendRequest();
                  },
                  child: Text(action),
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String current,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DropdownButtonFormField<String>(
        value: current,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        items:
            options
                .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _sendRequest() async {
    setState(() {
      responseText = "Generating...";
    });

    final provider = Provider.of<ChatProvider>(context, listen: false);
    final token =
        Provider.of<UserTokenProvider>(
          context,
          listen: false,
        ).user!.accessToken;

    final model = EmailRequest(
      mainIdea: mainIdeaController.text,
      action: _selectedImprovedAction ?? selectedAction,
      email: emailController.text,
      metadata: Metadata(
        context: [],
        subject: subjectController.text,
        sender: senderController.text,
        receiver: receiverController.text,
        language: selectedLanguage,
        style: Style(
          length: selectedLength,
          formality: selectedFormality,
          tone: selectedTone,
        ),
      ),
    );

    try {
      EmailResponse response;

      // 🔀 Switch between full reply and ideas mode
      if ((_selectedImprovedAction ?? selectedAction) == 'ideas') {
        response = await provider.replyEmailIdeas(token, model);
      } else {
        response = await provider.generateResponseEmail(token, model);
      }

      setState(() {
        _lastResponse = response;
        responseText = '''Email: ${response.email}

🧮 Remaining Usage: ${response.remainingUsage}
''';
      });
    } catch (e) {
      setState(() {
        responseText = "❌ Error: $e";
      });
    }
  }
}
