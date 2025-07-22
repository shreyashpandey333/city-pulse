import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Replace with actual Gemini API implementation
final geminiServiceProvider = Provider((ref) => GeminiService());

class GeminiService {
  // Mock responses for now - TODO: Integrate real Gemini API
  Future<String> getResponse(String userMessage) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final query = userMessage.toLowerCase();
    
    // Mock AI responses based on keywords
    if (query.contains('traffic') || query.contains('road')) {
      return _getTrafficResponse();
    } else if (query.contains('weather') || query.contains('rain') || query.contains('storm')) {
      return _getWeatherResponse();
    } else if (query.contains('events') || query.contains('happening')) {
      return _getEventsResponse();
    } else if (query.contains('fire') || query.contains('emergency')) {
      return _getEmergencyResponse();
    } else if (query.contains('power') || query.contains('electricity')) {
      return _getPowerResponse();
    } else if (query.contains('water') || query.contains('supply')) {
      return _getWaterResponse();
    } else {
      return _getGeneralResponse();
    }
  }

  String _getTrafficResponse() {
    final responses = [
      "🚦 Current traffic update:\n• Heavy congestion on MG Road (15-20 min delay)\n• Outer Ring Road is experiencing moderate traffic\n• Alternative: Use Airport Road for faster travel",
      "🛣️ Traffic Status:\n• Koramangala to Indiranagar: 25 mins\n• Whitefield Main Road: Construction work causing delays\n• Tip: Avoid Brigade Road area between 5-7 PM",
      "🚗 Live Traffic Alert:\n• Electronic City Flyover: Smooth\n• Hebbal Junction: Heavy traffic reported\n• Suggested route: Use service roads for quicker transit",
    ];
    return responses[DateTime.now().second % responses.length];
  }

  String _getWeatherResponse() {
    final responses = [
      "🌤️ Today's Weather:\n• Temperature: 26°C\n• Partly cloudy with 30% chance of rain\n• Evening thunderstorms possible\n• Carry an umbrella just in case!",
      "🌧️ Weather Update:\n• Light rain expected in 2 hours\n• Temperature dropping to 24°C\n• High humidity levels\n• Perfect weather for indoor activities",
      "⛈️ Storm Alert:\n• Thunderstorm warning active\n• Heavy rain expected between 6-8 PM\n• Stay indoors if possible\n• Monitor BBMP updates for waterlogging",
    ];
    return responses[DateTime.now().second % responses.length];
  }

  String _getEventsResponse() {
    final responses = [
      "🎉 Nearby Events:\n• Tech Meetup at UB City Mall (6 PM)\n• Cultural Festival at Lalbagh (All day)\n• Food Festival on Brigade Road (Weekend)\n• Art Exhibition at National Gallery",
      "📅 This Weekend:\n• Bangalore Comic Con at BIEC\n• Sunday Market at Russell Market\n• Classical Concert at Chowdiah Hall\n• Cycling event at Cubbon Park",
      "🎪 Local Happenings:\n• Street Food Festival (Indiranagar)\n• Open Mic Night at Toit (8 PM)\n• Photography Walk (Cubbon Park)\n• Book Reading at Blossoms",
    ];
    return responses[DateTime.now().second % responses.length];
  }

  String _getEmergencyResponse() {
    final responses = [
      "🚨 Emergency Services:\n• Fire: 101\n• Police: 100\n• Ambulance: 108\n• If you're reporting an incident, please share your exact location for faster response.",
      "🔥 Fire Safety Alert:\n• Fire reported in Indiranagar area\n• Fire department on site\n• Avoid the area if possible\n• Always have emergency contacts handy",
      "🆘 Emergency Protocol:\n• Stay calm and assess the situation\n• Call appropriate emergency number\n• Share precise location details\n• Follow local authority instructions",
    ];
    return responses[DateTime.now().second % responses.length];
  }

  String _getPowerResponse() {
    final responses = [
      "⚡ Power Status:\n• HSR Layout: Scheduled maintenance (2-5 PM)\n• Koramangala: Normal supply\n• For outage reports, contact BESCOM: 1912\n• Estimated restoration: 3 hours",
      "🔌 Electricity Update:\n• Planned outage in Whitefield today\n• Backup power recommended\n• BESCOM helpline: 1912\n• Mobile app available for real-time updates",
      "💡 Power Alert:\n• Unexpected outage in BTM Layout\n• Technical team dispatched\n• Expected restoration: Within 2 hours\n• Report issues through BESCOM portal",
    ];
    return responses[DateTime.now().second % responses.length];
  }

  String _getWaterResponse() {
    final responses = [
      "💧 Water Supply:\n• Regular supply in most areas\n• Tanker service available in HSR Layout\n• BWSSB helpline: 1916\n• Conserve water during peak summer",
      "🚰 Water Status:\n• Low pressure in Indiranagar\n• Normal supply expected by evening\n• Store water during morning hours\n• Report leakages to BWSSB immediately",
      "💦 Water Advisory:\n• Boil water before consumption\n• Quality testing in progress\n• Use water purifiers as precaution\n• Contact BWSSB for any concerns",
    ];
    return responses[DateTime.now().second % responses.length];
  }

  String _getGeneralResponse() {
    final responses = [
      "🏙️ Hey there! I'm your Bengaluru City Assistant. I can help you with:\n• Traffic updates and routes\n• Weather forecasts\n• Local events and activities\n• Emergency services info\n• City service updates",
      "✨ How can I help you today?\n• Ask about traffic conditions\n• Get weather updates\n• Find local events\n• Emergency contact info\n• Report city issues",
      "🚀 I'm here to make your Bengaluru experience better! Try asking me:\n• 'Traffic to Airport?'\n• 'Weather today?'\n• 'Events this weekend?'\n• 'Emergency numbers?'",
    ];
    return responses[DateTime.now().second % responses.length];
  }

  // TODO: Implement actual Gemini Vision API for image analysis
  Future<Map<String, dynamic>> analyzeImageWithGemini(String imagePath) async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock response - replace with actual Gemini Vision API call
    final categories = ['Traffic Jam', 'Flood', 'Road Closure', 'Power Outage', 'Fire'];
    final randomCategory = categories[DateTime.now().millisecond % categories.length];
    
    return {
      'category': randomCategory,
      'confidence': 0.85 + (DateTime.now().millisecond % 15) / 100,
      'description': 'AI-detected $randomCategory in the uploaded image',
      'location_context': 'Bengaluru city area',
      'suggestions': [
        'Report this incident to authorities',
        'Share with nearby community',
        'Monitor for updates',
      ],
    };
  }
}
