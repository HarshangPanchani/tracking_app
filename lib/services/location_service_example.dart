// Example Usage of LocationService
// This file demonstrates how to use the LocationService for background tracking

import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationTrackingUsageExample {
  final LocationService _locationService = LocationService();

  /// Example 1: Initialize the service (call this once in main.dart)
  Future<void> exampleInitialize() async {
    try {
      await _locationService.initializeService();
      print('Location service initialized successfully!');
    } catch (e) {
      print('Error initializing location service: $e');
    }
  }

  /// Example 2: Start tracking for current user
  Future<void> exampleStartTracking() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('No user logged in');
      return;
    }

    // Check if location service is enabled
    bool serviceEnabled = await LocationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled. Please enable them.');
      return;
    }

    // Check and request permissions
    var permission = await LocationService.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await LocationService.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }

    // Start tracking
    try {
      final String uid = user.uid;
      final String name = user.displayName ?? user.email ?? 'Unknown User';

      await LocationService.start(uid, name);
      print('Tracking started for user: $name');
    } catch (e) {
      print('Error starting tracking: $e');
    }
  }

  /// Example 3: Stop tracking
  Future<void> exampleStopTracking() async {
    try {
      await LocationService.stop();
      print('Tracking stopped successfully!');
    } catch (e) {
      print('Error stopping tracking: $e');
    }
  }

  /// Example 4: Check if service is running
  Future<void> exampleCheckServiceStatus() async {
    bool isRunning = await LocationService.isServiceRunning();
    print('Background service is running: $isRunning');
  }

  /// Example 5: Get current position once (without background tracking)
  Future<void> exampleGetCurrentPosition() async {
    final position = await LocationService.getCurrentPosition();

    if (position != null) {
      print('Current position:');
      print('Latitude: ${position.latitude}');
      print('Longitude: ${position.longitude}');
      print('Accuracy: ${position.accuracy} meters');
      print('Altitude: ${position.altitude} meters');
      print('Speed: ${position.speed} m/s');
    } else {
      print('Could not get current position');
    }
  }

  /// Complete workflow example
  Future<void> completeWorkflowExample() async {
    print('=== Complete Location Tracking Workflow ===\n');

    // Step 1: Initialize service (do this once in main.dart)
    print('Step 1: Initializing service...');
    await exampleInitialize();

    // Step 2: Check permissions
    print('\nStep 2: Checking permissions...');
    final permission = await LocationService.checkPermission();
    print('Permission status: $permission');

    // Step 3: Start tracking
    print('\nStep 3: Starting tracking...');
    await exampleStartTracking();

    // Step 4: Check if service is running
    print('\nStep 4: Checking service status...');
    await exampleCheckServiceStatus();

    // Wait for some time (in real app, this would be user-controlled)
    print('\nTracking for 30 seconds...');
    await Future.delayed(const Duration(seconds: 30));

    // Step 5: Stop tracking
    print('\nStep 5: Stopping tracking...');
    await exampleStopTracking();

    print('\n=== Workflow Complete ===');
  }
}

/*
 * INTEGRATION GUIDE:
 * 
 * 1. In main.dart, initialize the service before runApp():
 * 
 *    void main() async {
 *      WidgetsFlutterBinding.ensureInitialized();
 *      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
 *      
 *      // Initialize location service
 *      final locationService = LocationService();
 *      await locationService.initializeService();
 *      
 *      runApp(const MyApp());
 *    }
 * 
 * 2. In your UI (e.g., HomeScreen), add buttons to start/stop tracking:
 * 
 *    ElevatedButton(
 *      onPressed: () async {
 *        final user = FirebaseAuth.instance.currentUser;
 *        if (user != null) {
 *          await LocationService.start(
 *            user.uid,
 *            user.displayName ?? user.email ?? 'User',
 *          );
 *        }
 *      },
 *      child: const Text('Start Tracking'),
 *    ),
 * 
 *    ElevatedButton(
 *      onPressed: () async {
 *        await LocationService.stop();
 *      },
 *      child: const Text('Stop Tracking'),
 *    ),
 * 
 * 3. ANDROID PERMISSIONS (android/app/src/main/AndroidManifest.xml):
 * 
 *    Add these permissions inside <manifest>:
 *    
 *    <uses-permission android:name="android.permission.INTERNET"/>
 *    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
 *    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
 *    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
 *    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
 *    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
 *    <uses-permission android:name="android.permission.WAKE_LOCK"/>
 * 
 * 4. iOS PERMISSIONS (ios/Runner/Info.plist):
 * 
 *    Add these keys:
 *    
 *    <key>NSLocationWhenInUseUsageDescription</key>
 *    <string>We need your location to track your position</string>
 *    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
 *    <string>We need your location to track your position in the background</string>
 *    <key>UIBackgroundModes</key>
 *    <array>
 *      <string>fetch</string>
 *      <string>location</string>
 *    </array>
 */
