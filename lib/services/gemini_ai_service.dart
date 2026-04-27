import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/ai_config.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

/// Comprehensive AI service using Google's Gemini AI
/// Provides intelligent features for trip planning, packing, budgeting, and recommendations
class GeminiAIService {
  late final GenerativeModel _model;
  bool _isInitialized = false;

  GeminiAIService() {
    _initialize();
  }

  void _initialize() {
    if (!AIConfig.isConfigured) {
      print('Warning: Gemini AI is not configured. Please add your API key to ai_config.dart');
      return;
    }

    try {
      _model = GenerativeModel(
        model: AIConfig.geminiModel,
        apiKey: AIConfig.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: AIConfig.temperature,
          maxOutputTokens: AIConfig.maxTokens,
        ),
      );
      _isInitialized = true;
      print('Gemini AI service initialized successfully');
    } catch (e) {
      print('Error initializing Gemini AI: $e');
    }
  }

  bool get isAvailable => _isInitialized && AIConfig.isConfigured;

  // FEATURE 1: AI-Powered Itinerary Generation
  Future<ItineraryResult> generateItinerary({
    required String destination,
    required int durationDays,
    required double budgetPerDay,
    List<String> interests = const [],
    String travelStyle = 'balanced', // 'budget', 'balanced', 'luxury'
  }) async {
    if (!isAvailable) {
      return ItineraryResult(
        success: false,
        error: 'AI service not available',
      );
    }

    try {
      final interestsText = interests.isEmpty
          ? 'general sightseeing and activities'
          : interests.join(', ');

      final prompt = '''You are an expert travel planner. Create a detailed day-by-day itinerary.

Destination: $destination
Duration: $durationDays days
Daily Budget: \$${budgetPerDay.toStringAsFixed(0)}
Interests: $interestsText
Travel Style: $travelStyle

Please provide a JSON response with this exact structure:
{
  "days": [
    {
      "day": 1,
      "title": "Day 1: Arrival and City Exploration",
      "activities": [
        {
          "time": "09:00",
          "activity": "Check-in at hotel",
          "description": "Brief description",
          "estimatedCost": 0,
          "location": "Hotel Name"
        }
      ],
      "dailyBudget": 120,
      "tips": ["Tip 1", "Tip 2"]
    }
  ],
  "totalEstimatedCost": 1200,
  "highlights": ["Must-see attraction 1", "Must-see attraction 2"],
  "tips": ["General travel tip 1", "General travel tip 2"]
}

Make it realistic, practical, and optimized for the budget and interests provided.''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content)
          .timeout(AIConfig.apiTimeout);

      if (response.text == null) {
        return ItineraryResult(
          success: false,
          error: 'No response from AI',
        );
      }

      print('=== AI FULL RESPONSE START ===');
      print(response.text!);
      print('=== AI FULL RESPONSE END ===');
      print('Finish reason: ${response.candidates?.first.finishReason}');
      print('Safety ratings: ${response.candidates?.first.safetyRatings}');

      // Extract JSON from response (handle markdown code blocks)
      String responseText = response.text!;

      // Remove markdown code blocks if present
      responseText = responseText.replaceAll(RegExp(r'```json\s*'), '');
      responseText = responseText.replaceAll(RegExp(r'```\s*'), '');

      // Find JSON object
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch != null) {
        try {
          final jsonData = jsonDecode(jsonMatch.group(0)!);
          return ItineraryResult(
            success: true,
            itinerary: Itinerary.fromJson(jsonData),
          );
        } catch (e) {
          print('JSON parsing error: $e');
          return ItineraryResult(
            success: false,
            error: 'Failed to parse AI response: $e',
          );
        }
      }

      print('No JSON found in response');
      return ItineraryResult(
        success: false,
        error: 'Failed to parse AI response - no valid JSON found',
      );
    } on TimeoutException {
      print('Error generating itinerary: Timeout');
      return ItineraryResult(
        success: false,
        error: 'Request timed out. Please check your internet connection and try again.',
      );
    } on SocketException {
      print('Error generating itinerary: No internet connection');
      return ItineraryResult(
        success: false,
        error: 'No internet connection. Please connect to the internet and try again.',
      );
    } catch (e) {
      print('Error generating itinerary: $e');
      print('Error type: ${e.runtimeType}');
      String errorMessage = 'Failed to generate itinerary: ${e.toString()}';
      if (e.toString().contains('API key') || e.toString().contains('API_KEY')) {
        errorMessage = 'Invalid API key. Please check your configuration.';
      } else if (e.toString().contains('403') || e.toString().contains('401')) {
        errorMessage = 'API authentication failed. Please check your API key.';
      } else if (e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = 'API permission denied. Your API key may not have access to this model.';
      } else if (e.toString().contains('RESOURCE_EXHAUSTED') || e.toString().contains('quota')) {
        errorMessage = 'API quota exceeded. Please check your Gemini API quota.';
      } else if (e.toString().contains('INVALID_ARGUMENT')) {
        errorMessage = 'Invalid request. Please try again or check the model configuration.';
      }
      return ItineraryResult(
        success: false,
        error: errorMessage,
      );
    }
  }

  // FEATURE 2: Smart Packing Suggestions (Enhanced)
  Future<PackingResult> generateSmartPackingList({
    required String destination,
    required int durationDays,
    String? weatherCondition,
    double? temperature,
    List<String> activities = const [],
  }) async {
    if (!isAvailable) {
      return PackingResult(
        success: false,
        error: 'AI service not available',
        items: _getBasicPackingList(),
      );
    }

    try {
      final weatherText = weatherCondition != null && temperature != null
          ? 'Weather: $weatherCondition, ${temperature.toStringAsFixed(1)}°C'
          : 'Weather: Check local forecast';

      final activitiesText = activities.isEmpty
          ? 'general tourism'
          : activities.join(', ');

      final prompt = '''You are a professional packing consultant. Create a comprehensive packing list.

Destination: $destination
Duration: $durationDays days
$weatherText
Planned Activities: $activitiesText

Provide a JSON response with this structure:
{
  "categories": [
    {
      "name": "Clothing",
      "items": [
        {"name": "T-shirts", "quantity": 5, "priority": "essential", "reason": "Daily wear in warm weather"},
        {"name": "Jeans", "quantity": 2, "priority": "recommended", "reason": "Versatile for multiple occasions"}
      ]
    }
  ],
  "tips": ["Packing tip 1", "Packing tip 2"]
}

Priority levels: "essential", "recommended", "optional"
Include specific quantities and reasons for each item.''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content)
          .timeout(AIConfig.apiTimeout);

      if (response.text == null) {
        return PackingResult(
          success: false,
          error: 'No response from AI',
          items: _getBasicPackingList(),
        );
      }

      // Parse JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response.text!);
      if (jsonMatch != null) {
        final jsonData = jsonDecode(jsonMatch.group(0)!);
        return PackingResult(
          success: true,
          packingList: PackingList.fromJson(jsonData),
        );
      }

      return PackingResult(
        success: false,
        error: 'Failed to parse AI response',
        items: _getBasicPackingList(),
      );
    } on TimeoutException {
      print('Error generating packing list: Timeout');
      return PackingResult(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        items: _getBasicPackingList(),
      );
    } on SocketException {
      print('Error generating packing list: No internet');
      return PackingResult(
        success: false,
        error: 'No internet connection. Please connect and try again.',
        items: _getBasicPackingList(),
      );
    } catch (e) {
      print('Error generating packing list: $e');
      String errorMessage = 'Failed to generate packing list';
      if (e.toString().contains('API key') || e.toString().contains('403') || e.toString().contains('401')) {
        errorMessage = 'API authentication failed. Please check your API key.';
      }
      return PackingResult(
        success: false,
        error: errorMessage,
        items: _getBasicPackingList(),
      );
    }
  }

  // FEATURE 3: Budget Predictions Using Spending Patterns
  Future<BudgetPrediction> predictBudget({
    required String destination,
    required int durationDays,
    List<Transaction>? pastTransactions,
    String travelStyle = 'balanced',
  }) async {
    if (!isAvailable) {
      return BudgetPrediction(
        success: false,
        error: 'AI service not available',
      );
    }

    try {
      // Analyze past spending patterns
      String spendingContext = 'No previous spending data available.';
      if (pastTransactions != null && pastTransactions.isNotEmpty) {
        final avgDaily = pastTransactions
            .map((t) => t.amount)
            .reduce((a, b) => a + b) / pastTransactions.length;
        final categories = pastTransactions
            .map((t) => '${t.category}: \$${t.amount.toStringAsFixed(2)}')
            .join(', ');
        spendingContext = 'Average daily spending: \$${avgDaily.toStringAsFixed(2)}. Past expenses: $categories';
      }

      final prompt = '''You are a travel budget expert with extensive knowledge of global travel costs. Predict a REALISTIC budget breakdown based on ACTUAL prices in $destination.

Destination: $destination
Duration: $durationDays days
Travel Style: $travelStyle
$spendingContext

IMPORTANT: Research and use REAL, CURRENT average prices for $destination. Consider:
- Local cost of living and price levels in $destination
- Average accommodation costs (budget hotels, mid-range, hostels)
- Typical meal prices at local restaurants and street food
- Public transportation and taxi costs
- Common tourist activity prices
- The traveler's chosen "$travelStyle" travel style (budget/balanced/luxury)

For reference:
- Budget style: Use hostels, street food, public transport, free activities (30-50 USD/day for cheap destinations, 60-100 USD/day for expensive ones)
- Balanced style: Mid-range hotels, mix of local and tourist restaurants, occasional taxis (80-150 USD/day for cheap destinations, 150-250 USD/day for expensive ones)
- Luxury style: Upscale hotels, fine dining, private transport, premium activities (200-400+ USD/day depending on destination)

Provide a detailed JSON response with REALISTIC amounts:
{
  "totalEstimated": 2500,
  "dailyAverage": 200,
  "breakdown": [
    {"category": "Accommodation", "amount": 800, "percentage": 32},
    {"category": "Food & Dining", "amount": 500, "percentage": 20},
    {"category": "Transportation", "amount": 300, "percentage": 12},
    {"category": "Activities", "amount": 600, "percentage": 24},
    {"category": "Shopping", "amount": 200, "percentage": 8},
    {"category": "Emergency Fund", "amount": 100, "percentage": 4}
  ],
  "savingTips": ["Specific money-saving tips for $destination"],
  "warnings": ["Important budget considerations for $destination"],
  "confidence": 85
}

The total should reflect REAL costs for $destination, not generic estimates. Be accurate and practical.''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content)
          .timeout(AIConfig.apiTimeout);

      if (response.text == null) {
        return BudgetPrediction(
          success: false,
          error: 'No response from AI',
        );
      }

      // Parse JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response.text!);
      if (jsonMatch != null) {
        final jsonData = jsonDecode(jsonMatch.group(0)!);
        return BudgetPrediction(
          success: true,
          budget: BudgetBreakdown.fromJson(jsonData),
        );
      }

      return BudgetPrediction(
        success: false,
        error: 'Failed to parse AI response',
      );
    } on TimeoutException {
      print('Error predicting budget: Timeout');
      return BudgetPrediction(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
      );
    } on SocketException {
      print('Error predicting budget: No internet');
      return BudgetPrediction(
        success: false,
        error: 'No internet connection. Please connect and try again.',
      );
    } catch (e) {
      print('Error predicting budget: $e');
      String errorMessage = 'Failed to predict budget';
      if (e.toString().contains('API key') || e.toString().contains('403') || e.toString().contains('401')) {
        errorMessage = 'API authentication failed. Please check your API key.';
      }
      return BudgetPrediction(
        success: false,
        error: errorMessage,
      );
    }
  }

  // FEATURE 4: Personalized Travel Recommendations
  Future<RecommendationResult> getPersonalizedRecommendations({
    required String destination,
    List<String> interests = const [],
    List<String> pastDestinations = const [],
    String preferredCuisine = '',
    bool includeHiddenGems = true,
  }) async {
    if (!isAvailable) {
      return RecommendationResult(
        success: false,
        error: 'AI service not available',
      );
    }

    try {
      final interestsText = interests.isEmpty ? 'general tourism' : interests.join(', ');
      final pastText = pastDestinations.isEmpty
          ? 'No previous travel history'
          : 'Previously visited: ${pastDestinations.join(', ')}';

      final prompt = '''You are a local travel expert for $destination. Provide personalized recommendations.

Destination: $destination
User Interests: $interestsText
$pastText
Preferred Cuisine: ${preferredCuisine.isEmpty ? 'Open to all' : preferredCuisine}
Include Hidden Gems: $includeHiddenGems

Provide JSON response:
{
  "restaurants": [
    {"name": "Restaurant Name", "cuisine": "Italian", "priceLevel": "\$\$", "rating": 4.5, "why": "Perfect for pasta lovers", "location": "Downtown"}
  ],
  "attractions": [
    {"name": "Attraction", "type": "Museum", "rating": 4.8, "why": "Must-see for history buffs", "estimatedTime": "2-3 hours", "bestTime": "Morning"}
  ],
  "hiddenGems": [
    {"name": "Secret Spot", "type": "Viewpoint", "why": "Locals' favorite sunset spot", "howToFind": "Take bus 42"}
  ],
  "experiences": [
    {"name": "Cooking Class", "type": "Cultural", "duration": "3 hours", "price": 50, "why": "Learn authentic local cuisine"}
  ],
  "tips": ["Local custom 1", "Best time to visit attraction"],
  "warnings": ["Tourist trap to avoid", "Safety consideration"]
}

Focus on authentic, personalized recommendations that match the user's interests.''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content)
          .timeout(AIConfig.apiTimeout);

      if (response.text == null) {
        return RecommendationResult(
          success: false,
          error: 'No response from AI',
        );
      }

      // Parse JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response.text!);
      if (jsonMatch != null) {
        final jsonData = jsonDecode(jsonMatch.group(0)!);
        return RecommendationResult(
          success: true,
          recommendations: TravelRecommendations.fromJson(jsonData),
        );
      }

      return RecommendationResult(
        success: false,
        error: 'Failed to parse AI response',
      );
    } on TimeoutException {
      print('Error getting recommendations: Timeout');
      return RecommendationResult(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
      );
    } on SocketException {
      print('Error getting recommendations: No internet');
      return RecommendationResult(
        success: false,
        error: 'No internet connection. Please connect and try again.',
      );
    } catch (e) {
      print('Error getting recommendations: $e');
      String errorMessage = 'Failed to get recommendations';
      if (e.toString().contains('API key') || e.toString().contains('403') || e.toString().contains('401')) {
        errorMessage = 'API authentication failed. Please check your API key.';
      }
      return RecommendationResult(
        success: false,
        error: errorMessage,
      );
    }
  }

  // Fallback basic packing list
  List<String> _getBasicPackingList() {
    return [
      'Passport & Travel Documents',
      'Phone & Charger',
      'Wallet & Cards',
      'Comfortable Shoes',
      'Weather-Appropriate Clothing',
      'Toiletries',
      'Medications',
      'Sunglasses',
      'Travel Adapter',
      'Reusable Water Bottle',
    ];
  }
}

