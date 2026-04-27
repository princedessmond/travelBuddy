import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';

class TimezoneService {
  // Singleton pattern
  static final TimezoneService _instance = TimezoneService._internal();
  factory TimezoneService() => _instance;
  TimezoneService._internal() {
    _initializeTimezones();
  }

  bool _isInitialized = false;

  void _initializeTimezones() {
    if (!_isInitialized) {
      tz.initializeTimeZones();
      _isInitialized = true;
    }
  }

  /// Map country names to timezone identifiers
  /// This is a simplified mapping - in production, you'd want a more comprehensive database
  String _getTimezoneForCountry(String country) {
    final countryTimezones = {
      // Europe
      'france': 'Europe/Paris',
      'paris': 'Europe/Paris',
      'germany': 'Europe/Berlin',
      'berlin': 'Europe/Berlin',
      'united kingdom': 'Europe/London',
      'london': 'Europe/London',
      'uk': 'Europe/London',
      'spain': 'Europe/Madrid',
      'madrid': 'Europe/Madrid',
      'italy': 'Europe/Rome',
      'rome': 'Europe/Rome',
      'greece': 'Europe/Athens',
      'athens': 'Europe/Athens',
      'netherlands': 'Europe/Amsterdam',
      'amsterdam': 'Europe/Amsterdam',
      'switzerland': 'Europe/Zurich',
      'zurich': 'Europe/Zurich',

      // North America
      'usa': 'America/New_York',
      'united states': 'America/New_York',
      'new york': 'America/New_York',
      'los angeles': 'America/Los_Angeles',
      'chicago': 'America/Chicago',
      'miami': 'America/New_York',
      'canada': 'America/Toronto',
      'toronto': 'America/Toronto',
      'vancouver': 'America/Vancouver',
      'mexico': 'America/Mexico_City',

      // Asia
      'japan': 'Asia/Tokyo',
      'tokyo': 'Asia/Tokyo',
      'china': 'Asia/Shanghai',
      'shanghai': 'Asia/Shanghai',
      'beijing': 'Asia/Shanghai',
      'india': 'Asia/Kolkata',
      'mumbai': 'Asia/Kolkata',
      'delhi': 'Asia/Kolkata',
      'thailand': 'Asia/Bangkok',
      'bangkok': 'Asia/Bangkok',
      'singapore': 'Asia/Singapore',
      'malaysia': 'Asia/Kuala_Lumpur',
      'indonesia': 'Asia/Jakarta',
      'south korea': 'Asia/Seoul',
      'seoul': 'Asia/Seoul',
      'vietnam': 'Asia/Ho_Chi_Minh',
      'philippines': 'Asia/Manila',
      'dubai': 'Asia/Dubai',
      'uae': 'Asia/Dubai',

      // Australia & Oceania
      'australia': 'Australia/Sydney',
      'sydney': 'Australia/Sydney',
      'melbourne': 'Australia/Melbourne',
      'new zealand': 'Pacific/Auckland',
      'auckland': 'Pacific/Auckland',

      // South America
      'brazil': 'America/Sao_Paulo',
      'argentina': 'America/Buenos_Aires',
      'chile': 'America/Santiago',
      'peru': 'America/Lima',
      'colombia': 'America/Bogota',

      // Africa
      'south africa': 'Africa/Johannesburg',
      'egypt': 'Africa/Cairo',
      'kenya': 'Africa/Nairobi',
      'morocco': 'Africa/Casablanca',
      'nigeria': 'Africa/Lagos',
    };

    final key = country.toLowerCase().trim();
    return countryTimezones[key] ?? 'UTC';
  }

  /// Get current time at destination
  DateTime getDestinationTime(String destination) {
    try {
      final timezoneId = _getTimezoneForCountry(destination);
      final location = tz.getLocation(timezoneId);
      return tz.TZDateTime.now(location);
    } catch (e) {
      print('Error getting destination time: $e');
      return DateTime.now(); // Fallback to local time
    }
  }

  /// Get formatted destination time (e.g., "3:45 PM")
  String getFormattedDestinationTime(String destination) {
    final destTime = getDestinationTime(destination);
    return DateFormat('h:mm a').format(destTime);
  }

  /// Get formatted destination date and time (e.g., "Mon, Jan 15, 3:45 PM")
  String getFullFormattedDestinationTime(String destination) {
    final destTime = getDestinationTime(destination);
    return DateFormat('EEE, MMM d, h:mm a').format(destTime);
  }

  /// Get time difference from local time (e.g., "+2 hours", "-5 hours")
  String getTimeDifference(String destination) {
    try {
      final destTime = getDestinationTime(destination);
      final localTime = DateTime.now();

      final difference = destTime.difference(localTime);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;

      if (hours == 0 && minutes == 0) {
        return 'Same time zone';
      }

      final sign = hours >= 0 ? '+' : '';
      if (minutes == 0) {
        return '$sign$hours hrs';
      } else {
        return '$sign$hours hrs ${minutes.abs()} min';
      }
    } catch (e) {
      print('Error calculating time difference: $e');
      return 'Unknown';
    }
  }

  /// Calculate countdown to trip start
  String getCountdownToTrip(DateTime tripStartDate) {
    final now = DateTime.now();
    final difference = tripStartDate.difference(now);

    if (difference.isNegative) {
      return 'Trip started!';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return '$days days, $hours hours';
    } else if (hours > 0) {
      return '$hours hours, $minutes minutes';
    } else {
      return '$minutes minutes';
    }
  }

  /// Get a friendly countdown message
  String getCountdownMessage(DateTime tripStartDate) {
    final now = DateTime.now();
    final difference = tripStartDate.difference(now);

    if (difference.isNegative) {
      final daysSinceStart = now.difference(tripStartDate).inDays;
      if (daysSinceStart == 0) {
        return '🎉 Your trip starts today!';
      } else {
        return '✈️ Trip in progress (Day ${daysSinceStart + 1})';
      }
    }

    final days = difference.inDays;

    if (days == 0) {
      return '🎉 Tomorrow is the big day!';
    } else if (days == 1) {
      return '⏰ Only 1 day to go!';
    } else if (days <= 7) {
      return '⏰ $days days until departure!';
    } else if (days <= 30) {
      return '📅 $days days until your trip!';
    } else {
      final weeks = (days / 7).floor();
      return '📅 $weeks weeks until your adventure!';
    }
  }

  /// Check if destination is ahead or behind local time
  bool isDestinationAhead(String destination) {
    try {
      final destTime = getDestinationTime(destination);
      final localTime = DateTime.now();
      return destTime.isAfter(localTime);
    } catch (e) {
      return false;
    }
  }
}
