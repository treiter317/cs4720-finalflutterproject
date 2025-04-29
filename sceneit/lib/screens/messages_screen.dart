import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sceneit/screens/active_chat_screen.dart';
import '../constants/colors.dart';
import '../widgets/navbar.dart';
import 'package:intl/intl.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _activeUser = FirebaseAuth.instance.currentUser;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _userId = _activeUser!.uid;
  }

  Future<Map<String, dynamic>> _fetchUserInfo(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    return {
      'username': userDoc.data()?['username'] ?? 'Unknown',
      'profile_pic':
          userDoc.data()?['profilePic'] ??
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRmK71ObBifzt00f_UVxSxZrB8tB9YxnKjB7Q&s',
    };
  }

  // show date and time if not today; otherwise just time
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
        automaticallyImplyLeading: false,
      ),
      backgroundColor: AppColors.lightBlue,
      bottomNavigationBar: Navbar(selectedIndex: 0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Text(
              "Your Conversations",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .where('users', arrayContains: _userId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "You have no previous chats.\nCreate a chat with a user from a review.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final chats = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final users = List<String>.from(chat['users']);
                    final lastMessage =
                        chat['lastMessage'] ?? 'No messages yet';
                    final lastMessageTimestamp =
                        (chat['lastMessageTimestamp'] as Timestamp?)?.toDate();

                    final otherUserId = users.firstWhere(
                      (userId) => userId != _userId,
                    );

                    final otherUserInfo = _fetchUserInfo(otherUserId);

                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white,
                        child: FutureBuilder(
                          future: otherUserInfo,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return ListTile(
                                title: Text('Loading...'),
                                leading: CircleAvatar(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return ListTile(
                                title: Text('Error loading user'),
                              );
                            }
                            final userInfo = snapshot.data!;
                            return ListTile(
                              title: Text(
                                userInfo['username'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundImage: NetworkImage(
                                  userInfo['profile_pic'],
                                ),
                              ),
                              subtitle: Text(lastMessage),
                              trailing: Text(
                                lastMessageTimestamp != null
                                    ? formatTimestamp(lastMessageTimestamp)
                                    : "Unknown time",
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ActiveChatScreen(
                                          chatId: chat.id,
                                          otherUserId: otherUserId,
                                          otherUserPhoto:
                                              userInfo['profile_pic'],
                                          otherUsername: userInfo['username'],
                                        ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
