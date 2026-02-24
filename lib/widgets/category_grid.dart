import 'package:flutter/material.dart';
import '../services/dummy_data.dart';

/// Grid of category tiles displayed on the home screen.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = DummyData.categories;

    return GridView.builder(
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final name = categories[index];
        return GestureDetector(
          onTap: () {
            // navigate to filtered services
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(name, style: const TextStyle(fontSize: 16)),
          ),
        );
      },
    );
  }
}
