class Trip {
  String id;
  String destinationCountry;
  String destinationCurrency;
  String homeCurrency;
  double budget;
  double exchangeRate;
  DateTime? startDate;
  DateTime? endDate;
  List<Expense> expenses;
  List<PackingItem> packingList;
  List<DailyPlan> dailyPlans;

  Trip({
    required this.id,
    required this.destinationCountry,
    required this.destinationCurrency,
    required this.homeCurrency,
    required this.budget,
    this.exchangeRate = 1.0,
    this.startDate,
    this.endDate,
    List<Expense>? expenses,
    List<PackingItem>? packingList,
    List<DailyPlan>? dailyPlans,
  })  : expenses = expenses ?? [],
        packingList = packingList ?? [],
        dailyPlans = dailyPlans ?? [];

  double get totalSpent {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double get remainingBudget {
    return budget - totalSpent;
  }

  double get percentageSpent {
    if (budget == 0) return 0;
    return (totalSpent / budget) * 100;
  }

  double get remainingBudgetInDestinationCurrency {
    return remainingBudget * exchangeRate;
  }

  int? get tripDuration {
    if (startDate == null || endDate == null) return null;
    return endDate!.difference(startDate!).inDays + 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destinationCountry': destinationCountry,
      'destinationCurrency': destinationCurrency,
      'homeCurrency': homeCurrency,
      'budget': budget,
      'exchangeRate': exchangeRate,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'packingList': packingList.map((e) => e.toJson()).toList(),
      'dailyPlans': dailyPlans.map((e) => e.toJson()).toList(),
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      destinationCountry: json['destinationCountry'],
      destinationCurrency: json['destinationCurrency'],
      homeCurrency: json['homeCurrency'],
      budget: json['budget'].toDouble(),
      exchangeRate: json['exchangeRate']?.toDouble() ?? 1.0,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate:
          json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      expenses: (json['expenses'] as List?)
              ?.map((e) => Expense.fromJson(e))
              .toList() ??
          [],
      packingList: (json['packingList'] as List?)
              ?.map((e) => PackingItem.fromJson(e))
              .toList() ??
          [],
      dailyPlans: (json['dailyPlans'] as List?)
              ?.map((e) => DailyPlan.fromJson(e))
              .toList() ??
          [],
    );
  }

  Trip copyWith({
    String? id,
    String? destinationCountry,
    String? destinationCurrency,
    String? homeCurrency,
    double? budget,
    double? exchangeRate,
    DateTime? startDate,
    DateTime? endDate,
    List<Expense>? expenses,
    List<PackingItem>? packingList,
    List<DailyPlan>? dailyPlans,
  }) {
    return Trip(
      id: id ?? this.id,
      destinationCountry: destinationCountry ?? this.destinationCountry,
      destinationCurrency: destinationCurrency ?? this.destinationCurrency,
      homeCurrency: homeCurrency ?? this.homeCurrency,
      budget: budget ?? this.budget,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      expenses: expenses ?? this.expenses,
      packingList: packingList ?? this.packingList,
      dailyPlans: dailyPlans ?? this.dailyPlans,
    );
  }
}

class Expense {
  String id;
  double amount;
  String description;
  ExpenseCategory category;
  DateTime date;
  double overdraftAmount; // The specific amount that exceeded the budget (0 if no overdraft)

  Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    DateTime? date,
    this.overdraftAmount = 0,
  }) : date = date ?? DateTime.now();

  // Check if this expense caused an overdraft
  bool get isOverdraft => overdraftAmount > 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'category': category.name,
      'date': date.toIso8601String(),
      'overdraftAmount': overdraftAmount,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: json['amount'].toDouble(),
      description: json['description'],
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(json['date']),
      overdraftAmount: json['overdraftAmount']?.toDouble() ?? 0,
    );
  }
}

enum ExpenseCategory {
  food('Food', '🍕'),
  transport('Transport', '🚕'),
  accommodation('Accommodation', '🏨'),
  shopping('Shopping', '🛍️'),
  entertainment('Entertainment', '🎭'),
  activities('Activities', '🎯'),
  other('Other', '📝');

  final String label;
  final String emoji;

  const ExpenseCategory(this.label, this.emoji);
}

class PackingItem {
  String id;
  String name;
  bool isPacked;

  PackingItem({
    required this.id,
    required this.name,
    this.isPacked = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isPacked': isPacked,
    };
  }

  factory PackingItem.fromJson(Map<String, dynamic> json) {
    return PackingItem(
      id: json['id'],
      name: json['name'],
      isPacked: json['isPacked'] ?? false,
    );
  }

  PackingItem copyWith({
    String? id,
    String? name,
    bool? isPacked,
  }) {
    return PackingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isPacked: isPacked ?? this.isPacked,
    );
  }
}

class DailyPlan {
  String id;
  DateTime date;
  List<Activity> activities;
  List<Outfit> outfits;

  DailyPlan({
    required this.id,
    required this.date,
    List<Activity>? activities,
    List<Outfit>? outfits,
  })  : activities = activities ?? [],
        outfits = outfits ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'activities': activities.map((e) => e.toJson()).toList(),
      'outfits': outfits.map((e) => e.toJson()).toList(),
    };
  }

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    return DailyPlan(
      id: json['id'],
      date: DateTime.parse(json['date']),
      activities: (json['activities'] as List?)
              ?.map((e) => Activity.fromJson(e))
              .toList() ??
          [],
      outfits: (json['outfits'] as List?)
              ?.map((e) => Outfit.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Activity {
  String id;
  String time;
  String description;
  String? notes;

  Activity({
    required this.id,
    required this.time,
    required this.description,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'description': description,
      'notes': notes,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      time: json['time'],
      description: json['description'],
      notes: json['notes'],
    );
  }
}

class Outfit {
  String id;
  String? imageUrl;
  String? pinterestLink;
  String? description;

  Outfit({
    required this.id,
    this.imageUrl,
    this.pinterestLink,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'pinterestLink': pinterestLink,
      'description': description,
    };
  }

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['id'],
      imageUrl: json['imageUrl'],
      pinterestLink: json['pinterestLink'],
      description: json['description'],
    );
  }
}
