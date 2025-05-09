import 'package:aichat/widgets/import_confluence_source.dart';
import 'package:aichat/widgets/import_slack_source_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:aichat/widgets/import_web_source_dialog.dart';
import 'package:aichat/widgets/import_local_file_dialog.dart';

class KnowledgeSourceDialog extends StatefulWidget {
  const KnowledgeSourceDialog({
    super.key,
    this.onWebsiteSave,
    this.onLocalFileImport,
    this.onSlackSave,
    this.onConfluenceSave,
  });

  final Function(String, String)? onWebsiteSave;
  final Function(List<PlatformFile>)? onLocalFileImport;
  final Function(String, String)? onSlackSave;
  final Function(String, String, String, String)? onConfluenceSave;

  @override
  State<KnowledgeSourceDialog> createState() => _KnowledgeSourceDialogState();
}

class _KnowledgeSourceDialogState extends State<KnowledgeSourceDialog> {
  @override
  Widget build(BuildContext context) {
    final greyColor = Colors.grey.shade400;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Knowledge Source',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // List of sources
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildActiveTile(
                    icon: Icons.insert_drive_file,
                    title: 'Local files',
                    subtitle: 'Upload pdf, docx, ...',
                    onTap: () async {
                      Navigator.of(
                        context,
                      ).pop(); // Close the source selection dialog first

                      final selectedFiles =
                          await showDialog<List<PlatformFile>>(
                            context: context,
                            builder: (_) => const LocalFileImportDialog(),
                          );

                      if (selectedFiles != null && selectedFiles.isNotEmpty) {
                        widget.onLocalFileImport?.call(selectedFiles);
                      }
                    },
                  ),

                  _buildActiveTile(
                    icon: Icons.language,
                    title: 'Website',
                    subtitle: 'Connect Website to get data',
                    onTap: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder:
                            (context) => WebsiteImportDialog(
                              onSubmit: (name, url) {
                                widget.onWebsiteSave?.call(name, url);
                                Navigator.of(context).pop();
                              },
                            ),
                      );
                    },
                  ),
                  _buildActiveTile(
                    icon: Icons.chat,
                    title: 'Slack',
                    subtitle: "Connect to Slack Workspace",
                    onTap: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder:
                            (context) => SlackImportDialog(
                              onSubmit: (name, slackToken) {
                                widget.onSlackSave?.call(name, slackToken);
                                Navigator.of(context).pop();
                              },
                            ),
                      );
                    },
                  ),
                  _buildActiveTile(
                    icon: Icons.workspaces_outlined,
                    title: 'Confluence',
                    subtitle: "Connect to Confluence",
                    onTap: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder:
                            (context) => ConfluenceImportDialog(
                              onSubmit: (
                                name,
                                wikiPageUrl,
                                username,
                                apiToken,
                              ) {
                                widget.onConfluenceSave?.call(
                                  name,
                                  wikiPageUrl,
                                  username,
                                  apiToken,
                                );
                                Navigator.of(context).pop();
                              },
                            ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildComingSoonTile(
                    icon: Icons.cloud,
                    title: 'Google Drive',
                  ),
                  _buildComingSoonTile(
                    icon: Icons.code,
                    title: 'Github Repository',
                  ),
                  _buildComingSoonTile(
                    icon: Icons.code_off,
                    title: 'Gitlab Repository',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildComingSoonTile({required IconData icon, required String title}) {
    final greyColor = Colors.grey.shade400;

    return ListTile(
      leading: Icon(icon, color: greyColor),
      title: Text(title, style: TextStyle(color: greyColor)),
      subtitle: const Text('Coming soon', style: TextStyle(color: Colors.grey)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: greyColor),
      enabled: false,
    );
  }
}
