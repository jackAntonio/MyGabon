import 'package:flutter/material.dart';
import '../widgets/service_card.dart';
import 'package:provider/provider.dart';
import '../widgets/skeleton_loader.dart';
import '../providers/service_provider.dart';

/// Services / Announcements screen showing a list of nearby services.

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ServiceProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Services & Announcements')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search services...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: provider.search,
              ),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: SkeletonLoader(height: 100, borderRadius: BorderRadius.circular(16)),
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.services.length,
                    itemBuilder: (context, index) {
                      final service = provider.services[index];
                      return ServiceCard(service: service);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
