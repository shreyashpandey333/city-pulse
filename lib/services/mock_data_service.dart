import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/event.dart';
import '../models/user.dart';

class MockDataService {
  static const String _mockDataPath = 'assets/mock_data/events.json';
  
  static Future<List<Event>> getEvents() async {
    try {
      final String response = await rootBundle.loadString(_mockDataPath);
      final Map<String, dynamic> data = json.decode(response);
      
      final List<dynamic> eventsList = data['events'];
      return eventsList.map((event) => Event.fromJson(event)).toList();
    } catch (e) {
      print('Error loading events: $e');
      return [];
    }
  }
  
  static Future<User> getUser() async {
    try {
      final String response = await rootBundle.loadString(_mockDataPath);
      final Map<String, dynamic> data = json.decode(response);
      
      return User.fromJson(data['user']);
    } catch (e) {
      print('Error loading user: $e');
      rethrow;
    }
  }
  
  static Future<List<EventCategory>> getCategories() async {
    try {
      final String response = await rootBundle.loadString(_mockDataPath);
      final Map<String, dynamic> data = json.decode(response);
      
      final List<dynamic> categoriesList = data['categories'];
      return categoriesList.map((category) => EventCategory.fromJson(category)).toList();
    } catch (e) {
      print('Error loading categories: $e');
      return [];
    }
  }
  
  // Simulate real-time updates
  static Stream<List<Event>> getEventsStream() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      yield await getEvents();
    }
  }
  
  // Simulate Gemini Vision API response
  static Future<Map<String, dynamic>> analyzeImageWithGemini(String imagePath) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock response based on random category
    final categories = ['Traffic Jam', 'Flood', 'Road Closure', 'Power Outage', 'Construction'];
    final randomCategory = categories[DateTime.now().millisecond % categories.length];
    
    return {
      'category': randomCategory,
      'confidence': 0.85 + (DateTime.now().millisecond % 15) / 100,
      'description': 'AI-detected $randomCategory in the uploaded image',
      'location_context': 'Bengaluru city area',
    };
  }
}
