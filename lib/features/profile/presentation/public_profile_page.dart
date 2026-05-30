import 'package:flutter/material.dart';

class PublicProfilePage extends StatelessWidget {
  final String userId;
  const PublicProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('User: $userId')),
    );
  }
}
