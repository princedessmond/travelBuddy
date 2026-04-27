import 'package:http/http.dart' as http;
import 'dart:convert';

class AIPackingService {
  // TODO: Replace with your Anthropic API key from https://console.anthropic.com/
  static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY_HERE';
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';

  // Smart packing suggestions using Claude AI
  Future<List<String>> getSmartPackingSuggestions({
    required String destination,
    String? weatherCondition,
    double? temperature,
    int? tripDurationDays,
  }) async {
    try {
      // Build context for Claude
      String weatherContext = '';
      if (weatherCondition != null && temperature != null) {
        weatherContext = 'The weather is $weatherCondition with a temperature of ${temperature.toStringAsFixed(1)}°C.';
      }

      String durationContext = tripDurationDays != null
          ? 'The trip will last $tripDurationDays days.'
          : 'Trip duration is not specified.';

      final prompt = '''You are a helpful travel packing assistant. Generate a practical packing list for a trip.

Destination: $destination
$weatherContext
$durationContext

Please provide a comprehensive but concise packing list. Return ONLY a JSON array of item names (strings), no explanations or additional text.

Example format: ["Passport", "Phone charger", "Sunscreen", "T-shirts"]

Focus on essentials and items specific to the destination and weather. Limit to 15-20 most important items.''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('AI request timed out');
        },
      );

      print('Claude API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;

        print('Claude AI Response: $content');

        // Parse the JSON array from the response
        try {
          // Extract JSON array from the response
          final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(content);
          if (jsonMatch != null) {
            final jsonArray = jsonMatch.group(0)!;
            final List<dynamic> items = jsonDecode(jsonArray);
            return items.map((item) => item.toString()).toList();
          }
        } catch (e) {
          print('Error parsing AI response: $e');
        }

        // Fallback to basic suggestions if parsing fails
        return _getBasicSuggestions(destination, weatherCondition, temperature, tripDurationDays);
      } else {
        print('Claude API error: ${response.statusCode} - ${response.body}');
        return _getBasicSuggestions(destination, weatherCondition, temperature, tripDurationDays);
      }
    } catch (e, stackTrace) {
      print('Error getting AI packing suggestions: $e');
      print('Stack trace: $stackTrace');
      // Fallback to basic suggestions on error
      return _getBasicSuggestions(destination, weatherCondition, temperature, tripDurationDays);
    }
  }

  // Fallback basic suggestions
  List<String> _getBasicSuggestions(
    String destination,
    String? weatherCondition,
    double? temperature,
    int? tripDurationDays,
  ) {
    final suggestions = <String>{};

    // Essential items everyone needs
    suggestions.addAll([
      'Passport',
      'Phone charger',
      'Travel adapter',
      'Toiletries bag',
      'Medications',
      'Sunglasses',
      'Reusable water bottle',
    ]);

    // Weather-based suggestions
    if (weatherCondition != null && temperature != null) {
      suggestions.addAll(_getWeatherSuggestions(weatherCondition, temperature));
    }

    // Duration-based suggestions
    if (tripDurationDays != null) {
      suggestions.addAll(_getDurationSuggestions(tripDurationDays));
    }

    // Destination-specific suggestions
    suggestions.addAll(_getDestinationSuggestions(destination));

    return suggestions.toList();
  }

  List<String> _getWeatherSuggestions(String condition, double temp) {
    final suggestions = <String>[];

    // Temperature-based
    if (temp < 10) {
      suggestions.addAll([
        'Winter coat',
        'Thermal underwear',
        'Warm socks',
        'Gloves',
        'Scarf',
        'Beanie',
        'Hand warmers',
      ]);
    } else if (temp < 20) {
      suggestions.addAll([
        'Light jacket',
        'Long pants',
        'Sweater',
        'Closed-toe shoes',
      ]);
    } else if (temp >= 25) {
      suggestions.addAll([
        'Shorts',
        'T-shirts',
        'Sandals',
        'Sunscreen SPF 50+',
        'Sun hat',
        'Light dress',
        'Swimsuit',
      ]);
    }

    // Condition-based
    final lowerCondition = condition.toLowerCase();
    if (lowerCondition.contains('rain') || lowerCondition.contains('shower')) {
      suggestions.addAll([
        'Umbrella',
        'Rain jacket',
        'Waterproof shoes',
        'Quick-dry clothes',
      ]);
    }

    if (lowerCondition.contains('snow')) {
      suggestions.addAll([
        'Snow boots',
        'Waterproof pants',
        'Thick gloves',
        'Ski goggles',
      ]);
    }

    if (lowerCondition.contains('sun') || lowerCondition.contains('clear')) {
      suggestions.addAll([
        'Sunscreen',
        'After-sun lotion',
        'Light breathable clothes',
      ]);
    }

    return suggestions;
  }

  List<String> _getDurationSuggestions(int days) {
    final suggestions = <String>[];

    if (days >= 7) {
      suggestions.addAll([
        'Laundry detergent',
        'Extra underwear',
        'Portable clothesline',
      ]);
    }

    if (days >= 14) {
      suggestions.addAll([
        'First aid kit',
        'Extra toiletries',
        'Backup phone charger',
      ]);
    }

    // Clothing quantities
    final shirts = (days / 2).ceil();
    suggestions.add('$shirts casual shirts');

    if (days > 3) {
      suggestions.add('${(days / 3).ceil()} pairs of jeans/pants');
    }

    return suggestions;
  }

  List<String> _getDestinationSuggestions(String destination) {
    final suggestions = <String>[];
    final lower = destination.toLowerCase();

    // Beach destinations
    if (_isBeachDestination(lower)) {
      suggestions.addAll([
        'Beach towel',
        'Flip flops',
        'Beach bag',
        'Snorkel gear',
        'Waterproof phone case',
      ]);
    }

    // Mountain/hiking destinations
    if (_isMountainDestination(lower)) {
      suggestions.addAll([
        'Hiking boots',
        'Backpack',
        'Trekking poles',
        'First aid kit',
        'Insect repellent',
      ]);
    }

    // City destinations
    if (_isCityDestination(lower)) {
      suggestions.addAll([
        'Comfortable walking shoes',
        'Day backpack',
        'Camera',
        'Portable charger',
        'City guidebook',
      ]);
    }

    // Cold climate destinations
    if (_isColdDestination(lower)) {
      suggestions.addAll([
        'Thermal layers',
        'Winter boots',
        'Lip balm',
        'Moisturizer',
      ]);
    }

    // Tropical destinations
    if (_isTropicalDestination(lower)) {
      suggestions.addAll([
        'Insect repellent',
        'Light cotton clothes',
        'Mosquito net',
        'Anti-malaria medication',
      ]);
    }

    // Religious/cultural sites
    if (_isConservativeDestination(lower)) {
      suggestions.addAll([
        'Modest clothing',
        'Scarf/shawl',
        'Long pants',
        'Covered shoes',
      ]);
    }

    return suggestions;
  }

  bool _isBeachDestination(String destination) {
    const beaches = [
      'maldives', 'bali', 'hawaii', 'fiji', 'seychelles', 'mauritius',
      'thailand', 'miami', 'cancun', 'bora bora', 'zanzibar', 'phuket'
    ];
    return beaches.any((beach) => destination.contains(beach));
  }

  bool _isMountainDestination(String destination) {
    const mountains = [
      'nepal', 'switzerland', 'tibet', 'peru', 'patagonia',
      'norway', 'iceland', 'bhutan', 'colorado'
    ];
    return mountains.any((mountain) => destination.contains(mountain));
  }

  bool _isCityDestination(String destination) {
    const cities = [
      'paris', 'london', 'new york', 'tokyo', 'rome', 'barcelona',
      'amsterdam', 'berlin', 'sydney', 'dubai', 'singapore'
    ];
    return cities.any((city) => destination.contains(city));
  }

  bool _isColdDestination(String destination) {
    const cold = [
      'iceland', 'norway', 'finland', 'sweden', 'russia', 'alaska',
      'canada', 'greenland', 'antarctica', 'siberia'
    ];
    return cold.any((place) => destination.contains(place));
  }

  bool _isTropicalDestination(String destination) {
    const tropical = [
      'brazil', 'costa rica', 'malaysia', 'indonesia', 'philippines',
      'vietnam', 'cambodia', 'sri lanka', 'madagascar'
    ];
    return tropical.any((place) => destination.contains(place));
  }

  bool _isConservativeDestination(String destination) {
    const conservative = [
      'saudi arabia', 'iran', 'dubai', 'abu dhabi', 'qatar', 'egypt',
      'morocco', 'india', 'pakistan', 'jordan', 'vatican'
    ];
    return conservative.any((place) => destination.contains(place));
  }
}
