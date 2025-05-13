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
              child: Text('OK'),
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
                      ).user!.accessToken;

                  bool isVerified = await botProvider.verifyTelegramBot(
                    userToken,
                    token,
                  );

                  if (isVerified) {
                    if (mounted) {
                      setState(() {
                        isTelegramVerified = true;
                      });
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Telegram Bot verified successfully!'),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to verify Telegram Bot.'),
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showMessengerConfigDialog() {
    final callbackUrl =
        'https://knowledge-api.dev.jarvis.cx/kb-core/v1/hook/messenger/${widget.botId}';
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
              child: Text('OK'),
              onPressed: () async {
                final token = _messengerTokenController.text.trim();
                final pageId = _messengerPageIdController.text.trim();
                final appSecret = _messengerAppSecretController.text.trim();

                if (token.isNotEmpty &&
                    pageId.isNotEmpty &&
                    appSecret.isNotEmpty) {
                  final accessToken =
                      Provider.of<UserTokenProvider>(
                        context,
                        listen: false,
                      ).user!.accessToken;

                  final success = await Provider.of<BotProvider>(
                    context,
                    listen: false,
                  ).verifyMessengerBot(accessToken, token, pageId, appSecret);

                  if (success) {
                    // refetch the bot configurations
                    if (mounted) {
                      setState(() {
                        isMessengerVerified = true;
                      });
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Messenger Bot verified successfully!'),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Verification failed')),
                      );
                    }
                  }
                }
              },
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
                        'https://knowledge-api.dev.jarvis.cx/kb-core/v1/bot-integration/slack/auth/6ed67493-c04b-41e9-a7e8-cdd740de1d6c',
                  ),
                  _buildCopySection(
                    label: 'Event Request URL',
                    url:
                        'https://knowledge-api.dev.jarvis.cx/kb-core/v1/hook/slack/6ed67493-c04b-41e9-a7e8-cdd740de1d6c',
                  ),
                  _buildCopySection(
                    label: 'Slash Request URL',
                    url:
                        'https://knowledge-api.dev.jarvis.cx/kb-core/v1/hook/slack/slash/6ed67493-c04b-41e9-a7e8-cdd740de1d6c',
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
                onPressed: () async {
                  final token = _slackTokenController.text.trim();
                  final clientId = _clientIdController.text.trim();
                  final clientSecret = _clientSecretController.text.trim();
                  final signingSecret = _signingSecretController.text.trim();

                  if (token.isEmpty ||
                      clientId.isEmpty ||
                      clientSecret.isEmpty ||
                      signingSecret.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }

                  final accessToken =
                      Provider.of<UserTokenProvider>(
                        context,
                        listen: false,
                      ).user!.accessToken;

                  final success = await Provider.of<BotProvider>(
                    context,
                    listen: false,
                  ).verifySlackBot(
                    accessToken,
                    token,
                    clientId,
                    clientSecret,
                    signingSecret,
                  );

                  if (!mounted) return;

                  if (success) {
                    if (mounted) {
                      setState(() {
                        isSlackVerified = true;
                      });
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Slack Bot verified successfully!'),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Verification failed')),
                    );
                  }
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
      appBar: AppBar(title: Text('Publish'), backgroundColor: Colors.white),

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
                  ? () async {
                    final token =
                        Provider.of<UserTokenProvider>(
                          context,
                          listen: false,
                        ).user!.accessToken;

                    final botProvider = Provider.of<BotProvider>(
                      context,
                      listen: false,
                    );

                    try {
                      if (selectedPlatforms['Slack'] == true) {
                        await botProvider.publishSlackBot(
                          token,
                          widget.botId,
                          _slackTokenController.text,
                          _clientIdController.text,
                          _clientSecretController.text,
                          _signingSecretController.text,
                        );
                      } else if (selectedPlatforms['Telegram'] == true) {
                        await botProvider.publishTelegramBot(
                          token,
                          widget.botId,
                          _telegramTokenController.text,
                        );
                      } else if (selectedPlatforms['Messenger'] == true) {
                        await botProvider.publishMessengerBot(
                          token,
                          widget.botId,
                          _messengerTokenController.text,
                          _messengerPageIdController.text,
                          _messengerAppSecretController.text,
                        );
                      }
                      await botProvider.getBotConfiguration(
                        token,
                        widget.botId,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Publish bot success!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to publish bot: $e')),
                      );
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

    // Check if the platform config already exists in backend
    final isTelegramExist = botConfigurations.any(
      (config) => config.type.toLowerCase() == 'telegram',
    );
    final isMessengerExist = botConfigurations.any(
      (config) => config.type.toLowerCase() == 'messenger',
    );
    final isSlackExist = botConfigurations.any(
      (config) => config.type.toLowerCase() == 'slack',
    );

    // Determine if each is verified: either it exists OR was verified in-session
    final isTelegramVerifiedFinal = isTelegramExist || isTelegramVerified;
    final isMessengerVerifiedFinal = isMessengerExist || isMessengerVerified;
    final isSlackVerifiedFinal = isSlackExist || isSlackVerified;

    // Create a lookup map for redirect URLs
    final Map<String, String> redirectUrls = {
      for (var config in botConfigurations)
        config.type.toLowerCase(): config.redirect ?? "https://www.google.com/",
    };

    return selectedPlatforms.keys.map((platform) {
      final platformKey = platform.toLowerCase();

      // Map platform to the final verified state
      bool isVerified;
      switch (platform) {
        case 'Telegram':
          isVerified = isTelegramVerifiedFinal;
          break;
        case 'Messenger':
          isVerified = isMessengerVerifiedFinal;
          break;
        case 'Slack':
          isVerified = isSlackVerifiedFinal;
          break;
        default:
          isVerified = false;
      }

      final redirectUrl =
          redirectUrls[platformKey] ?? "https://www.google.com/";

      return CheckboxListTile(
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
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
              SizedBox(width: 8),
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
              TextButton(
                onPressed: () => _disconnectBot(platformKey),
                child: Text('Disconnect'),
              ),
              TextButton(
                onPressed:
                    isVerified ? () => launchUrl(Uri.parse(redirectUrl)) : null,
                child: Text('Redirect'),
              ),
            ],
          ),
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
