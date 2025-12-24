import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/chat_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/neu_box.dart';
import '../../widgets/neu_button.dart';
import '../../widgets/neu_text_field.dart';
import 'message_bubble.dart';

class ChatArea extends StatefulWidget {
  const ChatArea({super.key});
  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      // Animate to bottom for smooth feel
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Listen to changes in the text field to update the staged file's caption
    _ctrl.addListener(() {
      final chat = context.read<ChatProvider>();
      if (chat.stagedFilepath != null) {
        // This is slightly inefficient as it notifies listeners on every keystroke.
        // A more advanced solution would use a local variable and only update
        // the provider on send, but for V1 this is clear and effective.
        chat.stagedCaption = _ctrl.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // We use context.watch() at the top to rebuild on any change
    final chat = context.watch<ChatProvider>();
    final contact = chat.activeContact;

    // Auto-scroll logic
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Placeholder for when no chat is selected
    if (contact == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 60,
              color: NeuColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              "Select a contact to decrypt channel.",
              style: TextStyle(
                color: NeuColors.textSecondary,
                letterSpacing: 1.5,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Determine if we are in "File Staging" mode
    bool isStagingFile = chat.stagedFilepath != null;

    return Column(
      children: [
        // Header
        NeuBox(
          height: 80,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0), // No bottom margin
          borderRadius: 16,
          isPressed: false, // Popped out
          child: Row(
            children: [
              const SizedBox(width: 20),
              const Icon(Icons.lock, color: NeuColors.green, size: 16),
              const SizedBox(width: 10),
              Text(
                "@${contact.username}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NeuColors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Message List
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: contact.history.length,
            itemBuilder: (ctx, i) => MessageBubble(msg: contact.history[i]),
          ),
        ),

        // Input Area
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), // Adjusted padding
          child: Column(
            children: [
              // 1. Staging Area (Visible only when a file is selected)
              if (isStagingFile)
                NeuBox(
                  isPressed: true, // Sunken effect
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  borderRadius: 12,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.attachment,
                        color: NeuColors.accent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          chat.stagedFilepath!.split('/').last,
                          style: const TextStyle(color: NeuColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: NeuColors.red,
                          size: 20,
                        ),
                        onPressed: () {
                          chat.unstageFile();
                          _ctrl.clear();
                        },
                      ),
                    ],
                  ),
                ),

              // 2. Main Input Row
              Row(
                children: [
                  // File Button (Disabled if already staging)
                  NeuButton(
                    width: 50,
                    height: 50,
                    padding: EdgeInsets.zero,
                    onPressed: isStagingFile
                        ? null
                        : () async {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles();
                            if (result != null) {
                              chat.stageFile(result.files.single.path!);
                            }
                          },
                    child: Icon(
                      Icons.attach_file,
                      color: isStagingFile
                          ? Colors.grey[800]
                          : NeuColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Field
                  Expanded(
                    child: NeuTextField(
                      controller: _ctrl,
                      hintText: isStagingFile
                          ? "Add a caption..."
                          : "Type encrypted message...",
                      onSubmitted: (val) {
                        if (isStagingFile) {
                          chat.sendStagedFile();
                        } else if (val.trim().isNotEmpty) {
                          chat.sendMessage(val);
                        }
                        _ctrl.clear();
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Send Button
                  NeuButton(
                    width: 50,
                    height: 50,
                    padding: EdgeInsets.zero,
                    color: NeuColors.accent,
                    onPressed: () {
                      if (isStagingFile) {
                        chat.sendStagedFile();
                      } else if (_ctrl.text.trim().isNotEmpty) {
                        chat.sendMessage(_ctrl.text);
                      }
                      _ctrl.clear();
                    },
                    child: const Icon(
                      Icons.send,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
