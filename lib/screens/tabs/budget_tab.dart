import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../providers/trip_provider.dart';
import '../../models/trip_model.dart';
import '../../constants/countries_data.dart';

class BudgetTab extends StatelessWidget {
  const BudgetTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, child) {
        final trip = tripProvider.currentTrip;
        if (trip == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exchange Rate Card
              _ExchangeRateCard(trip: trip),
              const SizedBox(height: 20),

              // Budget Remaining Card
              _BudgetRemainingCard(trip: trip),
              const SizedBox(height: 20),

              // Add Expense Button
              const _AddExpenseButton(),
              const SizedBox(height: 20),

              // Expenses List
              if (trip.expenses.isNotEmpty) ...[
                const Text(
                  'Recent Expenses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...trip.expenses.reversed.map((expense) =>
                    _ExpenseCard(expense: expense, trip: trip)),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        const Text(
                          '📝',
                          style: TextStyle(fontSize: 64),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No expenses yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ExchangeRateCard extends StatefulWidget {
  final Trip trip;

  const _ExchangeRateCard({required this.trip});

  @override
  State<_ExchangeRateCard> createState() => _ExchangeRateCardState();
}

class _ExchangeRateCardState extends State<_ExchangeRateCard> {
  final TextEditingController _rateController = TextEditingController();
  bool _isCustomRate = false;

  @override
  void initState() {
    super.initState();
    _rateController.text = widget.trip.exchangeRate.toStringAsFixed(4);
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  void _useLiveRate() async {
    setState(() {
      _isCustomRate = false;
    });
    await Provider.of<TripProvider>(context, listen: false).refreshExchangeRate();
    setState(() {
      _rateController.text = widget.trip.exchangeRate.toStringAsFixed(4);
    });
  }

  void _updateCustomRate() {
    final rate = double.tryParse(_rateController.text);
    if (rate != null && rate > 0) {
      Provider.of<TripProvider>(context, listen: false).setCustomExchangeRate(rate);
      setState(() {
        _isCustomRate = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exchange Rate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              // Show refresh button when in live rate mode
              if (!_isCustomRate)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _useLiveRate,
                  color: AppColors.accentBlue,
                  tooltip: 'Refresh live rate',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Toggle buttons for Live/Custom Rate
          Container(
            decoration: BoxDecoration(
              color: AppColors.lightGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _useLiveRate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isCustomRate ? AppColors.accentBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'Live Rate',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: !_isCustomRate ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCustomRate = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isCustomRate ? AppColors.accentBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        'Custom Rate',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isCustomRate ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            '1 ${widget.trip.homeCurrency} =',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: _isCustomRate,
            onChanged: (value) => _updateCustomRate(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _isCustomRate ? Colors.white : AppColors.lightGrey.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightGrey),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.lightGrey.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.accentBlue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.trip.destinationCurrency,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetRemainingCard extends StatelessWidget {
  final Trip trip;

  const _BudgetRemainingCard({required this.trip});

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final percentSpent = trip.percentageSpent.clamp(0.0, 100.0);
    final percentRemaining = 100 - percentSpent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Budget Remaining',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Amounts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${trip.homeCurrency}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatCurrency(trip.remainingBudget),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ),
                    Text(
                      'of ${_formatCurrency(trip.budget)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${trip.destinationCurrency}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatCurrency(trip.remainingBudgetInDestinationCurrency),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                    Text(
                      '~${_formatCurrency(trip.budget * trip.exchangeRate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget used: ${percentSpent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Left: ${percentRemaining.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentSpent / 100,
                  minHeight: 10,
                  backgroundColor: AppColors.lightPink,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentSpent > 90
                        ? AppColors.error
                        : percentSpent > 75
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Started with\n${_formatCurrency(trip.budget)} ${trip.homeCurrency}',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Spent\n${_formatCurrency(trip.totalSpent)} ${trip.homeCurrency}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddExpenseButton extends StatelessWidget {
  const _AddExpenseButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddExpenseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Log an Expense'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _showBudgetExceededWarning(
    BuildContext context,
    double amount,
    double remainingBudget,
    double totalBudget,
    String currency,
    String description,
    ExpenseCategory category,
    Trip trip,
  ) {
    final formatter = NumberFormat('#,##0.00');
    final overage = amount - remainingBudget;

    // Calculate home currency equivalents
    final amountInHome = amount / trip.exchangeRate;
    final remainingInHome = trip.remainingBudget;
    final overageInHome = overage / trip.exchangeRate;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            const Text('Budget Warning'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This expense will exceed your budget!',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              _BudgetWarningRow(
                label: 'Expense',
                value: '${formatter.format(amount)} $currency',
                color: AppColors.textPrimary,
              ),
              _BudgetWarningRow(
                label: '',
                value: '≈ ${formatter.format(amountInHome)} ${trip.homeCurrency}',
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              _BudgetWarningRow(
                label: 'Remaining Budget',
                value: '${formatter.format(remainingBudget)} $currency',
                color: AppColors.success,
              ),
              _BudgetWarningRow(
                label: '',
                value: '≈ ${formatter.format(remainingInHome)} ${trip.homeCurrency}',
                color: AppColors.textSecondary,
              ),
              const Divider(height: 24),
              _BudgetWarningRow(
                label: 'You\'ll be over by',
                value: '${formatter.format(overage)} $currency',
                color: AppColors.error,
                isBold: true,
              ),
              _BudgetWarningRow(
                label: '',
                value: '≈ ${formatter.format(overageInHome)} ${trip.homeCurrency}',
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Do you want to continue and go over budget?',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add the expense with the calculated overdraft amount
              Provider.of<TripProvider>(dialogContext, listen: false).addExpense(
                amount: amount,
                description: description,
                category: category,
                overdraftAmount: overage, // Store the amount that exceeded the budget
              );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  String _getFlagForCurrency(String currencyCode) {
    final country = CountriesData.countries.firstWhere(
      (c) => c.currencyCode == currencyCode,
      orElse: () => CountriesData.countries.first,
    );
    return country.flag;
  }

  void _showAddExpenseDialog(BuildContext context) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    ExpenseCategory selectedCategory = ExpenseCategory.food;
    double convertedAmount = 0.0;

    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final trip = tripProvider.currentTrip;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          // Calculate conversion whenever amount changes
          final amount = double.tryParse(amountController.text) ?? 0.0;
          convertedAmount = amount * (trip?.exchangeRate ?? 1.0);

          return AlertDialog(
            title: const Text('Add Expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        // Trigger rebuild to update converted amount
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Amount (${trip?.destinationCurrency ?? ""})',
                      prefixText: '💰 ',
                      helperText: 'Enter amount in ${trip?.destinationCurrency ?? "local currency"}',
                    ),
                  ),
                  // Show conversion in real-time
                  if (trip != null && amount > 0) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '≈ ${_getFlagForCurrency(trip.homeCurrency)} ${NumberFormat('#,##0.00').format(convertedAmount)} ${trip.homeCurrency}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Show exact converted amount in a styled container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightPink,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryPink.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _getFlagForCurrency(trip.homeCurrency),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${NumberFormat('#,##0.00##########').format(convertedAmount)} ${trip.homeCurrency}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixText: '📝 ',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ExpenseCategory.values.map((category) {
                    final isSelected = category == selectedCategory;
                    return FilterChip(
                      label: Text(
                        '${category.emoji} ${category.label}',
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => selectedCategory = category);
                      },
                      selectedColor: AppColors.primaryPink.withOpacity(0.3),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                    ),
                  );
                  return;
                }

                final tripProvider = Provider.of<TripProvider>(context, listen: false);
                final trip = tripProvider.currentTrip;

                if (trip != null) {
                  final remainingBudget = trip.remainingBudgetInDestinationCurrency;
                  final newTotal = trip.totalSpent + amount;

                  // Check if this expense will exceed the budget
                  if (newTotal > trip.budget) {
                    Navigator.pop(context); // Close expense dialog
                    _showBudgetExceededWarning(
                      context,
                      amount,
                      remainingBudget,
                      trip.budget * trip.exchangeRate,
                      trip.destinationCurrency,
                      descriptionController.text.isEmpty
                          ? selectedCategory.label
                          : descriptionController.text,
                      selectedCategory,
                      trip,
                    );
                    return;
                  }
                }

                tripProvider.addExpense(
                  amount: amount,
                  description: descriptionController.text.isEmpty
                      ? selectedCategory.label
                      : descriptionController.text,
                  category: selectedCategory,
                );

                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
      ),
    );
  }
}

class _BudgetWarningRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _BudgetWarningRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final Trip trip;

  const _ExpenseCard({required this.expense, required this.trip});

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Row(
        children: [
          // Category emoji
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.lightPink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                expense.category.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Description and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${expense.category.label} • ${DateFormat('MMM dd, HH:mm').format(expense.date)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Overdraft warning indicator
                      if (expense.isOverdraft)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Tooltip(
                            message: 'Overdraft: ${_formatCurrency(expense.overdraftAmount)} ${trip.destinationCurrency}',
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                              size: 18,
                            ),
                          ),
                        ),
                      Text(
                        '-${_formatCurrency(expense.amount)} ${trip.destinationCurrency}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  // Show home currency equivalent
                  Text(
                    '≈ ${_formatCurrency(expense.amount / trip.exchangeRate)} ${trip.homeCurrency}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Show overdraft amount below total
                  if (expense.isOverdraft)
                    Text(
                      'Overdraft: ${_formatCurrency(expense.overdraftAmount)} ${trip.destinationCurrency}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () {
                  Provider.of<TripProvider>(context, listen: false)
                      .deleteExpense(expense.id);
                },
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
