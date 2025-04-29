import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String sentUserId;
  final String receivedUserId;
  final String message;
  final DateTime timestamp;

  Message({
    required this.sentUserId,
    required this.receivedUserId,
    required this.message,
    required this.timestamp,
  });

  factory Message.fromFirestore(Map<String, dynamic> doc) {
    return Message(
      sentUserId: doc['sentUserId'],
      receivedUserId: doc['receivedUserId'],
      message: doc['message'],
      timestamp: (doc['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sentUserId': sentUserId,
      'receivedUserId': receivedUserId,
      'message': message,
      'timestamp': timestamp,
    };
  }
}