import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'services/daemon_service.dart';
import 'providers/chat_provider.dart';

void main() {
  final daemon = DaemonService();
  daemon.connect();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ChatProvider(daemon))],
      child: const NectarApp(),
    ),
  );
}

class NectarApp extends StatelessWidget {
  const NectarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nectar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.amber,
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
          surface: Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: const AuthSwitcher(),
    );
  }
}

// --- Auth Switcher ---
// This widget listens to the AuthState and swaps the entire screen accordingly.
class AuthSwitcher extends StatelessWidget {
  const AuthSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    // Select only the authState to prevent unnecessary rebuilds of the whole tree
    final authState = context.select((ChatProvider p) => p.authState);

    switch (authState) {
      case AuthState.connecting:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.amber),
                SizedBox(height: 16),
                Text(
                  "Connecting to Daemon...",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      case AuthState.locked:
        return const LoginScreen();
      case AuthState.setupNeeded:
        return const SetupScreen();
      case AuthState.ready:
        return const HomeScreen();
    }
  }
}

// --- Login Screen ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return Scaffold(
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Nectar Secure",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your database password",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              if (chat.authError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    chat.authError!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),

              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                onSubmitted: (_) => chat.unlock(_passCtrl.text),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => chat.unlock(_passCtrl.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Unlock",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Setup Screen (Registration) ---
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _serverCtrl = TextEditingController(text: "127.0.0.1");
  final _bioCtrl = TextEditingController();
  String? _avatarPath;

  Future<void> _pickAvatar() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        _avatarPath = result.files.single.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Join Nectar",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Avatar
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: _avatarPath != null
                              ? FileImage(File(_avatarPath!))
                              : null,
                          child: _avatarPath == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white24,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: _userCtrl,
                  decoration: _inputDeco("Nickname", Icons.alternate_email),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bioCtrl,
                  decoration: _inputDeco("Bio (Optional)", Icons.info_outline),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _serverCtrl,
                  decoration: _inputDeco("Server IP", Icons.dns),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: _inputDeco("New Password", Icons.lock_outline),
                ),

                const SizedBox(height: 32),
                if (chat.authError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      chat.authError!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                ElevatedButton(
                  onPressed: () {
                    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty)
                      return;
                    chat.setup(
                      _userCtrl.text,
                      _passCtrl.text,
                      _serverCtrl.text,
                      _avatarPath ?? "",
                      _bioCtrl.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Create Account",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

// --- Main Chat UI ---

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SizedBox(width: 280, child: ContactList()),
          const VerticalDivider(width: 1, color: Colors.white12),
          const Expanded(child: ChatArea()),
        ],
      ),
    );
  }
}

class ContactList extends StatelessWidget {
  const ContactList({super.key});

  void _showAddContactDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Contact"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: "Username (e.g. bob)",
            prefixText: "@",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                context.read<ChatProvider>().addContact(ctrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Add"),
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
        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          color: const Color(0xFF252525),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Nectar",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              IconButton(
                icon: const Icon(Icons.person_add, color: Colors.amber),
                onPressed: () => _showAddContactDialog(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: chat.contactList.length,
            itemBuilder: (ctx, i) {
              final name = chat.contactList[i];
              final contact = chat.contacts[name]!;
              final isActive = name == chat.activeContactName;

              return ListTile(
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                selected: isActive,
                selectedTileColor: Colors.amber.withOpacity(0.15),
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                trailing: contact.unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "${contact.unreadCount}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
                onTap: () => chat.setActiveContact(name),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1A1A1A),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green[800],
                radius: 16,
                child: const Icon(Icons.check, size: 16),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "@${chat.myUsername}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Online",
                    style: TextStyle(color: Colors.green, fontSize: 11),
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
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final contact = chat.activeContact;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    if (contact == null) {
      return Container(
        color: const Color(0xFF121212),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white24),
              SizedBox(height: 16),
              Text(
                "Select a contact to start encryption",
                style: TextStyle(color: Colors.white38),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.centerLeft,
          color: const Color(0xFF1F1F1F),
          child: Text(
            "@${contact.username}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(20),
            itemCount: contact.history.length,
            itemBuilder: (ctx, i) => MessageBubble(msg: contact.history[i]),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1F1F1F),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.grey),
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles();
                  if (result != null)
                    chat.uploadFile(result.files.single.path!);
                },
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      chat.sendMessage(val);
                      _ctrl.clear();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    filled: true,
                    fillColor: const Color(0xFF2C2C2C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.amber,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.black),
                  onPressed: () {
                    if (_ctrl.text.trim().isNotEmpty) {
                      chat.sendMessage(_ctrl.text);
                      _ctrl.clear();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message msg;
  const MessageBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isMine;

    Widget content;
    if (msg.type == 'media') {
      bool isImage =
          msg.content.endsWith('.jpg') || msg.content.endsWith('.png');
      content = isImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(msg.content),
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 100,
                  width: 100,
                  color: Colors.grey,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file,
                  color: isMe ? Colors.black54 : Colors.white70,
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(msg.content.split('/').last)),
              ],
            );
    } else {
      content = Text(
        msg.content,
        style: TextStyle(
          fontSize: 15,
          color: isMe ? Colors.black : Colors.white,
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isMe ? Colors.amber : const Color(0xFF333333),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe
                ? const Radius.circular(16)
                : const Radius.circular(0),
            bottomRight: isMe
                ? const Radius.circular(0)
                : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                msg.sender,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
            ],
            content,
          ],
        ),
      ),
    );
  }
}
