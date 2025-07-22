import 'event.dart';

class User {
  final String userId;
  final String name;
  final String email;
  final Location location;
  final UserPreferences preferences;
  final int reputation;
  final int reportsSubmitted;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.location,
    required this.preferences,
    required this.reputation,
    required this.reportsSubmitted,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      location: Location.fromJson(json['location'] ?? {}),
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      reputation: json['reputation'] ?? 0,
      reportsSubmitted: json['reportsSubmitted'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'location': location.toJson(),
      'preferences': preferences.toJson(),
      'reputation': reputation,
      'reportsSubmitted': reportsSubmitted,
    };
  }
}

class UserPreferences {
  final double alertRadius;
  final List<String> categories;
  final bool notificationEnabled;
  final bool darkMode;

  UserPreferences({
    required this.alertRadius,
    required this.categories,
    required this.notificationEnabled,
    required this.darkMode,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      alertRadius: (json['alertRadius'] ?? 5.0).toDouble(),
      categories: List<String>.from(json['categories'] ?? []),
      notificationEnabled: json['notificationEnabled'] ?? true,
      darkMode: json['darkMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertRadius': alertRadius,
      'categories': categories,
      'notificationEnabled': notificationEnabled,
      'darkMode': darkMode,
    };
  }

  UserPreferences copyWith({
    double? alertRadius,
    List<String>? categories,
    bool? notificationEnabled,
    bool? darkMode,
  }) {
    return UserPreferences(
      alertRadius: alertRadius ?? this.alertRadius,
      categories: categories ?? this.categories,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

class EventCategory {
  final String id;
  final String name;
  final String icon;
  final String color;

  EventCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
    };
  }
}
