import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/daemon_service.dart';
import 'dart:convert';     // <--- ADD THIS for base64Decode
import 'dart:typed_data'; // <--- ADD THIS for Uint8List

enum AuthState { connecting, locked, setupNeeded, ready }
enum MessageStatus { sending, sent, failed, received }

class Message {
  final String uuid;      // Global ID
  final String? replyTo;  // UUID of parent message
  final String localId;   // Temporary tracking ID (optional now, but good for ACKs)
  
  final String sender;
  final String content;
  final bool isMine;
  final bool isFile;
  final String timestamp;
  final String type;      // 'text', 'media', 'voice'
  
  MessageStatus status;   // Mutable to allow updates (Sending -> Sent)

  Message({
    required this.uuid,
    this.replyTo,
    required this.localId,
    required this.sender,
    required this.content,
    required this.isMine,
    required this.isFile,
    required this.timestamp,
    required this.type,
    required this.status,
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
  final Uuid _uuidGen = const Uuid();
  Timer? _connTimer;

  // Auth State
  AuthState authState = AuthState.connecting;
  String? authError;
  String? globalError; // For Snackbars

  // User Info
  String myUsername = "Unknown";
  String myPubkey = "";
  String myAvatar = "";
  String myBio = "";

  // Data
  final Map<String, Contact> contacts = {};
  List<String> get contactList => contacts.keys.toList()..sort();

  String? activeContactName;
  bool _hasSynced = false;

  Contact? get activeContact {
    if (activeContactName != null && contacts.containsKey(activeContactName)) {
      return contacts[activeContactName];
    }
    return null;
  }

  ChatProvider(this._daemon) {
    _daemon.events.listen(_handleEvent);
    _startConnectionPolling();
  }

  @override
  void dispose() {
    _connTimer?.cancel();
    super.dispose();
  }

  void clearError() {
    globalError = null;
    notifyListeners();
  }

  // --- ROBUST Connection Polling ---
  void _startConnectionPolling() {
    _connTimer?.cancel();
    _connTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (authState != AuthState.ready) {
        _daemon.sendCommand('get_status', {});
        
        // Race condition check: If daemon is ready but we missed the packet
        if (authState != AuthState.connecting) {
           _daemon.sendCommand('get_self', {});
        }
      } else {
        // Logged in. Do we have data?
        if (!_hasSynced) {
          print("[Flutter] Requesting Sync...");
          _daemon.sendCommand('sync_request', {});
        } else {
          // Heartbeat or stop
          timer.cancel(); 
        }
      }
    });
  }

  // --- Actions ---

  void unlock(String password) {
    authError = null;
    notifyListeners();
    _daemon.sendCommand('unlock', {'password': password});
  }

  void setup(String username, String password, String ip, String avatarPath, String bio) {
    authError = null;
    notifyListeners();
    _daemon.sendCommand('setup', {
      'username': username,
      'password': password,
      'server_ip': ip,
      'avatar': avatarPath,
      'bio': bio,
    });
    myAvatar = avatarPath;
    myBio = bio;
  }

  void setActiveContact(String name) {
    activeContactName = name;
    if (contacts.containsKey(name)) {
      contacts[name]!.unreadCount = 0;
    }
    notifyListeners();
  }

  void addContact(String username) {
    _daemon.sendCommand('add_contact', {'username': username});
  }

  void sendMessage(String text, {String? replyToUuid}) {
    if (activeContactName == null) return;
    
    // Generate IDs
    String uuid = _uuidGen.v4();
    String localId = "${DateTime.now().millisecondsSinceEpoch}-$uuid";

    // Network
    _daemon.sendCommand('send_text', {
      'target': activeContactName,
      'text': text,
      'uuid': uuid,
      'reply_to': replyToUuid ?? "",
      'local_id': localId
    });

    // Optimistic UI
    _addMessage(
      activeContactName!,
      Message(
        uuid: uuid,
        replyTo: replyToUuid,
        localId: localId,
        sender: "Me",
        content: text,
        isMine: true,
        isFile: false,
        timestamp: DateTime.now().toString(),
        type: 'text',
        status: MessageStatus.sending, // Gray clock
      ),
    );
  }

  void editMessage(String uuid, String newText) {
    if (activeContactName == null) return;

    _daemon.sendCommand('edit_msg', {
      'target': activeContactName,
      'uuid': uuid,
      'text': newText
    });

    // Optimistic Update
    _processEdit(activeContactName!, uuid, newText);
  }

  void deleteMessage(String uuid) {
    if (activeContactName == null) return;

    _daemon.sendCommand('delete_msg', {
      'target': activeContactName,
      'uuid': uuid
    });

    // Optimistic Delete
    _processDelete(activeContactName!, uuid);
  }

  void uploadFile(String path) {
    if (activeContactName == null) return;
    // Note: File uploads handle their own messages via the Daemon for now
    _daemon.sendCommand('upload_file', {
      'target': activeContactName,
      'filepath': path,
    });
  }

  // --- Event Handling ---

