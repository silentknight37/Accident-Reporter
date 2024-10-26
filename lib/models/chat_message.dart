import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  String? userId;
  String? message;
  Timestamp? timestamp;
  bool? isUser;

  ChatMessage({this.userId, this.message, this.timestamp, this.isUser});

  factory ChatMessage.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ChatMessage(
      userId: data['userId'],
      message: data['message'],
      timestamp: data['timestamp'],
      isUser: data['isUser'],
    );
  }
}
