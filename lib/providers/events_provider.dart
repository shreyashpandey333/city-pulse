import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../services/alert_service.dart';
import '../services/location_service.dart';

// Events state provider
final eventsProvider = StateNotifierProvider<EventsNotifier, AsyncValue<List<Event>>>((ref) {
  return EventsNotifier();
});

// Filter state provider
final eventFiltersProvider = StateNotifierProvider<EventFiltersNotifier, EventFilters>((ref) {
  return EventFiltersNotifier();
});

// Filtered events provider
final filteredEventsProvider = Provider<AsyncValue<List<Event>>>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  final filters = ref.watch(eventFiltersProvider);
  
  return eventsAsync.when(
    data: (events) {
      List<Event> filteredEvents = events;
      
      // Filter by category
      if (filters.selectedCategories.isNotEmpty) {
        filteredEvents = filteredEvents.where((event) {
          return filters.selectedCategories.contains(event.category);
        }).toList();
      }
      
      // Filter by severity
      if (filters.selectedSeverities.isNotEmpty) {
        filteredEvents = filteredEvents.where((event) {
          return filters.selectedSeverities.contains(event.severity);
        }).toList();
      }
      
      // Sort by timestamp (newest first)
      filteredEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return AsyncValue.data(filteredEvents);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

class EventsNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  EventsNotifier() : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      state = const AsyncValue.loading();
      
      // Get current location
      final location = await LocationService.getCurrentLocation();
      if (location == null) {
        state = AsyncValue.error('Unable to get current location', StackTrace.current);
        return;
      }
      
      // Get events from AlertService (NDMA API)
      final alertService = AlertService();
      final events = await alertService.getNdmaAlertsForLocation(
        latitude: location.lat,
        longitude: location.lng,
        radiusKm: 10.0, // Default radius
      );
      
      state = AsyncValue.data(events);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshEvents() async {
    await loadEvents();
  }
}

class EventFiltersNotifier extends StateNotifier<EventFilters> {
  EventFiltersNotifier() : super(EventFilters());

  void updateCategories(List<String> categories) {
    state = state.copyWith(selectedCategories: categories);
  }

  void updateSeverities(List<String> severities) {
    state = state.copyWith(selectedSeverities: severities);
  }

  void updateRadius(double radius) {
    state = state.copyWith(radius: radius);
  }

  void clearFilters() {
    state = EventFilters();
  }
}

class EventFilters {
  final List<String> selectedCategories;
  final List<String> selectedSeverities;
  final double radius;

  EventFilters({
    this.selectedCategories = const [],
    this.selectedSeverities = const [],
    this.radius = 10.0,
  });

  EventFilters copyWith({
    List<String>? selectedCategories,
    List<String>? selectedSeverities,
    double? radius,
  }) {
    return EventFilters(
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedSeverities: selectedSeverities ?? this.selectedSeverities,
      radius: radius ?? this.radius,
    );
  }
}
