import 'package:flutter/material.dart';
import 'package:sceneit/widgets/button_widget.dart';
import '../constants/colors.dart';
import '../data/Show.dart';

class ShowDetailsScreen extends StatelessWidget {
  final Show show;

  const ShowDetailsScreen({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/SceneItLogo.png'),
        backgroundColor: AppColors.lightBlue,
        centerTitle: true,
      ),
      backgroundColor: AppColors.lightBlue,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://image.tmdb.org/t/p/w200${show.posterPath}',
                    width: 120,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 120,
                      height: 180,
                      color: Colors.grey,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        show.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        show.overview ?? 'No description available.',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ButtonWidget(
              text: 'Add to Watchlist',
              onPressed: () {},
              color: AppColors.darkBlue,
              fullWidth: true,
            ),
            const SizedBox(height: 32),

            const Text(
              'Reviews',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Reviews coming soon...'),
          ],
        ),
      ),
    );
  }
}
