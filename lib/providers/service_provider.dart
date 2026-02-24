import 'package:flutter/material.dart';
import '../models/service_model.dart';

/// Provides list of services and filtering logic.
class ServiceProvider extends ChangeNotifier {
  List<ServiceModel> _services = [];

  List<ServiceModel> get services => _services;

  ServiceProvider() {
    // populate with dummy data on init
    _services = [
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
    ];
  }

  void filterByCategory(String category) {
    // TODO: implement filtering logic when real data available
    notifyListeners();
  }

  void search(String query) {
    // TODO: implement search logic
    notifyListeners();
  }
}
