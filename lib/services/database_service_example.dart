// Example Usage of DatabaseService
// This file demonstrates how to use the DatabaseService in your Flutter app

import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

class LocationTrackingExample {
  final DatabaseService _dbService = DatabaseService();

  // Example 1: Update user location
  Future<void> exampleUpdateLocation() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Sample coordinates (latitude, longitude)
      double latitude = 37.7749; // San Francisco
      double longitude = -122.4194;

      try {
        await _dbService.updateLocation(user, latitude, longitude);
        print('Location updated successfully!');
      } catch (e) {
        print('Error updating location: $e');
      }
    }
  }

  // Example 2: Stop tracking
  Future<void> exampleStopTracking() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await _dbService.stopTracking(user.uid);
        print('Tracking stopped successfully!');
      } catch (e) {
        print('Error stopping tracking: $e');
      }
    }
  }

  // Example 3: Get active users (Stream)
  void exampleGetActiveUsers() {
    _dbService.getActiveUsers().listen((snapshot) {
      print('Active users count: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('User: ${data['name']}');
        print('Location: ${data['current_lat']}, ${data['current_lng']}');
        print('Last updated: ${data['last_updated']}');
        print('---');
      }
    });
  }

  // Example 4: Get location history
  Future<void> exampleGetLocationHistory() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final history = await _dbService.getLocationHistory(
          user.uid,
          limit: 10,
        );

        print('Location history (last 10):');
        for (var doc in history.docs) {
          final data = doc.data() as Map<String, dynamic>;
          print('Lat: ${data['lat']}, Lng: ${data['lng']}');
          print('Timestamp: ${data['timestamp']}');
          print('---');
        }
      } catch (e) {
        print('Error getting history: $e');
      }
    }
  }
}

/*
 * FIRESTORE DATA STRUCTURE:
 * 
 * users (collection)
 *   └── {uid} (document)
 *       ├── current_lat: double
 *       ├── current_lng: double
 *       ├── last_updated: Timestamp
 *       ├── name: String
 *       ├── is_active: boolean
 *       └── location_history (sub-collection)
 *           └── {auto-generated-id} (document)
 *               ├── lat: double
 *               ├── lng: double
 *               └── timestamp: Timestamp
 */
