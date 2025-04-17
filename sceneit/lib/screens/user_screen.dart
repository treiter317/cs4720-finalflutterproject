import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../constants/colors.dart';
import 'login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String username = '';
  String profilePicUrl = '';
  String joinedDate = '';
  bool isLoading = true;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .get();

      setState(() {
        username = userDoc.data()?['username'] ?? 'Unknown';
        profilePicUrl =
            userDoc.data()?['profilePic'] ??
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRmK71ObBifzt00f_UVxSxZrB8tB9YxnKjB7Q&s';
        joinedDate =
            user?.metadata.creationTime?.toLocal().toString().split(' ')[0] ??
            '';
        isLoading = false;
      });
    }
  }

  Future<void> _editProfileDialog() async {
    File? newImage;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: const Text("Update Profile Picture"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (pickedFile != null) {
                            setStateDialog(() {
                              newImage = File(pickedFile.path);
                            });
                          }
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              newImage != null
                                  ? FileImage(newImage!)
                                  : NetworkImage(profilePicUrl)
                                      as ImageProvider,
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Icon(Icons.camera_alt, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Tap to change your profile picture",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (newImage != null) {
                          final ref = FirebaseStorage.instance.ref(
                            'profile_pictures/${user!.uid}',
                          );
                          await ref.putFile(newImage!);
                          final newImageUrl = await ref.getDownloadURL();

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user!.uid)
                              .update({'profilePic': newImageUrl});

                          Navigator.pop(context);
                          _fetchUserData();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.lightBlue,
        elevation: 0,
        title: Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: NetworkImage(profilePicUrl),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Joined: $joinedDate'),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: _editProfileDialog,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Important note: This section is being worked on actively, logout + image picker working only at the moment',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
    );
  }
}
