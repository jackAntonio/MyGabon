import 'package:flutter/material.dart';
import '../widgets/category_icon.dart';

/// Home screen showing welcome message, search bar and categories.
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to GabonConnect',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'What service do you need?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  CategoryIcon(icon: Icons.build, label: 'Repair'),
                  SizedBox(width: 16),
                  CategoryIcon(icon: Icons.computer, label: 'IT Services'),
                  SizedBox(width: 16),
                  CategoryIcon(icon: Icons.cleaning_services, label: 'Cleaning'),
                  SizedBox(width: 16),
                  CategoryIcon(icon: Icons.local_taxi, label: 'Transport'),
                  SizedBox(width: 16),
                  CategoryIcon(icon: Icons.store, label: 'Marketplace'),
                  SizedBox(width: 16),
                  CategoryIcon(icon: Icons.more_horiz, label: 'Other'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Featured Providers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // Placeholder for a horizontal list of featured providers
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text('Provider ${index + 1}'),
                  );
                },
              ),
            ),
            // remaining space
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}
