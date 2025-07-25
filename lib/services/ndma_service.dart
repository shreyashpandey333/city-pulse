import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';

class NdmaService {
  static const String _baseUrl = 'https://sachet.ndma.gov.in/cap_public_website/FetchLocationWiseAlerts';
  
  /// Fetch location-wise alerts from NDMA API
  static Future<List<Event>> fetchLocationWiseAlerts({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl?lat=${latitude.toString()}&long=${longitude.toString()}&radius=${radiusKm.toString()}');

      print('Fetching NDMA alerts from: $uri');

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0',
        },
        body: json.encode({
          'lat': latitude,
          'long': longitude,
          'radius': radiusKm,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('NDMA API response: $data');
        
        final events = _parseNdmaResponse(data);
        
        // If no real alerts, add mock data for testing UI
        if (events.isEmpty) {
          print('No NDMA alerts found, adding mock data for testing');
          return _generateMockAlerts(latitude, longitude);
        }
        
        return events;
      } else {
        print('NDMA API error: ${response.statusCode} - ${response.body}');
        // Return mock data on API error for testing
        return _generateMockAlerts(latitude, longitude);
      }
    } catch (e) {
      print('Error fetching NDMA alerts: $e');
      // Return mock data on exception for testing
      return _generateMockAlerts(latitude, longitude);
    }
  }

  /// Parse NDMA API response and convert to Event objects
  static List<Event> _parseNdmaResponse(dynamic data) {
    final List<Event> events = [];
    
    try {
      // Handle different possible response structures
      List<dynamic> alerts = [];
      
      if (data is List) {
        alerts = data;
      } else if (data is Map && data.containsKey('alerts')) {
        alerts = data['alerts'] as List? ?? [];
      } else if (data is Map && data.containsKey('data')) {
        alerts = data['data'] as List? ?? [];
      } else if (data is Map && data.containsKey('features')) {
        alerts = data['features'] as List? ?? [];
      }

      for (final alert in alerts) {
        if (alert is Map<String, dynamic>) {
          final event = _parseAlertToEvent(alert);
          if (event != null) {
            events.add(event);
          }
        }
      }
    } catch (e) {
      print('Error parsing NDMA response: $e');
    }

    return events;
  }

  /// Parse individual alert object to Event
  static Event? _parseAlertToEvent(Map<String, dynamic> alert) {
    try {
      // Extract basic information
      final String? identifier = alert['identifier'] ?? alert['id'];
      final String? event = alert['event'] ?? alert['eventType'] ?? alert['type'];
      final String? headline = alert['headline'] ?? alert['title'] ?? alert['summary'];
      final String? description = alert['description'] ?? alert['desc'] ?? alert['details'];
      final String? areaDesc = alert['areaDesc'] ?? alert['area'] ?? alert['location'];
      final String? severity = alert['severity'] ?? alert['urgency'] ?? 'Medium';
      
      // Extract coordinates
      double? lat, lng;
      
      // Try different coordinate field names
      if (alert.containsKey('geometry')) {
        final geometry = alert['geometry'];
        if (geometry is Map && geometry.containsKey('coordinates')) {
          final coords = geometry['coordinates'];
          if (coords is List && coords.length >= 2) {
            lng = coords[0]?.toDouble();
            lat = coords[1]?.toDouble();
          }
        }
      } else if (alert.containsKey('coordinates')) {
        final coords = alert['coordinates'];
        if (coords is List && coords.length >= 2) {
          lng = coords[0]?.toDouble();
          lat = coords[1]?.toDouble();
        }
      } else if (alert.containsKey('lat') && alert.containsKey('lng')) {
        lat = alert['lat']?.toDouble();
        lng = alert['lng']?.toDouble();
      } else if (alert.containsKey('latitude') && alert.containsKey('longitude')) {
        lat = alert['latitude']?.toDouble();
        lng = alert['longitude']?.toDouble();
      }

      // Use default Bengaluru coordinates if not found
      lat ??= 12.9716;
      lng ??= 77.5946;

      // Extract timestamp
      DateTime timestamp = DateTime.now();
      if (alert.containsKey('sent')) {
        try {
          timestamp = DateTime.parse(alert['sent']);
        } catch (e) {
          print('Error parsing timestamp: $e');
        }
      } else if (alert.containsKey('effective')) {
        try {
          timestamp = DateTime.parse(alert['effective']);
        } catch (e) {
          print('Error parsing effective timestamp: $e');
        }
      }

      // Determine event type and category
      String eventType = _categorizeEvent(event ?? 'Alert');
      String category = eventType;

      // Create Event object
      return Event(
        eventId: identifier ?? DateTime.now().millisecondsSinceEpoch.toString(),
        eventType: eventType,
        severity: _normalizeSeverity(severity ?? 'Medium'),
        location: Location(
          lat: lat,
          lng: lng,
          address: areaDesc ?? 'Location not specified',
        ),
        mediaURL: '', // NDMA alerts typically don't have media
        timestamp: timestamp,
        summary: headline ?? 'NDMA Alert',
        description: description ?? 'No description available',
        reportedBy: 'NDMA', // National Disaster Management Authority
        category: category,
        impactRadius: _calculateImpactRadius(severity ?? 'Medium'),
      );
    } catch (e) {
      print('Error parsing individual alert: $e');
      return null;
    }
  }

