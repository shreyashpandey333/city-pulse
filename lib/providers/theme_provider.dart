import 'package:flutter_riverpod/flutter_riverpod.dart';

// Dynamic theme provider based on alert levels
final dynamicThemeProvider = StateNotifierProvider<DynamicThemeNotifier, DynamicThemeState>((ref) {
  return DynamicThemeNotifier();
});

// Chat panel state provider
final chatPanelStateProvider = StateNotifierProvider<ChatPanelStateNotifier, ChatPanelState>((ref) {
  return ChatPanelStateNotifier();
});

// Map state provider
final mapStateProvider = StateNotifierProvider<MapStateNotifier, MapState>((ref) {
  return MapStateNotifier();
});

class DynamicThemeState {
  final String alertLevel;
  final String backgroundGif;
  final bool showAlertBackground;

  const DynamicThemeState({
    this.alertLevel = 'none',
    this.backgroundGif = '',
    this.showAlertBackground = false,
  });

  DynamicThemeState copyWith({
    String? alertLevel,
    String? backgroundGif,
    bool? showAlertBackground,
  }) {
    return DynamicThemeState(
      alertLevel: alertLevel ?? this.alertLevel,
      backgroundGif: backgroundGif ?? this.backgroundGif,
      showAlertBackground: showAlertBackground ?? this.showAlertBackground,
    );
  }
}

class ChatPanelState {
  final bool isExpanded;
  final double height;
  final bool isAnimating;

  const ChatPanelState({
    this.isExpanded = false,
    this.height = 0.3,
    this.isAnimating = false,
  });

  ChatPanelState copyWith({
    bool? isExpanded,
    double? height,
    bool? isAnimating,
  }) {
    return ChatPanelState(
      isExpanded: isExpanded ?? this.isExpanded,
      height: height ?? this.height,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }
}

class MapState {
  final double lat;
  final double lng;
  final double zoom;
  final List<MapPin> pins;

  const MapState({
    this.lat = 12.9716,
    this.lng = 77.5946,
    this.zoom = 11.0,
    this.pins = const [],
  });

  MapState copyWith({
    double? lat,
    double? lng,
    double? zoom,
    List<MapPin>? pins,
  }) {
    return MapState(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      zoom: zoom ?? this.zoom,
      pins: pins ?? this.pins,
    );
  }
}

class MapPin {
  final String id;
  final double lat;
  final double lng;
  final String eventType;
  final String title;
  final String description;

  const MapPin({
    required this.id,
    required this.lat,
    required this.lng,
    required this.eventType,
    required this.title,
    required this.description,
  });
}

class DynamicThemeNotifier extends StateNotifier<DynamicThemeState> {
  DynamicThemeNotifier() : super(const DynamicThemeState());

  void updateThemeForAlert(String alertType, String severity) {
    final shouldShowBackground = severity == 'High' || severity == 'high';
    
    String backgroundGif = '';
    if (shouldShowBackground) {
      switch (alertType.toLowerCase()) {
        case 'thunderstorm':
        case 'thunder':
          backgroundGif = 'assets/lottie/thunderstorm.json';
          break;
        case 'rain':
        case 'flood':
          backgroundGif = 'assets/lottie/rain.json';
          break;
        case 'fire':
          backgroundGif = 'assets/lottie/fire.json';
          break;
      }
    }

    state = state.copyWith(
      alertLevel: severity,
      backgroundGif: backgroundGif,
      showAlertBackground: shouldShowBackground && backgroundGif.isNotEmpty,
    );
  }

  void clearAlert() {
    state = const DynamicThemeState();
  }
}

class ChatPanelStateNotifier extends StateNotifier<ChatPanelState> {
  ChatPanelStateNotifier() : super(const ChatPanelState());

  void toggleExpanded() {
    state = state.copyWith(
      isExpanded: !state.isExpanded,
      height: state.isExpanded ? 0.3 : 0.7,
      isAnimating: true,
    );
  }

  void setHeight(double height) {
    state = state.copyWith(height: height);
  }

  void setAnimating(bool animating) {
    state = state.copyWith(isAnimating: animating);
  }
}

class MapStateNotifier extends StateNotifier<MapState> {
  MapStateNotifier() : super(const MapState());

  void updateLocation(double lat, double lng, {double? zoom}) {
    state = state.copyWith(
      lat: lat,
      lng: lng,
      zoom: zoom ?? state.zoom,
    );
  }

  void updatePins(List<MapPin> pins) {
    state = state.copyWith(pins: pins);
  }

  void addPin(MapPin pin) {
    state = state.copyWith(pins: [...state.pins, pin]);
  }

  void removePin(String id) {
    state = state.copyWith(
      pins: state.pins.where((pin) => pin.id != id).toList(),
    );
  }
}
