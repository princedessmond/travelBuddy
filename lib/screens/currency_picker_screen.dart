import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/countries_data.dart';
import '../widgets/mascot_guide.dart';

class CurrencyPickerScreen extends StatefulWidget {
  const CurrencyPickerScreen({super.key});

  @override
  State<CurrencyPickerScreen> createState() => _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends State<CurrencyPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CountryData> _filteredCurrencies = CountriesData.countries;
  CountryData? _destinationCountry;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCurrencies);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the selected country from previous screen
    _destinationCountry =
        ModalRoute.of(context)?.settings.arguments as CountryData?;
  }

  void _filterCurrencies() {
    final query = _searchController.text;
    setState(() {
      _filteredCurrencies = CountriesData.searchCountries(query);
    });
  }

  void _selectCurrency(CountryData country) {
    if (_destinationCountry == null) return;

    Navigator.pushNamed(
      context,
      '/budget-setup',
      arguments: {
        'destination': _destinationCountry,
        'homeCurrency': country,
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.lightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header - Hidden when keyboard is visible
              if (!keyboardVisible) ...[
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'Travel Companion',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Budget, pack, plan & share your trip — all in one place! 🌍✨',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Mascot Guide
                const MascotGuide(
                  message: "Now tell me — what currency\nare you carrying? 💵 Let's\nmatch it up!",
                  emoji: '💰',
                ),

                // Step indicator
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightPink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '💵 Step 2 of 3',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ],

              // Main heading - Simplified when keyboard is visible
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  keyboardVisible ? 16 : 0,
                  20,
                  0,
                ),
                child: Text(
                  keyboardVisible ? 'Search currency' : 'What currency do you have? 💵',
                  style: TextStyle(
                    fontSize: keyboardVisible ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (!keyboardVisible) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Select your home currency',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              SizedBox(height: keyboardVisible ? 12 : 20),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search currency...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              SizedBox(height: keyboardVisible ? 12 : 20),

              // Currencies grid
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _filteredCurrencies.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '🔍',
                                style: TextStyle(fontSize: 64),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No currencies found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _filteredCurrencies.length,
                          itemBuilder: (context, index) {
                            final country = _filteredCurrencies[index];
                            return _CurrencyCard(
                              country: country,
                              onTap: () => _selectCurrency(country),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  final CountryData country;
  final VoidCallback onTap;

  const _CurrencyCard({
    required this.country,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPink.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flag emoji
              Text(
                country.flag,
                style: const TextStyle(fontSize: 34),
              ),
              const SizedBox(height: 10),

              // Currency name
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    country.currencyName,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Currency code
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightPink,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  country.currencyCode,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
