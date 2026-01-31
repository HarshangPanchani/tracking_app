import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

class LocationService {
  static const String notificationChannelId = 'tracking_channel';
  static const String notificationChannelName = 'Company Tracker';
  static const int notificationId = 888;

  /// Initialize the background service
  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description: 'This channel is used for location tracking notifications',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Create the notification channel on Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Configure the background service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Company Tracker',
        initialNotificationContent: 'Initializing...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  /// Start tracking for a specific user
  static Future<void> start(String uid, String name) async {
    final service = FlutterBackgroundService();

    // Check if service is running
    var isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }

    // Invoke the start_tracking event
    service.invoke('start_tracking', {'uid': uid, 'name': name});
  }

  /// Stop tracking
  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stop_tracking');
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Main background service entry point
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Initialize Firebase in the background isolate
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    StreamSubscription<Position>? positionStreamSubscription;
    String? currentUid;
    String? currentName;

    // Update notification helper
    Future<void> updateNotification(String content) async {
      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
          title: 'Company Tracker',
          content: content,
        );
      }
    }

    // Listen for start_tracking event
    service.on('start_tracking').listen((event) async {
      if (event != null) {
        currentUid = event['uid'] as String?;
        currentName = event['name'] as String?;

        if (currentUid == null) {
          await updateNotification('Error: No user ID provided');
          return;
        }

        await updateNotification('Starting location tracking...');

        // Check and request location permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          await updateNotification('Location permission denied');
          return;
        }

        // Cancel existing subscription if any
        await positionStreamSubscription?.cancel();

        // Start location stream
        final LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        );

        positionStreamSubscription =
            Geolocator.getPositionStream(
              locationSettings: locationSettings,
            ).listen(
              (Position position) async {
                try {
                  final FirebaseFirestore firestore =
                      FirebaseFirestore.instance;
                  final double lat = position.latitude;
                  final double lng = position.longitude;

                  // Prepare live status data
                  final Map<String, dynamic> liveStatusData = {
                    'current_lat': lat,
                    'current_lng': lng,
                    'last_updated': FieldValue.serverTimestamp(),
                    'name': currentName ?? 'Unknown User',
                    'is_active': true,
                  };

                  // Prepare history data
                  final Map<String, dynamic> historyData = {
                    'lat': lat,
                    'lng': lng,
                    'timestamp': FieldValue.serverTimestamp(),
                  };

                  // Execute both operations in parallel
                  await Future.wait([
                    // Update live status
                    firestore
                        .collection('users')
                        .doc(currentUid)
                        .set(liveStatusData, SetOptions(merge: true)),

                    // Add to location history
                    firestore
                        .collection('users')
                        .doc(currentUid)
                        .collection('location_history')
                        .add(historyData),
                  ]);

                  // Update notification with last update time
                  final String timestamp = DateTime.now().toString().split(
                    '.',
                  )[0];
                  await updateNotification(
                    'Tracking active: Last update at $timestamp',
                  );

                  // Send update to UI if needed
                  service.invoke('location_update', {
                    'lat': lat,
                    'lng': lng,
                    'timestamp': timestamp,
                  });
                } catch (e) {
                  await updateNotification('Error updating location: $e');
                }
              },
              onError: (error) async {
                await updateNotification('Location stream error: $error');
              },
            );

        await updateNotification('Tracking started successfully');
      }
    });

    // Listen for stop_tracking event
    service.on('stop_tracking').listen((event) async {
      await updateNotification('Stopping tracking...');

      // Cancel the position stream
      await positionStreamSubscription?.cancel();
      positionStreamSubscription = null;

      // Update Firestore to set is_active to false
      if (currentUid != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .update({
                'is_active': false,
                'last_updated': FieldValue.serverTimestamp(),
              });
        } catch (e) {
          await updateNotification('Error stopping tracking: $e');
        }
      }

      await updateNotification('Tracking stopped');

      // Stop the service
      service.stopSelf();
    });

    // Listen for service stop event
    service.on('stop').listen((event) async {
      await positionStreamSubscription?.cancel();
      service.stopSelf();
    });
  }

  /// Check if location service is enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position once
  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if background service is running
  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}
