import 'package:aichat/core/models/BotConfiguration.dart';
import 'package:aichat/core/providers/bot_provider.dart';
import 'package:aichat/core/providers/user_token_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PublishScreen extends StatefulWidget {
  @override
  _PublishScreenState createState() => _PublishScreenState();

  final String botId;
  const PublishScreen({super.key, required this.botId});
}

class _PublishScreenState extends State<PublishScreen> {
  final _slackTokenController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  final _signingSecretController = TextEditingController();
  final TextEditingController _telegramTokenController =
      TextEditingController();
  final TextEditingController _messengerTokenController =
      TextEditingController();
  final TextEditingController _messengerPageIdController =
      TextEditingController();
  final TextEditingController _messengerAppSecretController =
      TextEditingController();
  bool isTelegramVerified = false;
  bool isMessengerVerified = false;
  bool isSlackVerified = false;

  @override
  void initState() {
    super.initState();

    //Check the bot configurations to set the verified status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final botProvider = Provider.of<BotProvider>(context, listen: false);
      botProvider.fetchBots(
        Provider.of<UserTokenProvider>(
          context,
          listen: false,
        ).user!.accessToken,
      );
      // Fetch the bot configurations
      botProvider.getBotConfiguration(
        Provider.of<UserTokenProvider>(
          context,
          listen: false,
        ).user!.accessToken,
        widget.botId,
      );

      // Set the verification statuses based on botConfigurations
      bool slackVerified = false;
      bool telegramVerified = false;
      bool messengerVerified = false;

      botProvider.botConfigurations.forEach((config) {
        if (config.type == 'slack') slackVerified = true;
        if (config.type == 'telegram') telegramVerified = true;
        if (config.type == 'messenger') messengerVerified = true;
      });

      setState(() {
        isSlackVerified = slackVerified;
        isTelegramVerified = telegramVerified;
        isMessengerVerified = messengerVerified;
      });
    });
  }

  final TextEditingController _changelogController = TextEditingController();
  Map<String, bool> selectedPlatforms = {
    'Slack': false,
    'Telegram': false,
    'Messenger': false,
  };

  Future<void> _disconnectBot(String type) async {
    try {
      final token =
          Provider.of<UserTokenProvider>(
            context,
            listen: false,
          ).user!.accessToken;

      await Provider.of<BotProvider>(
        context,
        listen: false,
      ).disconnectBotConfiguration(token, widget.botId, type);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type disconnected successfully')),
      );

      // Refresh the configurations
      await Provider.of<BotProvider>(
        context,
        listen: false,
      ).getBotConfiguration(token, widget.botId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to disconnect $type')));
    }
  }

  Future<void> _showTelegramConfigDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Configure Telegram Bot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect to Telegram Bots and chat with this bot in Telegram App',
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse(
                    'https://jarvis.cx/help/knowledge-base/publish-bot/telegram',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch the URL')),
                    );
                  }
                },
                child: Text(
                  'How to obtain Telegram configurations?',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Telegram information'),
                ],
              ),
              SizedBox(height: 12),
              _buildRequiredTextField('Token', _telegramTokenController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String token = _telegramTokenController.text.trim();
                if (token.isNotEmpty) {
                  final botProvider = Provider.of<BotProvider>(
                    context,
                    listen: false,
                  );
                  final userToken =
                      Provider.of<UserTokenProvider>(
                        context,
                        listen: false,
                      ).user!.accessToken ??
                      '';
                  bool isVerified = await botProvider.verifyTelegramBot(
                    userToken,
                    token,
                  );

                  setState(() {
                    isTelegramVerified = isVerified;
                  });
                  if (isTelegramVerified) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Telegram Bot verified successfully!'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to verify Telegram Bot.')),
                    );
                  }
                  Navigator.of(context).pop();
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showMessengerConfigDialog() {
    final callbackUrl =
        'https://knowledge-api.jarvis.cx/kb-core/v1/hook/messenger/${widget.botId}';
    const verifyToken = 'knowledge';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Configure Messenger Bot'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect to Messenger Bots and chat with this bot in Messenger App',
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse(
                      'https://jarvis.cx/help/knowledge-base/publish-bot/messenger',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not launch the URL'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'How to obtain Messenger configurations?',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Messenger copylink'),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Copy the following content to your Messenger app configuration page.',
                ),
                SizedBox(height: 12),
                _buildCopySection(label: 'Callback URL', url: callbackUrl),
                _buildCopySection(label: 'Verify Token', url: verifyToken),
                SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Messenger information'),
                  ],
                ),
                SizedBox(height: 12),
                _buildRequiredTextField(
                  'Messenger Bot Token',
                  _messengerTokenController,
                ),
                _buildRequiredTextField(
                  'Messenger Bot Page ID',
                  _messengerPageIdController,
                ),
                _buildRequiredTextField(
                  'Messenger Bot App Secret',
                  _messengerAppSecretController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final token = _messengerTokenController.text.trim();
                final pageId = _messengerPageIdController.text.trim();
                final appSecret = _messengerAppSecretController.text.trim();

                if (token.isNotEmpty &&
                    pageId.isNotEmpty &&
                    appSecret.isNotEmpty) {
                  // Save logic here
                  Navigator.of(context).pop();
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSlackConfigDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Configure Slack Bot'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect to Slack Bots and chat with this bot in Slack App',
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(
                        'https://jarvis.cx/help/knowledge-base/publish-bot/slack',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch the URL'),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'How to obtain Slack configurations?',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '1️⃣ Slack copylink',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Copy the following content to your Slack app configuration page.',
                  ),
                  SizedBox(height: 8),
                  _buildCopySection(
                    label: 'OAuth2 Redirect URLs',
                    url:
                        'https://knowledge-api.jarvis.cx/kb-core/v1/bot-integration/slack/auth/6ed67493-c04b-41e9-a7e8-cdd740de1d6c',
                  ),
                  _buildCopySection(
                    label: 'Event Request URL',
                    url:
                        'https://knowledge-api.jarvis.cx/kb-core/v1/hook/slack/6ed67493-c04b-41e9-a7e8-cdd740de1d6c',
                  ),
                  _buildCopySection(
                    label: 'Slash Request URL',
                    url:
                        'https://knowledge-api.jarvis.cx/kb-core/v1/hook/slack/slash/6ed67493-c04b-41e9-a7e8-cdd740de1d6c',
                  ),
                  SizedBox(height: 20),
                  Text(
                    '2️⃣ Slack information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  _buildRequiredTextField('Token', _slackTokenController),
                  _buildRequiredTextField('Client ID', _clientIdController),
                  _buildRequiredTextField(
                    'Client Secret',
                    _clientSecretController,
                  ),
                  _buildRequiredTextField(
                    'Signing Secret',
                    _signingSecretController,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Save or submit logic
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildCopySection({required String label, required String url}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(child: SelectableText(url)),
              IconButton(
                icon: Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredTextField(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: '* ',
              style: TextStyle(color: Colors.red),
              children: [
                TextSpan(text: label, style: TextStyle(color: Colors.black)),
              ],
            ),
          ),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Publish')),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Changelog', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                ElevatedButton(onPressed: () {}, child: Text('Generate')),
              ],
            ),
            TextField(
              controller: _changelogController,
              maxLines: 5,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: "Enter this bot version's changelog",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Publish to *',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "By publishing your bot on the following platforms, you fully understand and agree to abide by Terms of service for each publishing channel.",
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            ..._buildPlatformList(),
            SizedBox(height: 80), // Space to avoid being hidden by the button
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed:
              selectedPlatforms.containsValue(true)
                  ? () {
                    if (selectedPlatforms['Slack'] == true) {
                      _showSlackConfigDialog();
                    } else if (selectedPlatforms['Telegram'] == true) {
                      Provider.of<BotProvider>(
                        context,
                        listen: false,
                      ).publishTelegramBot(
                        Provider.of<UserTokenProvider>(
                          context,
                          listen: false,
                        ).user!.accessToken,
                        widget.botId,
                        _telegramTokenController.text,
                      );
                    } else if (selectedPlatforms['Messenger'] == true) {
                      _showMessengerConfigDialog();
                    }
                  }
                  : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            textStyle: TextStyle(fontSize: 16),
          ),
          child: Text('Publish'),
        ),
      ),
    );
  }

  List<Widget> _buildPlatformList() {
    final botConfigurations =
        Provider.of<BotProvider>(context).botConfigurations;

    // Extract verified configurations for quick access
    final Map<String, BotConfiguration> verifiedConfigs = {
      for (var config in botConfigurations) config.type.toLowerCase(): config,
    };

    return selectedPlatforms.keys.map((platform) {
      final platformKey = platform.toLowerCase();
      final config = verifiedConfigs[platformKey];
      final isVerified = config != null;
      final redirectUrl =
          config?.redirect != null ? config!.redirect : "https://www.google.com/";

      return CheckboxListTile(
        title: Row(
          children: [
            Image.asset('assets/$platformKey.png', width: 24, height: 24),
            SizedBox(width: 8),
            Text(platform),
            SizedBox(width: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isVerified ? Colors.green[100] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isVerified ? 'Verified' : 'Not Configured',
                style: TextStyle(
                  color: isVerified ? Colors.green : Colors.black87,
                  fontSize: 12,
                ),
              ),
            ),
            Spacer(),

            // Configure button (disabled if verified)
            TextButton(
              onPressed:
                  isVerified
                      ? null
                      : () {
                        if (platform == 'Telegram') {
                          _showTelegramConfigDialog();
                        } else if (platform == 'Messenger') {
                          _showMessengerConfigDialog();
                        } else if (platform == 'Slack') {
                          _showSlackConfigDialog();
                        }
                      },
              child: Text('Configure'),
            ),

            // Disconnect button (always shown, but disabled if not verified)
            TextButton(
              onPressed: () => _disconnectBot(platformKey),
              child: Text('Disconnect'),
            ),

            // Redirect button (always shown, disabled if not verified or no redirect)
            TextButton(
              onPressed:
                  (isVerified && redirectUrl != null)
                      ? () => launchUrl(Uri.parse(redirectUrl))
                      : null,
              child: Text('Redirect'),
            ),
          ],
        ),
        value: selectedPlatforms[platform],
        onChanged:
            isVerified
                ? (bool? value) {
                  setState(() {
                    selectedPlatforms[platform] = value!;
                  });
                }
                : null,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: isVerified ? Colors.green : Colors.grey,
        checkColor: isVerified ? Colors.white : Colors.black,
      );
    }).toList();
  }
}
