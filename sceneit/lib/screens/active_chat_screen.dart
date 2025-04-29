import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sceneit/data/Message.dart';
import '../constants/colors.dart';
import '../widgets/navbar.dart';

class ActiveChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserPhoto;
  final String otherUsername;

  const ActiveChatScreen({
    required this.chatId,
    required this.otherUserId,
    required this.otherUsername,
    required this.otherUserPhoto,
    super.key,
  });

  @override
  _ActiveChatScreenState createState() => _ActiveChatScreenState();
}

class _ActiveChatScreenState extends State<ActiveChatScreen> {
  final _activeUser = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final message = Message(
      sentUserId: _activeUser,
      receivedUserId: widget.otherUserId,
      message: messageText,
      timestamp: DateTime.timestamp(),
    );

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add(message.toMap());

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update(
      {
        'lastMessage': message.message,
        'lastMessageTimestamp': message.timestamp,
      },
    );

    _messageController.clear();
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final isToday =
        now.year == timestamp.year &&
        now.month == timestamp.month &&
        now.day == timestamp.day;

    if (isToday) {
      return DateFormat('h:mm a').format(timestamp);
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/SceneItLogo.png'),
        backgroundColor: AppColors.lightBlue,
        centerTitle: true,
      ),
      backgroundColor: AppColors.lightBlue,
      bottomNavigationBar: Navbar(selectedIndex: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(widget.otherUserPhoto),
                ),
                SizedBox(width: 16),
                Text(
                  widget.otherUsername,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .collection('messages')
                      .orderBy('timestamp')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                }

                final messageDocs = snapshot.data?.docs ?? [];

                final messages =
                    messageDocs.map((doc) {
                      return Message.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                      );
                    }).toList();

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isActiveUser = message.sentUserId == _activeUser;

                    return Align(
                      alignment:
                          isActiveUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment:
                            isActiveUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            padding: EdgeInsets.all(12),
                            constraints: BoxConstraints(maxWidth: 300),
                            decoration: BoxDecoration(
                              color:
                                  isActiveUser
                                      ? AppColors.darkBlue
                                      : Colors.grey[400],
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12.0),
                                topRight: Radius.circular(12.0),
                                bottomLeft:
                                    isActiveUser
                                        ? Radius.circular(12.0)
                                        : Radius.zero,
                                bottomRight:
                                    isActiveUser
                                        ? Radius.zero
                                        : Radius.circular(12.0),
                              ),
                            ),
                            child: Text(
                              message.message,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              formatTimestamp(message.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Enter your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(onPressed: _sendMessage, icon: Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
