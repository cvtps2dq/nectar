import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
      // Context Menu (Delete)
      onLongPressStart: (details) {
        if (!isMe) return; // Only show menu for my messages

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          items: [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(Icons.delete_outline, color: NeuColors.red),
                  SizedBox(width: 12),
                  Text(
                    "Delete Message",
                    style: TextStyle(color: NeuColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ).then((value) {
          if (value == 'delete') {
            chat.deleteMessage(msg.uuid);
          }
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
            // Status Icon (For my messages)
            if (isMe) ...[
              _buildStatusIcon(msg.status),
              const SizedBox(width: 8),
            ],

            // The Main Bubble
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: NeuBox(
                color: NeuColors.surface,
                borderRadius: 16,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender Name (For incoming messages)
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

                    // Content (Text/Image/File)
                    _buildContent(context, msg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Message msg) {
    final chat = context.read<ChatProvider>();
    final isMe = msg.isMine;

    if (msg.type == 'media') {
      final String filename = msg.content; // Content is now just the filename
      final String localPath = "downloads/$filename";

      bool isImage =
          filename.toLowerCase().endsWith('.jpg') ||
          filename.toLowerCase().endsWith('.png') ||
          filename.toLowerCase().endsWith('.jpeg') ||
          filename.toLowerCase().endsWith('.gif');

      if (isImage) {
        final imageData = chat.getMedia(localPath);

        if (imageData != null) {
          // A. Image is loaded, display it.
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(imageData, height: 200, fit: BoxFit.cover),
          );
        } else {
          // B. Image is being downloaded, show a spinner.
          return Container(
            height: 120,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: NeuColors.accent,
                strokeWidth: 2,
              ),
            ),
          );
        }
      } else {
        // C. It's a generic file.
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, color: NeuColors.accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                filename,
                style: const TextStyle(color: NeuColors.textPrimary),
              ),
            ),
          ],
        );
      }
    }

    // It's plain text
    return Text(
      msg.content,
      style: TextStyle(
        color: isMe ? NeuColors.textPrimary : NeuColors.textPrimary,
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
        icon = Icons.check_circle_outline;
        color = NeuColors.green;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = NeuColors.red;
        break;
      default:
        return const SizedBox.shrink();
    }
    return Icon(icon, size: 14, color: color);
  }
}
