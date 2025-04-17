import 'package:flutter/material.dart';
import 'package:sceneit/data/Show.dart';
import 'package:sceneit/data/tmdb_reader.dart';
import 'user_screen.dart';
import '../constants/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Show>> popularShows;
  late Future<List<Show>> topRatedShows;
  late Future<List<Show>>? searchResults;

  bool searchOpen = false;
  final TextEditingController searchController = TextEditingController();

  void onSearchInput(String input) {
    if (input.isNotEmpty) {
      setState(() {
        searchOpen = true;
        searchResults = TMDBReader().searchShowsByKeyword(input);
      });
    } else {
      setState(() {
        searchOpen = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    popularShows = TMDBReader().getPopularShows();
    topRatedShows = TMDBReader().getTopRatedShows();
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Discover",
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            showSearchBar(),
            Expanded(
              child:
                  searchOpen
                      ? FutureBuilder<List<Show>>(
                        future: searchResults,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }
                          final searchedShows = snapshot.data!;
                          return searchResultList(searchedShows);
                        },
                      )
                      : ListView(
                        children: [
                          Text(
                            "Trending Now",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          FutureBuilder<List<Show>>(
                            future: popularShows,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              }
                              final popShows = snapshot.data!;
                              return showCardList(popShows);
                            },
                          ),
                          Text(
                            "Top Rated",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          FutureBuilder<List<Show>>(
                            future: topRatedShows,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              }
                              final topShows = snapshot.data!;
                              return showCardList(topShows);
                            },
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.darkBlue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserProfileScreen()),
          );
        },
        child: Icon(Icons.person, color: Colors.white),
        tooltip: 'Profile',
      ),
    );
  }

  Widget showSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              style: TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search TV Shows',
                hintStyle: TextStyle(color: Colors.white),
                prefixIcon: Icon(Icons.search, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.darkBlue),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.darkBlue,
              ),
              onChanged: onSearchInput,
            ),
          ),
          if (searchOpen)
            IconButton(
              icon: Icon(Icons.close, color: AppColors.darkBlue),
              onPressed: () {
                setState(() {
                  searchOpen = false;
                  searchController.clear();
                });
              },
            ),
        ],
      ),
    );
  }

  Widget searchResultList(List<Show> shows) {
    return ListView.separated(
      itemCount: shows.length,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      separatorBuilder:
          (context, index) =>
              const Divider(thickness: 2.0, color: AppColors.darkBlue),
      itemBuilder: (context, index) {
        final show = shows[index];
        return Row(
          children: [
            Image.network(
              'https://image.tmdb.org/t/p/w200${show.posterPath}',
              width: 80,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    height: 160,
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Text(
                    show.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Icon(Icons.star, color: Colors.amberAccent),
                  Text(show.rating.toString()),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget showCardList(List<Show> shows) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: shows.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final show = shows[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: showCard(show),
          );
        },
      ),
    );
  }

  Widget showCard(Show show) {
    return SizedBox(
      width: 120,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                'https://image.tmdb.org/t/p/w200${show.posterPath}',
                width: 120,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      height: 160,
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 6.0,
              ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.amberAccent),
                  Text(show.rating.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
