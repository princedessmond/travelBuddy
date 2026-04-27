import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';

class StorageService {
  static const String _tripKey = 'current_trip';
  static const String _tripHistoryKey = 'trip_history';
  static const String _hasSeenIntroKey = 'has_seen_intro';

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Trip operations
  Future<void> saveTrip(Trip trip) async {
    final json = jsonEncode(trip.toJson());
    await _prefs?.setString(_tripKey, json);
  }

  Future<Trip?> loadTrip() async {
    final json = _prefs?.getString(_tripKey);
    if (json == null) return null;
    try {
      return Trip.fromJson(jsonDecode(json));
    } catch (e) {
      print('Error loading trip: $e');
      return null;
    }
  }

  Future<void> clearTrip() async {
    await _prefs?.remove(_tripKey);
  }

  // Trip History operations
  Future<List<Trip>> loadTripHistory() async {
    final json = _prefs?.getString(_tripHistoryKey);
    if (json == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((tripJson) => Trip.fromJson(tripJson)).toList();
    } catch (e) {
      print('Error loading trip history: $e');
      return [];
    }
  }

  Future<void> saveTripToHistory(Trip trip) async {
    final history = await loadTripHistory();

    // Check if trip already exists in history (by ID)
    final existingIndex = history.indexWhere((t) => t.id == trip.id);
    if (existingIndex != -1) {
      // Update existing trip
      history[existingIndex] = trip;
    } else {
      // Add new trip to beginning of list
      history.insert(0, trip);
    }

    // Save updated history
    final json = jsonEncode(history.map((t) => t.toJson()).toList());
    await _prefs?.setString(_tripHistoryKey, json);
  }

  Future<void> deleteTripFromHistory(String tripId) async {
    final history = await loadTripHistory();
    history.removeWhere((trip) => trip.id == tripId);

    final json = jsonEncode(history.map((t) => t.toJson()).toList());
    await _prefs?.setString(_tripHistoryKey, json);
  }

  Future<void> clearTripHistory() async {
    await _prefs?.remove(_tripHistoryKey);
  }

  // Intro screen
  Future<void> setHasSeenIntro(bool value) async {
    await _prefs?.setBool(_hasSeenIntroKey, value);
  }

  Future<bool> hasSeenIntro() async {
    return _prefs?.getBool(_hasSeenIntroKey) ?? false;
  }

  // Share functionality - encode trip to Base64 URL
  String encodeTripToUrl(Trip trip) {
    final json = jsonEncode(trip.toJson());
    final bytes = utf8.encode(json);
    final base64 = base64Url.encode(bytes);
    return base64;
  }

  // Decode trip from Base64 URL
  Trip? decodeTripFromUrl(String encoded) {
    try {
      final bytes = base64Url.decode(encoded);
      final json = utf8.decode(bytes);
      return Trip.fromJson(jsonDecode(json));
    } catch (e) {
      print('Error decoding trip: $e');
      return null;
    }
  }
}
