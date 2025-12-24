import 'dart:async'; // <--- Import for Timer
import 'package:flutter/material.dart';
import '../services/daemon_service.dart';

enum AuthState { connecting, locked, setupNeeded, ready }

class Message {
  final String sender;
  final String content;
  final bool isMine;
  final bool isFile;
  final String timestamp;
  final String type;

  Message({
    required this.sender,
    required this.content,
    required this.isMine,
    required this.isFile,
    required this.timestamp,
    required this.type,
  });
}

class Contact {
  final String username;
  final List<Message> history = [];
  int unreadCount = 0;
  Contact(this.username);
}

class ChatProvider extends ChangeNotifier {
  final DaemonService _daemon;
  Timer? _connTimer; // <--- Timer to poll connection

  // Auth State
  AuthState authState = AuthState.connecting;
  String? authError;

  // User Info
  String myUsername = "Unknown";
  String myPubkey = "";
  String myAvatar = "";
  String myBio = "";

  // Data
  final Map<String, Contact> contacts = {};
  List<String> get contactList => contacts.keys.toList()..sort();

  String? activeContactName;

  Contact? get activeContact {
    if (activeContactName != null && contacts.containsKey(activeContactName)) {
      return contacts[activeContactName];
    }
    return null;
  }

  ChatProvider(this._daemon) {
    _daemon.events.listen(_handleEvent);
    // Start polling immediately
    _startConnectionPolling();
  }

  @override
  void dispose() {
    _connTimer?.cancel();
    super.dispose();
  }

  // --- Connection Polling ---
  void _startConnectionPolling() {
    _connTimer?.cancel();

    // Poll more frequently (200ms) during setup/unlock
    _connTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (authState == AuthState.ready && myUsername != "Unknown") {
        timer.cancel();
      } else {
        // Force a status check
        _daemon.sendCommand('get_status', {});
        // Also try to get self, just in case we missed the 'ready' event
        if (authState != AuthState.locked) {
          _daemon.sendCommand('get_self', {});
        }
      }
    });
  }

  // --- Actions ---

  void unlock(String password) {
    authError = null;
    notifyListeners();

    // 1. Send Command
    _daemon.sendCommand('unlock', {'password': password});

    // 2. Start Polling Status
    // If the unlock succeeds, the status will change to 'ready'
    // and _handleEvent will switch the UI.
    _startConnectionPolling();
  }

  void setup(
    String username,
    String password,
    String ip,
    String avatarPath,
    String bio,
  ) {
    authError = null;
    notifyListeners();
    _daemon.sendCommand('setup', {
      'username': username,
      'password': password,
      'server_ip': ip,
      'avatar': avatarPath,
      'bio': bio,
    });

    // Optimistic set
    myAvatar = avatarPath;
    myBio = bio;

    _startConnectionPolling();
  }

  void setActiveContact(String name) {
    activeContactName = name;
    if (contacts.containsKey(name)) {
      contacts[name]!.unreadCount = 0;
    }
    notifyListeners();
  }

  void addContact(String username) {
    // NEW: Send command to daemon to validate & persist
    _daemon.sendCommand('add_contact', {'username': username});
  }

  void sendMessage(String text) {
    if (activeContactName == null) return;
    _daemon.sendCommand('send_text', {
      'target': activeContactName,
      'text': text,
    });

    // Optimistic update
    _addMessage(
      activeContactName!,
      Message(
        sender: "Me",
        content: text,
        isMine: true,
        isFile: false,
        timestamp: DateTime.now().toString(),
        type: 'text',
      ),
    );
  }

  void uploadFile(String path) {
    if (activeContactName == null) return;
    _daemon.sendCommand('upload_file', {
      'target': activeContactName,
      'filepath': path,
    });
  }

  // --- Event Handling ---

  void _handleEvent(Map<String, dynamic> data) {
    final type = data['event'];
    final payload = data['payload'];

    print("[Flutter] Recv Event: $type"); // Debug logging

    if (type == 'status') {
      final status = payload['status'];

      // Stop the polling timer since we got a response
      _connTimer?.cancel();

      if (status == 'locked')
        authState = AuthState.locked;
      else if (status == 'setup_needed')
        authState = AuthState.setupNeeded;
      else if (status == 'ready') {
        if (payload['username'] != null) myUsername = payload['username'];
        authState = AuthState.ready;
        _daemon.sendCommand('get_self', {});
      }
      notifyListeners();
    } else if (type == 'auth_failed') {
      authError = payload['msg'] ?? "Authentication Failed";
      notifyListeners();
    } else if (type == 'contact_added') {
      String username = payload['username'];
      if (!contacts.containsKey(username)) {
        contacts[username] = Contact(username);
        setActiveContact(username);
        notifyListeners();
      }
    } else if (type == 'ready') {
      myUsername = payload['username'];
      myPubkey = payload['pubkey'];
      authState = AuthState.ready;
      _daemon.sendCommand('sync_request', {});
      notifyListeners();
    } else if (type == 'new_message') {
      final sender = payload['sender'];
      final body = payload['body'] ?? "";
      final msgType = payload['type'];

      String content = body;
      if (msgType == 'media') content = "downloads/${payload['filename']}";

      _addMessage(
        sender,
        Message(
          sender: sender,
          content: content,
          isMine: false,
          isFile: msgType == 'media',
          timestamp: payload['timestamp'].toString(),
          type: msgType ?? 'text',
        ),
      );
    } else if (type == 'sync_response') {
      if (payload['contacts'] != null) {
        contacts.clear();
        for (var c in payload['contacts']) {
          String name = c['username'];
          var contact = Contact(name);

          if (c['history'] != null) {
            for (var m in c['history']) {
              contact.history.add(
                Message(
                  sender: m['sender'],
                  content: m['content'],
                  isMine: m['is_mine'],
                  isFile: m['type'] == 'media',
                  timestamp: m['timestamp'].toString(),
                  type: m['type'] ?? 'text',
                ),
              );
            }
          }
          contacts[name] = contact;
        }
        notifyListeners();
      }
    }
  }

  void _addMessage(String contactName, Message msg) {
    if (!contacts.containsKey(contactName)) {
      contacts[contactName] = Contact(contactName);
    }
    contacts[contactName]!.history.add(msg);
    if (activeContactName != contactName && !msg.isMine) {
      contacts[contactName]!.unreadCount++;
    }
    notifyListeners();
  }
}
