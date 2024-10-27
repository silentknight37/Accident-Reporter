import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:insurance_reporter/models/chat_message.dart';

class ChatMessageTile extends StatelessWidget {
  final ChatMessage chatMessage;
  final BuildContext context;

  const ChatMessageTile({
    super.key,
    required this.context,
    required this.chatMessage,
  });

  String formatTimeAndDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }
    final date = timestamp.toDate();
    final time = TimeOfDay.fromDateTime(date).format(context);
    final day = date.day;
    final month = date.month;
    final year = date.year;
    return '$time, $day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(chatMessage.message ?? ''),
      subtitle: Text(formatTimeAndDate(chatMessage.timestamp)),
      trailing: chatMessage.isUser!
          ? const Icon(Icons.person_rounded)
          : const Icon(Icons.support_agent_rounded),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tileColor: chatMessage.isUser! ? Colors.blue[100] : Colors.grey[200],
    );
  }
}