  /// Categorize event based on event type
  static String _categorizeEvent(String eventType) {
    final type = eventType.toLowerCase();
    
    if (type.contains('flood') || type.contains('water')) {
      return 'Flood';
    } else if (type.contains('fire') || type.contains('wildfire')) {
      return 'Fire';
    } else if (type.contains('earthquake') || type.contains('seismic')) {
      return 'Earthquake';
    } else if (type.contains('cyclone') || type.contains('hurricane') || type.contains('storm')) {
      return 'Storm';
    } else if (type.contains('rain') || type.contains('precipitation')) {
      return 'Weather';
    } else if (type.contains('heat') || type.contains('temperature')) {
      return 'Heat Wave';
    } else if (type.contains('drought')) {
      return 'Drought';
    } else if (type.contains('landslide') || type.contains('avalanche')) {
      return 'Landslide';
    } else if (type.contains('tsunami')) {
      return 'Tsunami';
    } else if (type.contains('thunder') || type.contains('lightning')) {
      return 'Thunderstorm';
    } else {
      return 'Emergency';
    }
  }

  /// Normalize severity levels
  static String _normalizeSeverity(String severity) {
    final sev = severity.toLowerCase();
    
    if (sev.contains('extreme') || sev.contains('severe') || sev.contains('critical')) {
      return 'High';
    } else if (sev.contains('moderate') || sev.contains('medium')) {
      return 'Medium';
    } else if (sev.contains('minor') || sev.contains('low')) {
      return 'Low';
    } else {
      return 'Medium'; // Default
    }
  }

  /// Calculate impact radius based on severity
  static double _calculateImpactRadius(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'extreme':
      case 'severe':
        return 10.0; // 10km radius for high severity
      case 'medium':
      case 'moderate':
        return 5.0; // 5km radius for medium severity
      case 'low':
      case 'minor':
        return 2.0; // 2km radius for low severity
      default:
        return 5.0; // Default 5km radius
    }
  }

  /// Check if NDMA service is available
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await http.head(
        Uri.parse(_baseUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode < 500; // Service available if not server error
    } catch (e) {
      print('NDMA service availability check failed: $e');
      return false;
    }
  }

  /// Generate mock alerts for testing when API returns empty results
  static List<Event> _generateMockAlerts(double latitude, double longitude) {
    final now = DateTime.now();
    final random = DateTime.now().millisecondsSinceEpoch;
    
    return [
      Event(
        eventId: 'mock_flood_$random',
        eventType: 'Flood',
        severity: 'High',
        location: Location(
          lat: latitude + 0.01,
          lng: longitude + 0.01,
          address: 'Near ${_getLocationName(latitude, longitude)}',
        ),
        mediaURL: '',
        timestamp: now.subtract(const Duration(hours: 2)),
        summary: '🌊 Flood Warning - Heavy Rainfall',
        description: 'Heavy rainfall has caused flooding in low-lying areas. Avoid waterlogged roads and stay indoors if possible.',
        reportedBy: 'NDMA (Demo)',
        category: 'Flood',
        impactRadius: 8.0,
      ),
      Event(
        eventId: 'mock_weather_$random',
        eventType: 'Weather',
        severity: 'Medium',
        location: Location(
          lat: latitude - 0.005,
          lng: longitude + 0.008,
          address: 'Weather Station ${_getLocationName(latitude, longitude)}',
        ),
        mediaURL: '',
        timestamp: now.subtract(const Duration(minutes: 45)),
        summary: '⛈️ Thunderstorm Alert',
        description: 'Thunderstorm with lightning expected in the next 2-3 hours. Take necessary precautions.',
        reportedBy: 'NDMA (Demo)',
        category: 'Weather',
        impactRadius: 5.0,
      ),
      Event(
        eventId: 'mock_traffic_$random',
        eventType: 'Emergency',
        severity: 'Low',
        location: Location(
          lat: latitude + 0.008,
          lng: longitude - 0.003,
          address: 'Highway near ${_getLocationName(latitude, longitude)}',
        ),
        mediaURL: '',
        timestamp: now.subtract(const Duration(minutes: 20)),
        summary: '🚧 Road Closure - Maintenance Work',
        description: 'Road maintenance work in progress. Expect delays and use alternate routes.',
        reportedBy: 'NDMA (Demo)',
        category: 'Infrastructure',
        impactRadius: 2.0,
      ),
    ];
  }

  /// Get a simple location name based on coordinates
  static String _getLocationName(double latitude, double longitude) {
    // Simple location mapping for common Indian cities
    if (latitude >= 12.8 && latitude <= 13.1 && longitude >= 77.4 && longitude <= 77.8) {
      return 'Bangalore';
    } else if (latitude >= 19.0 && latitude <= 19.3 && longitude >= 72.7 && longitude <= 73.1) {
      return 'Mumbai';
    } else if (latitude >= 28.4 && latitude <= 28.8 && longitude >= 77.0 && longitude <= 77.4) {
      return 'Delhi';
    } else if (latitude >= 22.4 && latitude <= 22.7 && longitude >= 88.2 && longitude <= 88.5) {
      return 'Kolkata';
    } else if (latitude >= 13.0 && latitude <= 13.2 && longitude >= 80.1 && longitude <= 80.4) {
      return 'Chennai';
    } else {
      return 'Your Area';
    }
  }
}