  void _handleEvent(Map<String, dynamic> data) {
    final type = data['event'];
    final payload = data['payload'];

    // print("[Flutter] Event: $type"); // Uncomment for debugging

    if (type == 'status') {
      final status = payload['status'];
      AuthState newState = authState;
      
      if (status == 'locked') newState = AuthState.locked;
      else if (status == 'setup_needed') newState = AuthState.setupNeeded;
      else if (status == 'ready') {
        if (payload['username'] != null) myUsername = payload['username'];
        newState = AuthState.ready;
      }
      
      if (newState != authState) {
        authState = newState;
        notifyListeners();
      }
    } 
    else if (type == 'auth_failed' || type == 'error') {
      // General error handling
      if (type == 'auth_failed') authError = payload['msg'];
      else globalError = payload['msg'];
      notifyListeners();
    } 
    else if (type == 'contact_added') {
      String username = payload['username'];
      if (!contacts.containsKey(username)) {
        contacts[username] = Contact(username);
        setActiveContact(username);
        notifyListeners();
      }
    } 
    else if (type == 'ready') {
      myUsername = payload['username'];
      myPubkey = payload['pubkey'];
      authState = AuthState.ready;
      notifyListeners();
    } 
    else if (type == 'message_ack') {
      // payload: { local_id: "...", status: "sent" }
      String id = payload['local_id'];
      String statusStr = payload['status'];
      
      // Update status
      for (var c in contacts.values) {
        for (var m in c.history) {
          if (m.isMine && m.localId == id) {
            m.status = (statusStr == "sent") ? MessageStatus.sent : MessageStatus.failed;
            notifyListeners();
            return;
          }
        }
      }
    }
    else if (type == 'new_message') {
      final sender = payload['sender'];
      final eventType = payload['type']; // text, media, edit, delete

      if (eventType == 'edit') {
        // Edit existing message
        String relatedUuid = payload['related_uuid']; // ID of message to edit
        String newBody = payload['body'];
        _processEdit(sender, relatedUuid, newBody);
      } 
      else if (eventType == 'delete') {
        // Delete message
        String relatedUuid = payload['related_uuid'];
        _processDelete(sender, relatedUuid);
      } else if (type == 'file_data') {
      // payload: { path: "...", data_b64: "..." }
      String path = payload['path'];
      String b64 = payload['data_b64'];
      
      // Decode and cache
      _mediaCache[path] = base64Decode(b64);
      notifyListeners();
    }
      else {
        // Normal New Message
        final body = payload['body'] ?? "";
        String content = body;
        if (eventType == 'media') content = "downloads/${payload['filename']}";

        _addMessage(
          sender,
          Message(
            uuid: payload['uuid'] ?? "", 
            replyTo: payload['reply_to'],
            localId: "", // Not needed for incoming
            sender: sender,
            content: content,
            isMine: false,
            isFile: eventType == 'media',
            timestamp: payload['timestamp'].toString(),
            type: eventType ?? 'text',
            status: MessageStatus.received
          ),
        );
      }
    } 
    else if (type == 'sync_response') {
      _hasSynced = true;
      if (payload['contacts'] != null) {
        contacts.clear();
        for (var c in payload['contacts']) {
          String name = c['username'];
          var contact = Contact(name);

          if (c['history'] != null) {
            for (var m in c['history']) {
              bool isMine = m['is_mine'];
              contact.history.add(
                Message(
                  uuid: m['uuid'] ?? "", // Ensure Daemon exports this
                  replyTo: m['reply_to'],
                  localId: "synced",
                  sender: m['sender'],
                  content: m['content'],
                  isMine: isMine,
                  isFile: m['type'] == 'media',
                  timestamp: m['timestamp'].toString(),
                  type: m['type'] ?? 'text',
                  status: isMine ? MessageStatus.sent : MessageStatus.received,
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

  // --- Internal Logic ---

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

  void _processEdit(String contactName, String targetUuid, String newText) {
    if (contacts.containsKey(contactName)) {
      var history = contacts[contactName]!.history;
      int idx = history.indexWhere((m) => m.uuid == targetUuid);
      if (idx != -1) {
        var old = history[idx];
        history[idx] = Message(
          uuid: old.uuid, replyTo: old.replyTo, localId: old.localId,
          sender: old.sender, isMine: old.isMine, isFile: old.isFile,
          timestamp: old.timestamp, type: old.type, status: old.status,
          content: newText // Updated
        );
        notifyListeners();
      }
    }
  }

  void _processDelete(String contactName, String targetUuid) {
    if (contacts.containsKey(contactName)) {
      contacts[contactName]!.history.removeWhere((m) => m.uuid == targetUuid);
      notifyListeners();
    }
  }

  String? stagedFilepath;
  String stagedCaption = "";

  void stageFile(String path) {
    stagedFilepath = path;
    notifyListeners();
  }

  void unstageFile() {
    stagedFilepath = null;
    stagedCaption = "";
    notifyListeners();
  }

  void sendStagedFile() {
    if (activeContactName == null || stagedFilepath == null) return;
    
    // Pass caption to daemon
    // NOTE: We need to update IPC `upload_file` to accept a caption!
    _daemon.sendCommand('upload_file', {
      'target': activeContactName,
      'filepath': stagedFilepath,
      'caption': stagedCaption
    });

    // Optimistic UI Update (Show file as sending)
    _addMessage(
      activeContactName!, 
      Message(
        uuid: const Uuid().v4(), 
        localId: "${DateTime.now().millisecondsSinceEpoch}",
        sender: "Me", 
        // Use filename as content
        content: stagedFilepath!.split('/').last, 
        isMine: true, 
        isFile: true, 
        timestamp: DateTime.now().toString(), 
        type: 'media', 
        status: MessageStatus.sending
      )
    );

    unstageFile(); // Clear input
  }

  final Map<String, Uint8List> _mediaCache = {};
  Uint8List? getMedia(String path) => _mediaCache[path];

  void requestMedia(String path) {
    _daemon.sendCommand('get_file', {'path': path});
  }
}