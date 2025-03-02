import 'package:flutter/material.dart';
import '../models/artist_item.dart';

class ViewProfileScreen extends StatelessWidget {
  final ArtistItem artist;

  const ViewProfileScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(artist.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(artist.imageUrl),
            ),
            const SizedBox(height: 20),
            Text(
              artist.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            // Add more profile details here as needed
          ],
        ),
      ),
    );
  }
}