// Result Models
class ItineraryResult {
  final bool success;
  final Itinerary? itinerary;
  final String? error;

  ItineraryResult({required this.success, this.itinerary, this.error});
}

class PackingResult {
  final bool success;
  final PackingList? packingList;
  final List<String>? items; // Fallback simple list
  final String? error;

  PackingResult({required this.success, this.packingList, this.items, this.error});
}

class BudgetPrediction {
  final bool success;
  final BudgetBreakdown? budget;
  final String? error;

  BudgetPrediction({required this.success, this.budget, this.error});
}

class RecommendationResult {
  final bool success;
  final TravelRecommendations? recommendations;
  final String? error;

  RecommendationResult({required this.success, this.recommendations, this.error});
}

// Data Models
class Itinerary {
  final List<DayPlan> days;
  final double totalEstimatedCost;
  final List<String> highlights;
  final List<String> tips;

  Itinerary({
    required this.days,
    required this.totalEstimatedCost,
    required this.highlights,
    required this.tips,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      days: (json['days'] as List).map((d) => DayPlan.fromJson(d)).toList(),
      totalEstimatedCost: (json['totalEstimatedCost'] ?? 0).toDouble(),
      highlights: List<String>.from(json['highlights'] ?? []),
      tips: List<String>.from(json['tips'] ?? []),
    );
  }
}

