import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:insurance_reporter/components/chat_message_tile.dart';
import 'package:insurance_reporter/models/chat_message.dart';

class LiveChatTab extends StatefulWidget {
  const LiveChatTab({Key? key}) : super(key: key);

  @override
  _LiveChatTabState createState() => _LiveChatTabState();
}

class _LiveChatTabState extends State<LiveChatTab> {
  final _messageController = TextEditingController();
  final _chatMessages = <ChatMessage>[];

  @override
  void initState() {
    super.initState();
    _listenToChatMessages();
  }

  void _listenToChatMessages() {
    final firebaseDB = FirebaseFirestore.instance;
    firebaseDB.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    firebaseDB
        .collection('chat_messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _chatMessages.clear();
        _chatMessages.addAll(
          snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList(),
        );
      });
    });
  }

  void _sendMessage() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final message = _messageController.text;
    if (message.isNotEmpty) {
      FirebaseFirestore.instance.collection('chat_messages').add({
        'userId': userId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isUser': true,
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                reverse: true,
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  return ChatMessageTile(
                    context: context,
                    chatMessage: _chatMessages[index],
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration:
                          const InputDecoration(hintText: 'Type your message'),
                    ),
                  ),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
