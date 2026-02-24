import 'package:flutter/material.dart';

/// Simple placeholder for edit profile functionality.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: const Center(child: Text('Edit profile form goes here')),
    );
  }
}
