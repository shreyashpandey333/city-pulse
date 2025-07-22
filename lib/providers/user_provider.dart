import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/event.dart';

// User state provider
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<User>>((ref) {
  return UserNotifier();
});

// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});

// Bottom navigation provider
final bottomNavProvider = StateNotifierProvider<BottomNavNotifier, int>((ref) {
  return BottomNavNotifier();
});

class UserNotifier extends StateNotifier<AsyncValue<User>> {
  UserNotifier() : super(const AsyncValue.loading()) {
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      state = const AsyncValue.loading();
      
      // Get current Firebase Auth user
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      
      if (firebaseUser != null) {
        // Try to get user data from Firestore first
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        
        User user;
        if (userDoc.exists) {
          // User exists in Firestore, use that data but update with latest Firebase Auth info
          final userData = userDoc.data()!;
          user = User(
            userId: firebaseUser.uid,
            name: firebaseUser.displayName ?? userData['name'] ?? 'User',
            email: firebaseUser.email ?? userData['email'] ?? 'user@example.com',
            location: Location(
              lat: userData['location']?['lat'] ?? 12.9716,
              lng: userData['location']?['lng'] ?? 77.5946,
              address: userData['location']?['address'] ?? 'Bengaluru, Karnataka',
            ),
            preferences: UserPreferences(
              alertRadius: userData['preferences']?['alertRadius']?.toDouble() ?? 5.0,
              categories: List<String>.from(userData['preferences']?['categories'] ?? ['Traffic', 'Emergency']),
              notificationEnabled: userData['preferences']?['notificationEnabled'] ?? true,
              darkMode: userData['preferences']?['darkMode'] ?? false,
            ),
            reputation: userData['reputation'] ?? 0,
            reportsSubmitted: userData['reportsSubmitted'] ?? 0,
          );
        } else {
          // New user, create with Firebase Auth data and default preferences
          user = User(
            userId: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? 'user@example.com',
            location: Location(
              lat: 12.9716,
              lng: 77.5946,
              address: 'Bengaluru, Karnataka',
            ),
            preferences: UserPreferences(
              alertRadius: 5.0,
              categories: ['Traffic', 'Emergency'],
              notificationEnabled: true,
              darkMode: false,
            ),
            reputation: 0,
            reportsSubmitted: 0,
          );
          
          // Save new user to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .set({
            'uid': user.userId,
            'name': user.name,
            'email': user.email,
            'location': {
              'lat': user.location.lat,
              'lng': user.location.lng,
              'address': user.location.address,
            },
            'preferences': {
              'alertRadius': user.preferences.alertRadius,
              'categories': user.preferences.categories,
              'notificationEnabled': user.preferences.notificationEnabled,
              'darkMode': user.preferences.darkMode,
            },
            'reputation': user.reputation,
            'reportsSubmitted': user.reportsSubmitted,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        
        state = AsyncValue.data(user);
        print('User loaded successfully: ${user.name}');
      } else {
        // No Firebase user, create guest user
        final guestUser = User(
          userId: 'guest_user',
          name: 'Guest User',
          email: 'guest@example.com',
          location: Location(
            lat: 12.9716,
            lng: 77.5946,
            address: 'Bengaluru, Karnataka',
          ),
          preferences: UserPreferences(
            alertRadius: 5.0,
            categories: ['Traffic', 'Emergency'],
            notificationEnabled: true,
            darkMode: false,
          ),
          reputation: 0,
          reportsSubmitted: 0,
        );
        state = AsyncValue.data(guestUser);
        print('No Firebase user, using guest user');
      }
    } catch (error, stackTrace) {
      print('Error loading user: $error');
      print('Stack trace: $stackTrace');
      
      // Create a fallback user to prevent app from breaking
      final fallbackUser = User(
        userId: 'fallback_user',
        name: 'Guest User',
        email: 'guest@example.com',
        location: Location(
          lat: 12.9716,
          lng: 77.5946,
          address: 'Bengaluru, Karnataka',
        ),
        preferences: UserPreferences(
          alertRadius: 5.0,
          categories: ['Traffic', 'Emergency'],
          notificationEnabled: true,
          darkMode: false,
        ),
        reputation: 0,
        reportsSubmitted: 0,
      );
      state = AsyncValue.data(fallbackUser);
      print('Using fallback user data');
    }
  }

  Future<void> updateUserPreferences(UserPreferences preferences) async {
    state.whenData((user) async {
      final updatedUser = User(
        userId: user.userId,
        name: user.name,
        email: user.email,
        location: user.location,
        preferences: preferences,
        reputation: user.reputation,
        reportsSubmitted: user.reportsSubmitted,
      );
      
      // Update in Firestore if user is authenticated
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .update({
            'preferences': {
              'alertRadius': preferences.alertRadius,
              'categories': preferences.categories,
              'notificationEnabled': preferences.notificationEnabled,
              'darkMode': preferences.darkMode,
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          print('Error updating user preferences in Firestore: $e');
        }
      }
      
      state = AsyncValue.data(updatedUser);
    });
  }
}

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false); // false = light theme, true = dark theme

  void toggleTheme() {
    state = !state;
  }

  void setTheme(bool isDark) {
    state = isDark;
  }
}

class BottomNavNotifier extends StateNotifier<int> {
  BottomNavNotifier() : super(0); // Default to Dashboard

  void setIndex(int index) {
    state = index;
  }
}
