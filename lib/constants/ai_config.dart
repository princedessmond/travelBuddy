/// AI Configuration for Travel Companion App
///
/// This file contains API keys and configuration for AI services.
/// Note: In production, API keys should be stored in environment variables
/// or secure key management services, not hardcoded in source code.

class AIConfig {
  // Google Gemini API Key
  // Get your free API key from: https://makersuite.google.com/app/apikey
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';

  // Model configurations
  static const String geminiModel = 'gemini-flash-latest';
  static const int maxTokens = 8192; // Increased for longer itineraries
  static const double temperature = 0.7;

  // Feature flags
  static const bool enableAIItinerary = true;
  static const bool enableAIPacking = true;
  static const bool enableAIBudget = true;
  static const bool enableAIRecommendations = true;

  // API timeouts
  static const Duration apiTimeout = Duration(seconds: 30);

  // Validate if AI services are properly configured
  static bool get isConfigured {
    return geminiApiKey.isNotEmpty &&
           geminiApiKey != 'YOUR_GEMINI_API_KEY_HERE';
  }
}
