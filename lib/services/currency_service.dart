import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CurrencyService {
  // ExchangeRate-API with API Key
  // Free tier: 1,500 requests/month
  // API key loaded from environment variables
  static String get _apiKey => dotenv.get('EXCHANGE_RATE_API_KEY', fallback: '');
  static String get _baseUrl => 'https://v6.exchangerate-api.com/v6/$_apiKey/latest';

  // Singleton pattern
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  Map<String, double>? _cachedRates;
  String? _cacheBaseCurrency;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 30);

  /// Fetch exchange rate from base currency to target currency
  Future<double?> getExchangeRate(String from, String to) async {
    try {
      // If currencies are the same, return 1
      if (from == to) return 1.0;

      // Check cache
      if (_isCacheValid(from)) {
        final cachedRate = _cachedRates?[to];
        print('Using cached rate for $from to $to: $cachedRate');
        return cachedRate;
      }

      // Fetch fresh rates
      final url = Uri.parse('$_baseUrl/$from');
      print('Fetching exchange rate from: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('API request timed out');
        },
      );

      print('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check for API errors
        if (data['result'] != 'success') {
          print('API returned error: ${data['error-type']}');
          return null;
        }

        // v6 API uses 'conversion_rates' instead of 'rates'
        final rates = Map<String, double>.from(
          (data['conversion_rates'] as Map).map(
            (key, value) => MapEntry(key, value.toDouble()),
          ),
        );

        // Cache the results
        _cachedRates = rates;
        _cacheBaseCurrency = from;
        _cacheTime = DateTime.now();

        final rate = rates[to];
        print('Successfully fetched rate for $from to $to: $rate');
        return rate;
      } else {
        print('Failed to fetch exchange rate: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error fetching exchange rate: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Convert amount from one currency to another
  Future<double?> convertCurrency({
    required double amount,
    required String from,
    required String to,
  }) async {
    final rate = await getExchangeRate(from, to);
    if (rate == null) return null;
    return amount * rate;
  }

  /// Check if cache is still valid
  bool _isCacheValid(String baseCurrency) {
    if (_cachedRates == null ||
        _cacheBaseCurrency != baseCurrency ||
        _cacheTime == null) {
      return false;
    }

    final now = DateTime.now();
    return now.difference(_cacheTime!) < _cacheDuration;
  }

  /// Clear cache (useful for manual refresh)
  void clearCache() {
    _cachedRates = null;
    _cacheBaseCurrency = null;
    _cacheTime = null;
  }

  /// Get all available rates for a base currency
  Future<Map<String, double>?> getAllRates(String baseCurrency) async {
    try {
      // Check cache
      if (_isCacheValid(baseCurrency)) {
        print('Using cached rates for $baseCurrency');
        return _cachedRates;
      }

      // Fetch fresh rates
      final url = Uri.parse('$_baseUrl/$baseCurrency');
      print('Fetching all rates from: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('API request timed out');
        },
      );

      print('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check for API errors
        if (data['result'] != 'success') {
          print('API returned error: ${data['error-type']}');
          return null;
        }

        // v6 API uses 'conversion_rates' instead of 'rates'
        final rates = Map<String, double>.from(
          (data['conversion_rates'] as Map).map(
            (key, value) => MapEntry(key, value.toDouble()),
          ),
        );

        // Cache the results
        _cachedRates = rates;
        _cacheBaseCurrency = baseCurrency;
        _cacheTime = DateTime.now();

        print('Successfully fetched ${rates.length} exchange rates');
        return rates;
      } else {
        print('Failed to fetch exchange rates: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error fetching exchange rates: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}
