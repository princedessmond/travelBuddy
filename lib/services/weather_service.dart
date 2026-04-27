import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final double feelsLike;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final String main; // e.g., "Rain", "Clear", "Clouds"

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.main,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      humidity: json['main']['humidity'],
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      main: json['weather'][0]['main'],
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  String get temperatureCelsius => '${temperature.toStringAsFixed(1)}�C';
  String get temperatureFahrenheit =>
      '${(temperature * 9 / 5 + 32).toStringAsFixed(1)}�F';
}

class ForecastData {
  final DateTime dateTime;
  final double temperature;
  final String description;
  final String icon;
  final String main;

  ForecastData({
    required this.dateTime,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.main,
  });

  factory ForecastData.fromJson(Map<String, dynamic> json) {
    return ForecastData(
      dateTime: DateTime.parse(json['dt_txt']),
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      main: json['weather'][0]['main'],
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';
  String get temperatureCelsius => '${temperature.toStringAsFixed(1)}�C';
}

class WeatherService {
  // OpenWeatherMap API - Free tier: 60 calls/minute, 1,000,000 calls/month
  static const String _apiKey = '49d29d5e3cfe1c6cc60eafea8f172fa2';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Singleton pattern
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  WeatherData? _cachedWeather;
  String? _cachedCity;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Get current weather for a city
  Future<WeatherData?> getCurrentWeather(String cityName) async {
    try {
      // Check cache
      if (_isCacheValid(cityName)) {
        return _cachedWeather;
      }

      final url = Uri.parse(
        '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final weather = WeatherData.fromJson(data);

        // Cache the result
        _cachedWeather = weather;
        _cachedCity = cityName;
        _cacheTime = DateTime.now();

        return weather;
      } else {
        print('Failed to fetch weather: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }

  /// Get 5-day weather forecast (3-hour intervals)
  Future<List<ForecastData>> getWeatherForecast(String cityName) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?q=$cityName&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['list'];

        return list.map((json) => ForecastData.fromJson(json)).toList();
      } else {
        print('Failed to fetch forecast: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching forecast: $e');
      return [];
    }
  }

  /// Get daily forecast (one per day at noon)
  Future<List<ForecastData>> getDailyForecast(String cityName) async {
    try {
      final allForecasts = await getWeatherForecast(cityName);

      // Filter to get one forecast per day (around noon)
      final dailyForecasts = <ForecastData>[];
      String? lastDate;

      for (final forecast in allForecasts) {
        final dateStr = forecast.dateTime.toString().split(' ')[0];
        final hour = forecast.dateTime.hour;

        // Take the forecast closest to noon each day
        if (dateStr != lastDate && hour >= 11 && hour <= 13) {
          dailyForecasts.add(forecast);
          lastDate = dateStr;
        }
      }

      return dailyForecasts;
    } catch (e) {
      print('Error getting daily forecast: $e');
      return [];
    }
  }

  /// Get weather-based packing suggestions
  List<String> getPackingSuggestions(WeatherData weather) {
    final suggestions = <String>[];

    // Temperature-based suggestions
    if (weather.temperature < 10) {
      suggestions.addAll([
        'Winter coat',
        'Warm sweaters',
        'Thermal underwear',
        'Gloves',
        'Scarf',
        'Winter hat',
      ]);
    } else if (weather.temperature < 20) {
      suggestions.addAll([
        'Light jacket',
        'Long pants',
        'Sweater',
      ]);
    } else {
      suggestions.addAll([
        'Light clothing',
        'Shorts',
        'T-shirts',
        'Sunglasses',
        'Sunscreen',
        'Hat',
      ]);
    }

    // Weather condition-based suggestions
    if (weather.main.toLowerCase().contains('rain') ||
        weather.description.toLowerCase().contains('rain')) {
      suggestions.addAll([
        'Umbrella',
        'Rain jacket',
        'Waterproof shoes',
      ]);
    }

    if (weather.main.toLowerCase().contains('snow')) {
      suggestions.addAll([
        'Snow boots',
        'Waterproof pants',
        'Hand warmers',
      ]);
    }

    // Humidity-based suggestions
    if (weather.humidity > 70) {
      suggestions.add('Breathable clothing');
    }

    return suggestions;
  }

  /// Check if cache is still valid
  bool _isCacheValid(String city) {
    if (_cachedWeather == null ||
        _cachedCity != city ||
        _cacheTime == null) {
      return false;
    }

    final now = DateTime.now();
    return now.difference(_cacheTime!) < _cacheDuration;
  }

  /// Clear cache
  void clearCache() {
    _cachedWeather = null;
    _cachedCity = null;
    _cacheTime = null;
  }
}
