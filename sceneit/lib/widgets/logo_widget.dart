import 'package:flutter/material.dart';
//TODO: Fix this to have a normal stacked logowidget and the side by side logo
class LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.black,
          child: Icon(Icons.movie, size: 40, color: Colors.greenAccent),
        ),
        const SizedBox(height: 10),
        const Text(
          'Sceneit.',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
