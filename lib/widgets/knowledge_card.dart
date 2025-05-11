import 'package:aichat/widgets/knowledge_detail.dart';
import 'package:flutter/material.dart';

class KnowledgeCard extends StatelessWidget {
  final String title;
  final String id;
  final String subtitle;
  final String unitLabel;
  final String sizeLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onChat;

  const KnowledgeCard({
    super.key,
    required this.title,
    required this.id,
    required this.subtitle,
    required this.unitLabel,
    required this.sizeLabel,
    this.onEdit,
    this.onDelete,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false, // Makes background dimmable if desired
            pageBuilder: (context, _, __) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isSmallScreen = screenWidth < 600;

              return Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: isSmallScreen ? 1.0 : 0.6,
                  heightFactor: 1,
                  child: Material(
                    elevation: 8,
                    borderRadius:
                        isSmallScreen
                            ? BorderRadius.zero
                            : const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                    clipBehavior: Clip.antiAlias,
                    child: KnowledgeBaseDetail(
                      id: id,
                      title: title,
                      description: subtitle,
                    ),
                  ),
                ),
              );
            },
            transitionsBuilder: (_, animation, __, child) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              );

              return SlideTransition(position: offsetAnimation, child: child);
            },
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.storage, size: 30, color: Color(0xFF0D1C2E)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title - $id',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildLabel(
                          unitLabel,
                          const Color(0xFFD1FAE5),
                          const Color(0xFF047857),
                        ),
                        const SizedBox(width: 8),
                        _buildLabel(
                          sizeLabel,
                          const Color(0xFFEDE9FE),
                          const Color(0xFF7C3AED),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: onDelete,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: onChat,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
    );
  }
}