class DayPlan {
  final int day;
  final String title;
  final List<Activity> activities;
  final double dailyBudget;
  final List<String> tips;

  DayPlan({
    required this.day,
    required this.title,
    required this.activities,
    required this.dailyBudget,
    required this.tips,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      day: json['day'] ?? 1,
      title: json['title'] ?? '',
      activities: (json['activities'] as List).map((a) => Activity.fromJson(a)).toList(),
      dailyBudget: (json['dailyBudget'] ?? 0).toDouble(),
      tips: List<String>.from(json['tips'] ?? []),
    );
  }
}

class Activity {
  final String time;
  final String activity;
  final String description;
  final double estimatedCost;
  final String location;

  Activity({
    required this.time,
    required this.activity,
    required this.description,
    required this.estimatedCost,
    required this.location,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      time: json['time'] ?? '',
      activity: json['activity'] ?? '',
      description: json['description'] ?? '',
      estimatedCost: (json['estimatedCost'] ?? 0).toDouble(),
      location: json['location'] ?? '',
    );
  }
}

class PackingList {
  final List<PackingCategory> categories;
  final List<String> tips;

  PackingList({required this.categories, required this.tips});

  factory PackingList.fromJson(Map<String, dynamic> json) {
    return PackingList(
      categories: (json['categories'] as List).map((c) => PackingCategory.fromJson(c)).toList(),
      tips: List<String>.from(json['tips'] ?? []),
    );
  }
}

