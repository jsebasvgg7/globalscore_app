import 'package:flutter/material.dart';

class AlbumDetailPage extends StatelessWidget {
  final String albumId;
  const AlbumDetailPage({super.key, required this.albumId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Album: $albumId')),
    );
  }
}
