import 'package:flutter/material.dart';

/// Profile screen with dummy user info and posts section.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            const Text('John Doe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('+241 00 00 00 00'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Edit Profile'),
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('My Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            // placeholder for posts
            Container(
              height: 150,
              color: Colors.grey[200],
              alignment: Alignment.center,
              child: const Text('No posts yet'),
            ),
          ],
        ),
      ),
    );
  }
}
