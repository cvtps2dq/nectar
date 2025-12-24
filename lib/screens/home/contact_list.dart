import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/neu_box.dart';
import '../../widgets/neu_button.dart';
import '../../widgets/neu_avatar.dart';
import '../../widgets/neu_text_field.dart'; // For the Add Dialog

class ContactList extends StatelessWidget {
  const ContactList({super.key});

  void _showAddDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeuColors.background,
        title: const Text("Add Contact", style: TextStyle(color: NeuColors.textPrimary)),
        content: NeuTextField(
          controller: ctrl, 
          hintText: "Username (e.g. bob)", 
          prefixIcon: const Icon(Icons.alternate_email, color: NeuColors.textSecondary)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancel", style: TextStyle(color: NeuColors.textSecondary))
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                context.read<ChatProvider>().addContact(ctrl.text);
                Navigator.pop(ctx);
              }
            }, 
            child: const Text("Add", style: TextStyle(color: NeuColors.accent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("NECTAR", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2, color: NeuColors.accent)),
              NeuButton(
                width: 45, height: 45,
                padding: EdgeInsets.zero, // <-- ADD THIS
                onPressed: () => _showAddDialog(context),
                child: const Icon(Icons.add, color: NeuColors.textPrimary, size: 20),
              )
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chat.contactList.length,
            itemBuilder: (ctx, i) {
              final name = chat.contactList[i];
              final contact = chat.contacts[name]!;
              final isActive = name == chat.activeContactName;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => chat.setActiveContact(name),
                  child: NeuBox(
                    height: 80,
                    isPressed: isActive, // Sunk if active
                    color: isActive ? NeuColors.background : NeuColors.surface,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        NeuAvatar(fallbackName: name, size: 45),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name, 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 15,
                                  color: isActive ? NeuColors.accent : NeuColors.textPrimary
                                )
                              ),
                              if (contact.history.isNotEmpty)
                                Text(
                                  contact.history.last.content, 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: NeuColors.textSecondary)
                                ),
                            ],
                          ),
                        ),
                        if (contact.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 16),
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: NeuColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${contact.unreadCount}", 
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // User Profile Footer
        Padding(
          padding: const EdgeInsets.all(20),
          child: NeuBox(
            height: 80,
            isPressed: true, // "Inset" look for the footer
            child: Row(
              children: [
                const SizedBox(width: 16),
                NeuAvatar(
                  fallbackName: chat.myUsername, 
                  imagePath: chat.myAvatar, // Uses local path from DB
                  isOnline: true,
                  size: 45
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("@${chat.myUsername}", style: const TextStyle(fontWeight: FontWeight.bold, color: NeuColors.textPrimary)),
                    const Text("Online", style: TextStyle(fontSize: 11, color: NeuColors.green)),
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}