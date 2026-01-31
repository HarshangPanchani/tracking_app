import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update user's live location and save to history
  /// This function performs two operations in parallel:
  /// 1. Updates the user's current location in users/{uid}
  /// 2. Adds a new document to location_history sub-collection
  Future<void> updateLocation(User user, double lat, double lng) async {
    try {
      final String uid = user.uid;
      final String name = user.displayName ?? user.email ?? 'Unknown User';

      // Prepare the live status update data
      final Map<String, dynamic> liveStatusData = {
        'current_lat': lat,
        'current_lng': lng,
        'last_updated': FieldValue.serverTimestamp(),
        'name': name,
        'is_active': true,
      };

      // Prepare the history data
      final Map<String, dynamic> historyData = {
        'lat': lat,
        'lng': lng,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Execute both operations in parallel using Future.wait
      await Future.wait([
        // Update live status in users collection
        _firestore
            .collection('users')
            .doc(uid)
            .set(liveStatusData, SetOptions(merge: true)),

        // Add to location history sub-collection
        _firestore
            .collection('users')
            .doc(uid)
            .collection('location_history')
            .add(historyData),
      ]);
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  /// Stop tracking for a specific user
  /// Sets is_active to false in the user's document
  Future<void> stopTracking(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'is_active': false,
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to stop tracking: $e');
    }
  }

  /// Get user's current location data
  Future<DocumentSnapshot> getUserLocation(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      throw Exception('Failed to get user location: $e');
    }
  }

  /// Stream of user's location updates
  Stream<DocumentSnapshot> getUserLocationStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Get all active users
  Stream<QuerySnapshot> getActiveUsers() {
    return _firestore
        .collection('users')
        .where('is_active', isEqualTo: true)
        .snapshots();
  }

  /// Get location history for a user
  Future<QuerySnapshot> getLocationHistory(String uid, {int limit = 50}) async {
    try {
      return await _firestore
          .collection('users')
          .doc(uid)
          .collection('location_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
    } catch (e) {
      throw Exception('Failed to get location history: $e');
    }
  }

  /// Stream of location history for a user
  Stream<QuerySnapshot> getLocationHistoryStream(String uid, {int limit = 50}) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('location_history')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Delete old location history (optional cleanup function)
  Future<void> deleteOldHistory(String uid, DateTime beforeDate) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('location_history')
          .where('timestamp', isLessThan: Timestamp.fromDate(beforeDate))
          .get();

      // Delete in batches
      final WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete old history: $e');
    }
  }
}