class PackingCategory {
  final String name;
  final List<PackingItem> items;

  PackingCategory({required this.name, required this.items});

  factory PackingCategory.fromJson(Map<String, dynamic> json) {
    return PackingCategory(
      name: json['name'] ?? '',
      items: (json['items'] as List).map((i) => PackingItem.fromJson(i)).toList(),
    );
  }
}

class PackingItem {
  final String name;
  final int quantity;
  final String priority;
  final String reason;

  PackingItem({
    required this.name,
    required this.quantity,
    required this.priority,
    required this.reason,
  });

  factory PackingItem.fromJson(Map<String, dynamic> json) {
    return PackingItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      priority: json['priority'] ?? 'recommended',
      reason: json['reason'] ?? '',
    );
  }
}

class BudgetBreakdown {
  final double totalEstimated;
  final double dailyAverage;
  final List<BudgetCategory> breakdown;
  final List<String> savingTips;
  final List<String> warnings;
  final int confidence;

  BudgetBreakdown({
    required this.totalEstimated,
    required this.dailyAverage,
    required this.breakdown,
    required this.savingTips,
    required this.warnings,
    required this.confidence,
  });

  factory BudgetBreakdown.fromJson(Map<String, dynamic> json) {
    return BudgetBreakdown(
      totalEstimated: (json['totalEstimated'] ?? 0).toDouble(),
      dailyAverage: (json['dailyAverage'] ?? 0).toDouble(),
      breakdown: (json['breakdown'] as List).map((b) => BudgetCategory.fromJson(b)).toList(),
      savingTips: List<String>.from(json['savingTips'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
      confidence: json['confidence'] ?? 0,
    );
  }
}

class BudgetCategory {
  final String category;
  final double amount;
  final int percentage;

  BudgetCategory({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      percentage: json['percentage'] ?? 0,
    );
  }
}

class TravelRecommendations {
  final List<Restaurant> restaurants;
  final List<Attraction> attractions;
  final List<HiddenGem> hiddenGems;
  final List<Experience> experiences;
  final List<String> tips;
  final List<String> warnings;

  TravelRecommendations({
    required this.restaurants,
    required this.attractions,
    required this.hiddenGems,
    required this.experiences,
    required this.tips,
    required this.warnings,
  });

  factory TravelRecommendations.fromJson(Map<String, dynamic> json) {
    return TravelRecommendations(
      restaurants: (json['restaurants'] as List).map((r) => Restaurant.fromJson(r)).toList(),
      attractions: (json['attractions'] as List).map((a) => Attraction.fromJson(a)).toList(),
      hiddenGems: (json['hiddenGems'] as List).map((h) => HiddenGem.fromJson(h)).toList(),
      experiences: (json['experiences'] as List).map((e) => Experience.fromJson(e)).toList(),
      tips: List<String>.from(json['tips'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }
}

class Restaurant {
  final String name;
  final String cuisine;
  final String priceLevel;
  final double rating;
  final String why;
  final String location;

  Restaurant({
    required this.name,
    required this.cuisine,
    required this.priceLevel,
    required this.rating,
    required this.why,
    required this.location,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      name: json['name'] ?? '',
      cuisine: json['cuisine'] ?? '',
      priceLevel: json['priceLevel'] ?? '\$\$',
      rating: (json['rating'] ?? 0).toDouble(),
      why: json['why'] ?? '',
      location: json['location'] ?? '',
    );
  }
}

class Attraction {
  final String name;
  final String type;
  final double rating;
  final String why;
  final String estimatedTime;
  final String bestTime;

  Attraction({
    required this.name,
    required this.type,
    required this.rating,
    required this.why,
    required this.estimatedTime,
    required this.bestTime,
  });

  factory Attraction.fromJson(Map<String, dynamic> json) {
    return Attraction(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      why: json['why'] ?? '',
      estimatedTime: json['estimatedTime'] ?? '',
      bestTime: json['bestTime'] ?? '',
    );
  }
}

class HiddenGem {
  final String name;
  final String type;
  final String why;
  final String howToFind;

  HiddenGem({
    required this.name,
    required this.type,
    required this.why,
    required this.howToFind,
  });

  factory HiddenGem.fromJson(Map<String, dynamic> json) {
    return HiddenGem(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      why: json['why'] ?? '',
      howToFind: json['howToFind'] ?? '',
    );
  }
}

class Experience {
  final String name;
  final String type;
  final String duration;
  final double price;
  final String why;

  Experience({
    required this.name,
    required this.type,
    required this.duration,
    required this.price,
    required this.why,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      duration: json['duration'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      why: json['why'] ?? '',
    );
  }
}

class Transaction {
  final String category;
  final double amount;
  final DateTime date;

  Transaction({
    required this.category,
    required this.amount,
    required this.date,
  });
}
