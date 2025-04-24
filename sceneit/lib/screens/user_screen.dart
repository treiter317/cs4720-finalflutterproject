import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sceneit/screens/show_detail_screen.dart';
import '../constants/colors.dart';
import '../data/Review.dart';
import '../data/Show.dart';
import 'login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}
//TODO: allow removing/ editing of reviews
//TODO: show the rating of shows in the home screen. Both by sceneit users and tmdb
//TODO: Allow adding a review in the home section direcftly

class _UserProfileScreenState extends State<UserProfileScreen> {
  String username = '';
  String profilePicUrl = '';
  String joinedDate = '';
  bool isLoading = true;
  List<Review> myReviews = [];
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadWatchlist();
    _loadReviews();
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

  List<Show> watchlist = [];

  Future<void> _loadWatchlist() async {
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('watchlist')
        .get();

    final loaded = snapshot.docs.map((doc) {
      final data = doc.data();
      return Show(
        name: data['title'],
        posterPath: data['posterPath'],
        rating: 0,
        overview: "",
      );
    }).toList();

    setState(() {
      watchlist = loaded;
    });
  }

  Future<void> _loadReviews() async {
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('reviews')
        .get();

    final reviews = snapshot.docs.map((doc) => Review.fromMap(doc.data())).toList();

    setState(() {
      myReviews = reviews;
    });
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

  Future<void> _removeFromWatchlist(Show show) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      watchlist.removeWhere((s) => s.name == show.name);
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('watchlist')
        .doc(show.name)
        .delete();
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
        title: Image.asset('assets/SceneItLogo.png'),
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
                    const SizedBox(height: 10),
                    if (watchlist.isNotEmpty) ...[
                      Text(
                        'Watchlist',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 240,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: watchlist.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: showCard(watchlist[index]),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (myReviews.isNotEmpty) ...[
                      Text(
                        'My Reviews',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: myReviews.length,
                          itemBuilder: (context, index) {
                            final review = myReviews[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: reviewCard(review),
                            );
                          },
                        ),
                      ),
                    ]

                  ],
                ),
              ),
    );
  }

  Widget showCard(Show show) {
    return GestureDetector(
      onTap: () => _showWatchModal(show),
      child: SizedBox(
        width: 120,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  'https://image.tmdb.org/t/p/w200${show.posterPath}',
                  width: 120,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    height: 160,
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Text(
                  show.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showWatchModal(Show show) {
    final TextEditingController commentController = TextEditingController();
    double rating = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text("Leave a review and rating"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Write your review...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Rating: ${rating.toInt()} / 100"),
                  Slider(
                    value: rating,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: rating.toInt().toString(),
                    onChanged: (newRating) {
                      setModalState(() {
                        rating = newRating;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await _removeFromWatchlist(show);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Removed from watchlist")),
                      );
                    } catch (e) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to remove: $e")),
                      );
                    }
                  },
                  child: const Text("Remove from Watchlist"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      try {
                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(user.uid)
                            .collection("reviews")
                            .doc(show.name)
                            .set({
                          "title": show.name,
                          "posterPath": show.posterPath,
                          "review": commentController.text,
                          "rating": rating,
                          "timestamp": FieldValue.serverTimestamp(),
                        });

                        await _loadWatchlist();
                        await _loadReviews();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Review submitted!")),
                        );
                      } catch (e) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to submit review: $e")),
                        );
                      }
                    }
                  },
                  child: const Text("Submit Review"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Widget reviewCard(Review review) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              review.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              review.reviewText,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              'Rating: ${review.rating.toInt()} / 100',
              style: TextStyle(fontSize: 13, color: Colors.amber[800]),
            ),
          ],
        ),
      ),
    );
  }
}
