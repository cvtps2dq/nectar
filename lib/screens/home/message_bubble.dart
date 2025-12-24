import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/neu_box.dart';

class MessageBubble extends StatelessWidget {
  final Message msg;
  const MessageBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isMine;
    final chat = context.read<ChatProvider>();

    return GestureDetector(
      onLongPressStart: (details) {
        final offset = details.globalPosition;
        showMenu(
          context: context,
          color: NeuColors.surface,
          position: RelativeRect.fromLTRB(
            offset.dx,
            offset.dy,
            offset.dx,
            offset.dy,
          ),
          items: [
            if (isMe)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: const [
                    Icon(Icons.delete, color: NeuColors.red),
                    SizedBox(width: 8),
                    Text(
                      "Delete",
                      style: TextStyle(color: NeuColors.textPrimary),
                    ),
                  ],
                ),
              ),
          ],
        ).then((v) {
          if (v == 'delete') chat.deleteMessage(msg.uuid);
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Status Icon (Left side if mine, or hide)
            if (isMe) ...[
              _buildStatusIcon(msg.status),
              const SizedBox(width: 8),
            ],

            // The Bubble
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: NeuBox(
                // Me: Accent Color, Them: Surface Color
                color: isMe ? NeuColors.surface : NeuColors.surface,

                // Make "My" messages look slightly distinct via border or just alignment
                // Actually, let's use Accent for "Me" but keep the neomorphism subtle
                // Using a gradient or just text color is cleaner in dark mode.
                // Let's stick to Surface for both but use Text Color to distinguish.
                borderRadius: 16,
                // Different corners
                shape: BoxShape.rectangle,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          msg.sender,
                          style: const TextStyle(
                            color: NeuColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    _buildContent(msg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Message msg) {
    if (msg.type == 'media') {
      bool isImage =
          msg.content.endsWith('.jpg') || msg.content.endsWith('.png');
      if (isImage) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(msg.content),
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.broken_image, color: NeuColors.red),
          ),
        );
      } else {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, color: NeuColors.accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                msg.content.split('/').last,
                style: const TextStyle(color: NeuColors.textPrimary),
              ),
            ),
          ],
        );
      }
    }
    return Text(
      msg.content,
      style: TextStyle(
        color: msg.isMine ? NeuColors.accent : NeuColors.textPrimary,
        fontSize: 15,
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    IconData icon;
    Color color;
    switch (status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = NeuColors.textSecondary;
        break;
      case MessageStatus.sent:
        icon = Icons.check_circle;
        color = NeuColors.green;
        break;
      case MessageStatus.failed:
        icon = Icons.error;
        color = NeuColors.red;
        break;
      default:
        return const SizedBox.shrink();
    }
    return Icon(icon, size: 14, color: color);
  }
}
