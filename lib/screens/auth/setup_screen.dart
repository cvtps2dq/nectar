import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/chat_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/neu_box.dart';
import '../../widgets/neu_button.dart';
import '../../widgets/neu_text_field.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _ipCtrl = TextEditingController(text: "127.0.0.1");
  final _bioCtrl = TextEditingController();
  String? _avatarPath;

  Future<void> _pickAvatar() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() => _avatarPath = result.files.single.path);
    }
  }

  void _submit() {
    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    context.read<ChatProvider>().setup(
      _userCtrl.text,
      _passCtrl.text,
      _ipCtrl.text,
      _avatarPath ?? "",
      _bioCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: NeuBox(
            width: 450,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "INITIALIZE IDENTITY",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: NeuColors.accent,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 30),

                // Avatar Picker (Round Neumorphic Button)
                GestureDetector(
                  onTap: _pickAvatar,
                  child: NeuBox(
                    width: 100,
                    height: 100,
                    shape: BoxShape.circle,
                    isPressed:
                        _avatarPath ==
                        null, // Pressed in if empty, popped out if filled
                    child: _avatarPath != null
                        ? ClipOval(
                            child: Image.file(
                              File(_avatarPath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: NeuColors.textSecondary,
                            size: 30,
                          ),
                  ),
                ),
                const SizedBox(height: 30),

                NeuTextField(
                  controller: _userCtrl,
                  hintText: "Codename (User)",
                  prefixIcon: const Icon(
                    Icons.person,
                    color: NeuColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                NeuTextField(
                  controller: _bioCtrl,
                  hintText: "Bio / Status",
                  prefixIcon: const Icon(
                    Icons.info_outline,
                    color: NeuColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                NeuTextField(
                  controller: _ipCtrl,
                  hintText: "Hive Address",
                  prefixIcon: const Icon(
                    Icons.dns,
                    color: NeuColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                NeuTextField(
                  controller: _passCtrl,
                  hintText: "New Database Password",
                  obscureText: true,
                  prefixIcon: const Icon(
                    Icons.vpn_key,
                    color: NeuColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 40),
                NeuButton(
                  onPressed: _submit,
                  color: NeuColors.accent,
                  width: double.infinity,
                  child: const Text("GENERATE KEYS"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
