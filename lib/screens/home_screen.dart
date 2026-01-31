import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isTracking = false;
  bool _isLoading = false;
  double? _currentLat;
  double? _currentLng;
  String _statusMessage = 'Ready to start duty';

  @override
  void initState() {
    super.initState();
    _checkTrackingStatus();
    _listenToLocationUpdates();
  }

  Future<void> _checkTrackingStatus() async {
    final isRunning = await LocationService.isServiceRunning();
    if (mounted) {
      setState(() {
        _isTracking = isRunning;
        _statusMessage = isRunning
            ? 'Duty active - Tracking location'
            : 'Ready to start duty';
      });
    }
  }

  void _listenToLocationUpdates() {
    final service = FlutterBackgroundService();

    // Listen for location updates from the background service
    service.on('location_update').listen((event) {
      if (event != null && mounted) {
        setState(() {
          _currentLat = event['lat'] as double?;
          _currentLng = event['lng'] as double?;
        });
      }
    });
  }

  Future<void> _handleStartDuty() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Requesting permissions...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      // Step 1: Request location permissions using permission_handler
      setState(() {
        _statusMessage = 'Requesting location permissions...';
      });

      PermissionStatus locationStatus = await Permission.locationAlways
          .request();

      if (locationStatus.isDenied) {
        throw Exception(
          'Location permission denied. Please grant location access.',
        );
      }

      if (locationStatus.isPermanentlyDenied) {
        throw Exception(
          'Location permission permanently denied. Please enable it in settings.',
        );
      }

      // Step 2: Check if location service is enabled
      setState(() {
        _statusMessage = 'Checking location services...';
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      // Step 3: Start the location service
      setState(() {
        _statusMessage = 'Starting duty...';
      });

      final String uid = user.uid;
      final String name = user.displayName ?? user.email ?? 'Unknown User';

      await LocationService.start(uid, name);

      // Step 4: Get initial position
      try {
        Position? position = await LocationService.getCurrentPosition();
        if (position != null) {
          setState(() {
            _currentLat = position.latitude;
            _currentLng = position.longitude;
          });
        }
      } catch (e) {
        // Initial position fetch failed, but tracking will continue
        print('Could not get initial position: $e');
      }

      if (mounted) {
        setState(() {
          _isTracking = true;
          _statusMessage = 'Duty active - Tracking location';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Duty started - Location tracking active'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage =
              'Error: ${e.toString().replaceAll('Exception: ', '')}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEndDuty() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Ending duty...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      // Step 1: Stop the background service
      FlutterBackgroundService().invoke('stop_tracking');

      // Step 2: Update Firestore status
      if (user != null) {
        final dbService = DatabaseService();
        await dbService.stopTracking(user.uid);
      }

      if (mounted) {
        setState(() {
          _isTracking = false;
          _statusMessage = 'Duty ended';
          _currentLat = null;
          _currentLng = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Duty ended - Tracking stopped'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending duty: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!_isTracking) {
            _statusMessage = 'Ready to start duty';
          }
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    // Stop tracking before logout if active
    if (_isTracking) {
      await _handleEndDuty();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Company Tracker'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _isLoading ? null : _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 45,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.displayName ?? 'User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Status Message
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _isTracking ? Colors.green[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isTracking ? Colors.green : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isTracking ? Icons.check_circle : Icons.info_outline,
                        color: _isTracking ? Colors.green : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isTracking
                                ? Colors.green[800]
                                : Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Current Coordinates Display
                if (_currentLat != null && _currentLng != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.my_location,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Current Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Latitude',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentLat!.toStringAsFixed(6),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey[300],
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Longitude',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentLng!.toStringAsFixed(6),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                if (_currentLat != null && _currentLng != null)
                  const SizedBox(height: 32),

                // Large Central Duty Button
                SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_isTracking ? _handleEndDuty : _handleStartDuty),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTracking
                          ? Colors.red[600]
                          : Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      shadowColor: (_isTracking ? Colors.red : Colors.green)
                          .withOpacity(0.4),
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: _isLoading
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: CircularProgressIndicator(
                                  strokeWidth: 4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Processing...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isTracking
                                    ? Icons.stop_circle
                                    : Icons.play_circle_filled,
                                size: 70,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isTracking ? 'END DUTY' : 'START DUTY',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isTracking
                                    ? 'Tap to stop tracking'
                                    : 'Tap to begin tracking',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Info Text
                if (!_isTracking && !_isLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your location will be tracked while on duty',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
