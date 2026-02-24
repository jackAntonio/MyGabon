import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../widgets/service_card.dart';

/// Services / Announcements screen showing a list of nearby services.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({Key? key}) : super(key: key);

  // dummy list of services
  static final List<ServiceModel> _services = [
    ServiceModel(
      title: 'Plumbing Repair',
      description: 'Fix leaks and blocked pipes quickly.',
      location: 'Libreville',
      rating: 4.5,
    ),
    ServiceModel(
      title: 'Computer Repair',
      description: 'Software & hardware troubleshooting.',
      location: 'Port-Gentil',
      rating: 4.2,
    ),
    // add more as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services & Announcements')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          return ServiceCard(service: service);
        },
      ),
    );
  }
}
