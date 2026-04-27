import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/trip_model.dart';
import '../services/storage_service.dart';
import '../services/currency_service.dart';
import '../services/weather_service.dart';
import '../services/ai_packing_service.dart';

class TripProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final CurrencyService _currencyService = CurrencyService();
  final AIPackingService _aiPackingService = AIPackingService();
  final Uuid _uuid = const Uuid();

  Trip? _currentTrip;
  List<Trip> _tripHistory = [];
  bool _isLoading = false;
  String? _error;

  Trip? get currentTrip => _currentTrip;
  List<Trip> get tripHistory => _tripHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasTrip => _currentTrip != null;

  // Initialize and load saved trip
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentTrip = await _storageService.loadTrip();
      _tripHistory = await _storageService.loadTripHistory();
    } catch (e) {
      _error = 'Failed to load trip: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create new trip
  Future<void> createTrip({
    required String destinationCountry,
    required String destinationCurrency,
    required String homeCurrency,
    required double budget,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Archive current trip if it exists
      if (_currentTrip != null) {
        await _storageService.saveTripToHistory(_currentTrip!);
      }

      // Fetch exchange rate
      print('Fetching exchange rate from $homeCurrency to $destinationCurrency');
      final rate = await _currencyService.getExchangeRate(
        homeCurrency,
        destinationCurrency,
      );

      if (rate == null) {
        print('WARNING: Failed to fetch exchange rate, using default rate of 1.0');
        _error = 'Could not fetch current exchange rate. Using temporary rate. Please refresh exchange rate once connected.';
      } else {
        print('Successfully received exchange rate: $rate');
      }

      _currentTrip = Trip(
        id: _uuid.v4(),
        destinationCountry: destinationCountry,
        destinationCurrency: destinationCurrency,
        homeCurrency: homeCurrency,
        budget: budget,
        exchangeRate: rate ?? 1.0,
      );

      await _storageService.saveTrip(_currentTrip!);

      // Reload history to include the archived trip
      _tripHistory = await _storageService.loadTripHistory();
      _error = null;
    } catch (e) {
      _error = 'Failed to create trip: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update exchange rate
  Future<void> updateExchangeRate(double rate) async {
    if (_currentTrip == null) return;

    _currentTrip = _currentTrip!.copyWith(exchangeRate: rate);
    await _storageService.saveTrip(_currentTrip!);
    notifyListeners();
  }

  // Refresh exchange rate from API
  Future<void> refreshExchangeRate() async {
    if (_currentTrip == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Clear cache to force fresh API call
      _currencyService.clearCache();

      final rate = await _currencyService.getExchangeRate(
        _currentTrip!.homeCurrency,
        _currentTrip!.destinationCurrency,
      );

      if (rate != null) {
        _currentTrip = _currentTrip!.copyWith(exchangeRate: rate);
        await _storageService.saveTrip(_currentTrip!);
        _error = null;
      } else {
        _error = 'Could not fetch exchange rate. Please try again.';
      }
    } catch (e) {
      _error = 'Failed to refresh exchange rate: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Set custom exchange rate
  Future<void> setCustomExchangeRate(double rate) async {
    if (_currentTrip == null) return;

    _currentTrip = _currentTrip!.copyWith(exchangeRate: rate);
    await _storageService.saveTrip(_currentTrip!);
    notifyListeners();
  }

  // Update trip budget
  Future<void> updateTripBudget(String tripId, double newBudget) async {
    if (_currentTrip == null || _currentTrip!.id != tripId) return;

    _currentTrip = _currentTrip!.copyWith(budget: newBudget);
    await _storageService.saveTrip(_currentTrip!);
    notifyListeners();
  }

  // Set trip dates
  Future<void> setTripDates(DateTime startDate, DateTime endDate) async {
    if (_currentTrip == null) return;

    _currentTrip = _currentTrip!.copyWith(
      startDate: startDate,
      endDate: endDate,
    );

    // Generate daily plans for each day
    _generateDailyPlans();

    await _storageService.saveTrip(_currentTrip!);
    notifyListeners();
  }

  void _generateDailyPlans() {
    if (_currentTrip?.startDate == null || _currentTrip?.endDate == null) {
      return;
    }

    final days = _currentTrip!.endDate!.difference(_currentTrip!.startDate!).inDays + 1;
    final plans = <DailyPlan>[];

    for (int i = 0; i < days; i++) {
      final date = _currentTrip!.startDate!.add(Duration(days: i));
      plans.add(DailyPlan(
        id: _uuid.v4(),
        date: date,
      ));
    }

    _currentTrip = _currentTrip!.copyWith(dailyPlans: plans);
  }

  // Add expense
  Future<void> addExpense({
    required double amount,
    required String description,
    required ExpenseCategory category,
    double overdraftAmount = 0,
  }) async {
    if (_currentTrip == null) return;

    final expense = Expense(
      id: _uuid.v4(),
      amount: amount,
      description: description,
      category: category,
      overdraftAmount: overdraftAmount,
    );

    final updatedExpenses = [..._currentTrip!.expenses, expense];
    _currentTrip = _currentTrip!.copyWith(expenses: updatedExpenses);

    await _storageService.saveTrip(_currentTrip!);
    notifyListeners();
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    if (_currentTrip == null) return;

    final updatedExpenses = _currentTrip!.expenses
        .where((e) => e.id != expenseId)
        .toList();

    _currentTrip = _currentTrip!.copyWith(expenses: updatedExpenses);

    await _storageService.saveTrip(_currentTrip!);
    notifyListeners();
  }

  // Add packing item
  Future<void> addPackingItem(String name) async {
    if (_currentTrip == null) return;

    final item = PackingItem(
      id: _uuid.v4(),
      name: name,
    );

    final updatedList = [..._currentTrip!.packingList, item];
    _currentTrip = _currentTrip!.copyWith(packingList: updatedList);

    await _storageService.saveTrip(_currentTrip!);
    notifyListeners();
  }

  // Toggle packing item
  Future<void> togglePackingItem(String itemId) async {
    if (_currentTrip == null) return;

    final updatedList = _currentTrip!.packingList.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isPacked: !item.isPacked);
      }
      return item;
    }).toList();

    _currentTrip = _currentTrip!.copyWith(packingList: updatedList);

    await _storageService.saveTrip(_currentTrip!);
    notifyListeners();
  }

  // Delete packing item
  Future<void> deletePackingItem(String itemId) async {
    if (_currentTrip == null) return;

    final updatedList = _currentTrip!.packingList
        .where((item) => item.id != itemId)
        .toList();

    _currentTrip = _currentTrip!.copyWith(packingList: updatedList);

    await _storageService.saveTrip(_currentTrip!);
    notifyListeners();
  }

  // Add AI-powered smart packing suggestions
  Future<void> addSmartPackingSuggestions() async {
    if (_currentTrip == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Fetch weather for destination
      final weather = await WeatherService()
          .getCurrentWeather(_currentTrip!.destinationCountry);

      // Calculate trip duration
      int? tripDuration;
      if (_currentTrip!.startDate != null && _currentTrip!.endDate != null) {
        tripDuration = _currentTrip!.endDate!
            .difference(_currentTrip!.startDate!)
            .inDays + 1;
      }

      // Get AI-powered packing suggestions
      final suggestions = await _aiPackingService.getSmartPackingSuggestions(
        destination: _currentTrip!.destinationCountry,
        weatherCondition: weather?.main,
        temperature: weather?.temperature,
        tripDurationDays: tripDuration,
      );

      // Add suggestions that aren't already in the list
      final existingItems = _currentTrip!.packingList
          .map((i) => i.name.toLowerCase())
          .toSet();

      for (final suggestion in suggestions) {
        if (!existingItems.contains(suggestion.toLowerCase())) {
          await addPackingItem(suggestion);
        }
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to get packing suggestions: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add activity to daily plan
  Future<void> addActivity({
    required String dailyPlanId,
    required String time,
    required String description,
    String? notes,
  }) async {
    if (_currentTrip == null) return;

    final activity = Activity(
      id: _uuid.v4(),
      time: time,
      description: description,
      notes: notes,
    );

    final updatedPlans = _currentTrip!.dailyPlans.map((plan) {
      if (plan.id == dailyPlanId) {
        return DailyPlan(
          id: plan.id,
          date: plan.date,
          activities: [...plan.activities, activity],
          outfits: plan.outfits,
        );
      }
      return plan;
    }).toList();

    _currentTrip = _currentTrip!.copyWith(dailyPlans: updatedPlans);

    await _storageService.saveTrip(_currentTrip!);
    notifyListeners();
  }

  // Add outfit to daily plan
  Future<void> addOutfit({
    required String dailyPlanId,
    String? imageUrl,
    String? pinterestLink,
    String? description,
  }) async {
    if (_currentTrip == null) return;

    final outfit = Outfit(
      id: _uuid.v4(),
      imageUrl: imageUrl,
      pinterestLink: pinterestLink,
      description: description,
    );

    final updatedPlans = _currentTrip!.dailyPlans.map((plan) {
      if (plan.id == dailyPlanId) {
        return DailyPlan(
          id: plan.id,
          date: plan.date,
          activities: plan.activities,
          outfits: [...plan.outfits, outfit],
        );
      }
      return plan;
    }).toList();

    _currentTrip = _currentTrip!.copyWith(dailyPlans: updatedPlans);

    await _storageService.saveTrip(_currentTrip!);
    notifyListeners();
  }

  // Generate share link
  String generateShareLink() {
    if (_currentTrip == null) return '';
    return _storageService.encodeTripToUrl(_currentTrip!);
  }

  // Load trip from share link
  Future<void> loadSharedTrip(String encoded) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentTrip = _storageService.decodeTripFromUrl(encoded);
      _error = null;
    } catch (e) {
      _error = 'Failed to load shared trip: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Reset trip (start over)
  Future<void> resetTrip() async {
    await _storageService.clearTrip();
    _currentTrip = null;
    _error = null;
    notifyListeners();
  }

  // Load trip from history (switch to it)
  Future<void> loadTripFromHistory(String tripId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Save current trip to history if it exists
      if (_currentTrip != null) {
        await _storageService.saveTripToHistory(_currentTrip!);
      }

      // Find the trip in history
      final trip = _tripHistory.firstWhere((t) => t.id == tripId);

      // Set it as current trip
      _currentTrip = trip;
      await _storageService.saveTrip(_currentTrip!);

      // Reload history
      _tripHistory = await _storageService.loadTripHistory();
      _error = null;
    } catch (e) {
      _error = 'Failed to load trip from history: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Delete trip from history
  Future<void> deleteTripFromHistory(String tripId) async {
    try {
      await _storageService.deleteTripFromHistory(tripId);
      _tripHistory = await _storageService.loadTripHistory();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete trip from history: $e';
      notifyListeners();
    }
  }

  // Save current trip to history (for manual archiving)
  Future<void> archiveCurrentTrip() async {
    if (_currentTrip == null) return;

    try {
      await _storageService.saveTripToHistory(_currentTrip!);
      _tripHistory = await _storageService.loadTripHistory();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to archive trip: $e';
      notifyListeners();
    }
  }
}
