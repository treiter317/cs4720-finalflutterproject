import 'package:flutter/material.dart';
import 'package:sceneit/constants/colors.dart';
import 'package:sceneit/screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sceneit',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.lightBlue,
        appBar: AppBar(
          title: Image.asset(
            'assets/SceneItLogo.png',
          ),
          backgroundColor: AppColors.lightBlue,
          centerTitle: true,
        ),
        bottomNavigationBar: null, //this is where we can have the navigation bar that appears on each screen
        body: HomeScreen(),
      ),
    );
  }
}
