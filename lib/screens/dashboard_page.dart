import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../providers/user_provider.dart';
import '../providers/chat_providers.dart';
import '../providers/events_provider.dart';
import '../models/chat_message.dart';
import '../models/event.dart';
import '../services/location_service.dart';
import '../themes/app_theme.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _chatController;
  late Animation<double> _chatHeightAnimation;
  late Animation<double> _chatOpacityAnimation;
  late TextEditingController _messageController;
  late ScrollController _chatScrollController;

  
  bool _isChatExpanded = true;  // Start expanded
  double _minChatHeight = 120;
  double _maxChatHeight = 500;
  
  Set<Marker> _markers = {};
  List<Event> _events = [];
  Location? _currentLocation;

  @override
  void initState() {
    super.initState();
    _initializeResponsiveSizes();
    _initializeAnimations();
    _loadEventsAndLocation();
  }
  
  void _initializeResponsiveSizes() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;
      
      // Responsive sizing based on screen size
      if (screenWidth < 600) { // Mobile
        _minChatHeight = 100;
        _maxChatHeight = screenHeight * 0.6; // 60% of screen height
      } else if (screenWidth < 1024) { // Tablet
        _minChatHeight = 120;
        _maxChatHeight = screenHeight * 0.5; // 50% of screen height
      } else { // Desktop
        _minChatHeight = 140;
        _maxChatHeight = screenHeight * 0.4; // 40% of screen height
      }
      
      // Ensure minimum safe area
      final bottomPadding = MediaQuery.of(context).padding.bottom;
      _maxChatHeight = (_maxChatHeight - bottomPadding - 50).clamp(200.0, screenHeight * 0.7);
      
      setState(() {
        _initializeAnimations();
      });
    });
  }
  
  void _initializeAnimations() {
    _chatController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _chatHeightAnimation = Tween<double>(
      begin: _minChatHeight,
      end: _maxChatHeight,
    ).animate(CurvedAnimation(
      parent: _chatController,
      curve: Curves.easeInOut,
    ));
    
    _chatOpacityAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chatController,
      curve: Curves.easeInOut,
    ));
    
    _messageController = TextEditingController();
    _chatScrollController = ScrollController();
    
    // Start with chat expanded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatController.forward();
    });
  }
  
  Future<void> _loadEventsAndLocation() async {
    try {
      // Get current location
      _currentLocation = await LocationService.getCurrentLocation();
      
      // Load events from events provider (NDMA integration)
      ref.read(eventsProvider.notifier).loadEvents();
      
      setState(() {});
    } catch (e) {
      print('Error loading location: $e');
    }
  }
  
  Future<void> _createMarkers() async {
    Set<Marker> markers = {};
    
    // Add event markers from _events
    for (final event in _events) {
      final marker = Marker(
        markerId: MarkerId(event.eventId),
        position: LatLng(event.location.lat, event.location.lng),
        infoWindow: InfoWindow(
          title: event.summary,
          snippet: event.description,
        ),
        icon: await _createCustomMarkerIcon(_getMarkerColorByCategory(event.category), _getMarkerIconByCategory(event.category)),
      );
      markers.add(marker);
    }

    // Add current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentLocation!.lat, _currentLocation!.lng),
          icon: await _createCustomMarkerIcon(Colors.blue, Icons.my_location),
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: _currentLocation!.address,
          ),
        ),
      );
    }
    
    // Add event markers
    for (Event event in _events) {
      Color markerColor = _getMarkerColorByCategory(event.category);
      IconData markerIcon = _getMarkerIconByCategory(event.category);
      
      markers.add(
        Marker(
          markerId: MarkerId(event.eventId),
          position: LatLng(event.location.lat, event.location.lng),
          icon: await _createCustomMarkerIcon(markerColor, markerIcon),
          infoWindow: InfoWindow(
            title: event.eventType,
            snippet: '${event.severity} - ${event.location.address}',
          ),
        ),
      );
    }
    
    _markers = markers;
  }
  
  Future<BitmapDescriptor> _createCustomMarkerIcon(Color color, IconData icon) async {
    // Create custom marker icon with specific event icons
    try {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      const double size = 100.0;
      
      // Draw circular background
      final backgroundPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2 - 2,
        backgroundPaint,
      );
      
      // Draw white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2 - 2,
        borderPaint,
      );
      
      // Draw icon
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: size * 0.5,
            fontFamily: icon.fontFamily ?? 'MaterialIcons',
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size - textPainter.width) / 2,
          (size - textPainter.height) / 2,
        ),
      );
      
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      
      return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    } catch (e) {
      print('Error creating custom marker: $e');
      // Fallback to default marker
      return BitmapDescriptor.defaultMarkerWithHue(_getHueFromColor(color));
    }
  }
  
  double _getHueFromColor(Color color) {
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    if (color == Colors.yellow) return BitmapDescriptor.hueYellow;
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.blue) return BitmapDescriptor.hueBlue;
    if (color == Colors.purple) return BitmapDescriptor.hueViolet;
    return BitmapDescriptor.hueRed;
  }
  
  Color _getMarkerColorByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'traffic':
        return Colors.orange;
      case 'emergency':
        return Colors.red;
      case 'weather':
        return Colors.blue;
      case 'event':
        return Colors.green;
      case 'construction':
        return Colors.yellow;
      default:
        return Colors.purple;
    }
  }
  
  IconData _getMarkerIconByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'traffic':
        return Icons.traffic;
      case 'emergency':
      case 'fire':
        return Icons.local_fire_department;
      case 'weather':
      case 'rain':
      case 'flood':
        return Icons.cloud_queue;
      case 'accident':
        return Icons.car_crash;
      case 'event':
      case 'festival':
        return Icons.celebration;
      case 'construction':
      case 'roadwork':
        return Icons.construction;
      case 'police':
        return Icons.local_police;
      case 'medical':
      case 'hospital':
        return Icons.local_hospital;
      case 'protest':
      case 'gathering':
        return Icons.groups;
      case 'power':
      case 'electricity':
        return Icons.flash_on;
      default:
        return Icons.location_on;
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isChatExpanded = !_isChatExpanded;
    });
    
    if (_isChatExpanded) {
      _chatController.forward();
    } else {
      _chatController.reverse();
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    ref.read(chatMessageProvider.notifier).addMessage(message);
    _messageController.clear();

    // Auto-scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1000), () {
      final aiResponse = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _generateAIResponse(text),
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.suggestion,
      );
      ref.read(chatMessageProvider.notifier).addMessage(aiResponse);

      // Auto-scroll to bottom again
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  String _generateAIResponse(String userMessage) {
    if (userMessage.toLowerCase().contains('traffic')) {
      return 'I found some traffic updates near your location. There\'s moderate congestion on MG Road and heavy traffic on Outer Ring Road.';
    } else if (userMessage.toLowerCase().contains('weather')) {
      return 'The weather in Bengaluru today is partly cloudy with a high of 26°C. There\'s a 30% chance of rain in the evening.';
    } else if (userMessage.toLowerCase().contains('events')) {
      return 'Here are some upcoming events in your area: Tech meetup at UB City Mall, Cultural festival at Lalbagh, and a food festival at Brigade Road.';
    } else {
      return 'I\'m here to help you with information about Bengaluru! You can ask me about traffic, weather, events, or any city-related queries.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final chatMessages = ref.watch(chatMessageProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Update events and markers when events change
    eventsAsync.whenData((events) {
      if (_events != events) {
        _events = events;
        _createMarkers();
      }
    });
    
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      body: Stack(
        children: [
          // Full screen map
          Positioned.fill(
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[900] 
                  : Colors.grey[100],
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation != null 
                    ? LatLng(_currentLocation!.lat, _currentLocation!.lng)
                    : const LatLng(12.9716, 77.5946), // Bengaluru coordinates
                  zoom: 15.0,
                ),
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                compassEnabled: true,
                onMapCreated: (GoogleMapController controller) {
                  // Apply dark mode style if needed
                  if (Theme.of(context).brightness == Brightness.dark) {
                    controller.setMapStyle('''[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#212121"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#2c2c2c"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#373737"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#3c3c3c"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#000000"
      }
    ]
  }
]''');
                  }
                  // Move camera to current location with better zoom if available
                  if (_currentLocation != null) {
                    controller.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(_currentLocation!.lat, _currentLocation!.lng),
                          zoom: 15.0, // Better zoom for showing current location
                        ),
                      ),
                    );
                  }
                },
                markers: _markers,
              ),
            ),
          ),
          
          // Collapsible chat interface at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _chatHeightAnimation,
              builder: (context, child) {
                final bottomPadding = MediaQuery.of(context).padding.bottom;
                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  height: _chatHeightAnimation.value + bottomPadding,
                  decoration: BoxDecoration(
                    color: (isDarkMode 
                        ? Theme.of(context).colorScheme.surface 
                        : Colors.white).withOpacity(_chatOpacityAnimation.value),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle and header
                      GestureDetector(
                        onTap: _toggleChat,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Drag handle
                              Container(
                                width: 50,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Chat header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    color: AppTheme.primaryPurple,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ask about your area',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryPurple,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedRotation(
                                    turns: _isChatExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      Icons.keyboard_arrow_up,
                                      color: AppTheme.primaryPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Chat messages (only visible when expanded)
                      if (_isChatExpanded)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: chatMessages.isEmpty
                                ? _buildWelcomeMessageArea()
                                : ListView.builder(
                                    controller: _chatScrollController,
                                    itemCount: chatMessages.length,
                                    itemBuilder: (context, index) {
                                      final message = chatMessages[index];
                                      return _buildChatBubble(message);
                                    },
                                  ),
                          ),
                        ),
                      
                      // Chat input
                      Container(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                bottom: 8 + MediaQuery.of(context).padding.bottom,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                          border: Border(
                            top: BorderSide(
                              color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey[700] : Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Ask about traffic, events, weather...',
                                    hintStyle: GoogleFonts.poppins(
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: _sendMessage,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _sendMessage(_messageController.text),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.primaryPurple, AppTheme.primaryBlue],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryPurple.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(String userName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Colors.white70],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.primaryBlue],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'G',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay updated with real-time city insights',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryPurple, AppTheme.primaryBlue],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 16,
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? const LinearGradient(
                        colors: [AppTheme.primaryPurple, AppTheme.primaryBlue],
                      )
                    : null,
                color: message.isUser ? null : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: message.isUser ? Colors.white : Colors.grey[800],
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (message.isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                color: AppTheme.accentCyan,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessageArea() {
    final userAsync = ref.watch(userProvider);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryPurple, AppTheme.primaryBlue],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPurple.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
            size: 35,
          ),
        ),
        const SizedBox(height: 24),
        userAsync.when(
          data: (user) => Text(
            'Hello ${user.name}! 👋',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryPurple,
            ),
          ),
          loading: () => Text(
            'Hello! 👋',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryPurple,
            ),
          ),
          error: (error, _) => Text(
            'Hello! 👋',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryPurple,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'I\'m your City Pulse Assistant',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ask me about traffic conditions, weather updates,\nevents in your area, or any city-related queries.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        // Suggestion chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSuggestionChip('🚦 Traffic updates', () => _sendMessage('traffic updates')),
            _buildSuggestionChip('🌤️ Weather forecast', () => _sendMessage('weather forecast')),
            _buildSuggestionChip('🎪 Local events', () => _sendMessage('events near me')),
            _buildSuggestionChip('🚨 Emergency alerts', () => _sendMessage('emergency alerts')),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryPurple.withOpacity(0.1), AppTheme.primaryBlue.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryPurple.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryPurple,
          ),
        ),
      ),
    );
  }
}
