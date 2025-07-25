import 'dart:async';
import 'dart:math';
import '../models/event.dart';
import '../models/user.dart';
import 'notification_service.dart';
import 'ndma_service.dart';
import 'location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  Timer? _alertTimer;
  final List<Event> _activeAlerts = [];
  ProviderContainer? _providerContainer;
  bool _hasActiveHighSeverityAlerts = false;
  
  // User preferences for alert categories
  static const Map<String, String> _categoryTopics = {
    'Traffic': 'traffic_alerts',
    'Emergency': 'emergency_alerts',
    'Weather': 'weather_alerts',
    'Infrastructure': 'infrastructure_alerts',
    'Utilities': 'utilities_alerts',
  };

  // Initialize alert service
  Future<void> initialize({ProviderContainer? providerContainer}) async {
    await NotificationService.initialize();
    _providerContainer = providerContainer;
    _startAlertMonitoring();
  }

  // Start monitoring for alerts
  void _startAlertMonitoring() {
    _alertTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkForNewAlerts();
    });
  }

  // Stop alert monitoring
  void stopAlertMonitoring() {
    _alertTimer?.cancel();
  }

  // Subscribe user to alert categories based on preferences
  Future<void> subscribeToAlertCategories(UserPreferences preferences) async {
    for (String category in preferences.categories) {
      final topic = _categoryTopics[category];
      if (topic != null) {
        await NotificationService.subscribeToTopic(topic);
        print('Subscribed to $category alerts');
      }
    }
  }

  // Unsubscribe from alert categories
  Future<void> unsubscribeFromAlertCategories(List<String> categories) async {
    for (String category in categories) {
      final topic = _categoryTopics[category];
      if (topic != null) {
        await NotificationService.unsubscribeFromTopic(topic);
        print('Unsubscribed from $category alerts');
      }
    }
  }

  // Check for new alerts from NDMA API
  Future<void> _checkForNewAlerts() async {
    try {
      // Get current location
      final location = await LocationService.getCurrentLocation();
      if (location == null) {
        print('Unable to get current location for NDMA alerts');
        return;
      }

      // Get user preferences for alert radius (default 5km if not available)
      double alertRadius = 300.0; // Default radius set to 300 km as per new requirement
      if (_providerContainer != null) {
        try {
          final userState = _providerContainer!.read(userProvider);
          userState.whenData((user) {
            alertRadius = user.preferences.alertRadius;
          });
        } catch (e) {
          print('Error getting user preferences: $e');
        }
      }

      // Fetch alerts from NDMA API
      final ndmaAlerts = await NdmaService.fetchLocationWiseAlerts(
        latitude: location.lat,
        longitude: location.lng,
        radiusKm: alertRadius,
      );
      print('NDMA Alerts Response:');
      for (final alert in ndmaAlerts) {
        print(alert);
      }

      // Process new alerts
      for (final alert in ndmaAlerts) {
        // Check if this alert is already active
        final existingAlert = _activeAlerts.firstWhere(
          (existing) => existing.eventId == alert.eventId,
          orElse: () => Event(
            eventId: '',
            eventType: '',
            severity: '',
            location: Location(lat: 0, lng: 0, address: ''),
            mediaURL: '',
            timestamp: DateTime.now(),
            summary: '',
            description: '',
            reportedBy: '',
            category: '',
            impactRadius: 0,
          ),
        );

        if (existingAlert.eventId.isEmpty) {
          await _processNewAlert(alert);
        }
      }

      // Update theme based on alert presence
      _updateThemeForAlerts();

      // Fallback: Generate random alerts for demonstration if no NDMA alerts
      if (ndmaAlerts.isEmpty) {
        final random = Random();
        if (random.nextDouble() < 0.1) { // 10% chance of demo alert
          final alert = _generateRandomAlert();
          await _processNewAlert(alert);
        }
      }
    } catch (e) {
      print('Error checking for NDMA alerts: $e');
      // Fallback to random alerts on error
      final random = Random();
      if (random.nextDouble() < 0.1) {
        final alert = _generateRandomAlert();
        await _processNewAlert(alert);
      }
    }
  }

  // Generate a random alert for demonstration
  Event _generateRandomAlert() {
    final random = Random();
    final alertTypes = ['Traffic', 'Emergency', 'Weather', 'Infrastructure'];
    final severities = ['High', 'Medium', 'Low'];
    final locations = [
      'MG Road', 'Brigade Road', 'Koramangala', 'Whitefield', 
      'Electronic City', 'Indiranagar', 'Jayanagar', 'Malleshwaram'
    ];

    final alertType = alertTypes[random.nextInt(alertTypes.length)];
    final severity = severities[random.nextInt(severities.length)];
    final location = locations[random.nextInt(locations.length)];

    String title, description;
    
    switch (alertType) {
      case 'Traffic':
        title = '🚦 Traffic Alert in $location';
        description = 'Heavy traffic congestion reported. Consider alternate routes.';
        break;
      case 'Emergency':
        title = '🚨 Emergency Alert';
        description = 'Emergency situation reported in $location area. Please avoid the area.';
        break;
      case 'Weather':
        title = '🌧️ Weather Alert';
        description = 'Heavy rainfall expected in $location. Plan your travel accordingly.';
        break;
      case 'Infrastructure':
        title = '🚧 Infrastructure Alert';
        description = 'Road work in progress at $location. Expect delays.';
        break;
      default:
        title = 'City Alert';
        description = 'Important city notification for $location area.';
    }

    return Event(
      eventId: DateTime.now().millisecondsSinceEpoch.toString(),
      eventType: alertType,
      severity: severity,
      location: Location(
        lat: 12.9716 + (random.nextDouble() - 0.5) * 0.1,
        lng: 77.5946 + (random.nextDouble() - 0.5) * 0.1,
        address: location,
      ),
      mediaURL: '', // No media for generated alerts
      timestamp: DateTime.now(),
      summary: title,
      description: description,
      reportedBy: 'System', // Auto-generated alerts are reported by system
      category: alertType,
      impactRadius: 1.0, // Default 1km radius
    );
  }

  // Process new alert and send notification if needed
  Future<void> _processNewAlert(Event alert) async {
    _activeAlerts.add(alert);
    
    // Update theme immediately when high severity alert is added
    if (alert.severity.toLowerCase() == 'high') {
      _hasActiveHighSeverityAlerts = true;
      _updateThemeForAlerts();
    }
    
    // Check if user should receive notification for this category
    final shouldNotify = await NotificationService.areNotificationsEnabledForCategory(alert.eventType);
    
    if (shouldNotify) {
      await NotificationService.showAlertNotification(
        title: alert.summary,
        body: alert.description,
        alertType: alert.eventType,
        severity: alert.severity,
      );
      
      print('Alert notification sent: ${alert.summary}');
    }
  }

  // Send a test notification
  Future<void> sendTestNotification() async {
    await NotificationService.showAlertNotification(
      title: '🧪 Test Notification',
      body: 'This is a test notification from City Pulse. Your alerts are working!',
      alertType: 'Test',
      severity: 'Medium',
    );
  }

  // Send emergency alert to all users
  Future<void> sendEmergencyAlert({
    required String title,
    required String message,
    required String location,
  }) async {
    await NotificationService.showAlertNotification(
      title: '🚨 EMERGENCY: $title',
      body: '$message Location: $location',
      alertType: 'Emergency',
      severity: 'High',
    );
  }

  // Get active alerts
  List<Event> getActiveAlerts() {
    return List.unmodifiable(_activeAlerts);
  }

  // Clear old alerts (older than 24 hours)
  void clearOldAlerts() {
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
    final removedCount = _activeAlerts.length;
    _activeAlerts.removeWhere((alert) => alert.timestamp.isBefore(cutoffTime));
    
    // Update theme if alerts were removed
    if (removedCount != _activeAlerts.length) {
      _updateThemeForAlerts();
    }
  }

  // Get FCM token for server-side notifications
  Future<String?> getFCMToken() async {
    return await NotificationService.getFCMToken();
  }

  // Get alert statistics
  Map<String, int> getAlertStatistics() {
    final stats = <String, int>{};
    for (final alert in _activeAlerts) {
      stats[alert.eventType] = (stats[alert.eventType] ?? 0) + 1;
    }
    return stats;
  }

  // Update theme based on current alerts
  void _updateThemeForAlerts() {
    if (_providerContainer == null) return;
    
    try {
      final hasHighSeverityAlerts = _activeAlerts.any(
        (alert) => alert.severity.toLowerCase() == 'high'
      );
      
      _hasActiveHighSeverityAlerts = hasHighSeverityAlerts;
      
      final themeNotifier = _providerContainer!.read(dynamicThemeProvider.notifier);
      
      if (hasHighSeverityAlerts) {
        // Find the most severe alert to determine theme
        final highSeverityAlert = _activeAlerts.firstWhere(
          (alert) => alert.severity.toLowerCase() == 'high',
          orElse: () => _activeAlerts.first,
        );
        
        themeNotifier.updateThemeForAlert(
          highSeverityAlert.eventType,
          highSeverityAlert.severity,
        );
        
        // Also update to emergency red theme
        themeNotifier.setEmergencyTheme(true);
      } else {
        themeNotifier.clearAlert();
        themeNotifier.setEmergencyTheme(false);
      }
    } catch (e) {
      print('Error updating theme for alerts: $e');
    }
  }
  
  // Get NDMA alerts for a specific location
  Future<List<Event>> getNdmaAlertsForLocation({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      return await NdmaService.fetchLocationWiseAlerts(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
    } catch (e) {
      print('Error fetching NDMA alerts: $e');
      return [];
    }
  }
  
  // Check if there are active high severity alerts
  bool hasActiveHighSeverityAlerts() {
    return _hasActiveHighSeverityAlerts;
  }
  
  // Manually trigger alert check
  Future<void> checkForAlertsNow() async {
    await _checkForNewAlerts();
  }

  // Clean up resources
  void dispose() {
    _alertTimer?.cancel();
    _activeAlerts.clear();
    _hasActiveHighSeverityAlerts = false;
    
    // Clear emergency theme on dispose
    if (_providerContainer != null) {
      try {
        final themeNotifier = _providerContainer!.read(dynamicThemeProvider.notifier);
        themeNotifier.clearAlert();
        themeNotifier.setEmergencyTheme(false);
      } catch (e) {
        print('Error clearing theme on dispose: $e');
      }
    }
  }
}
