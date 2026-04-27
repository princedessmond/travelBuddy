import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/trip_model.dart';
import '../providers/trip_provider.dart';
import '../screens/tabs/budget_tab.dart';
import '../screens/tabs/packing_tab.dart';
import '../screens/tabs/planner_tab.dart';
import '../screens/tabs/share_tab.dart';
import '../constants/countries_data.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final Set<String> _expandedSections = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Trip?'),
        content: const Text(
          'Are you sure you want to reset this trip? All data will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final tripProvider = Provider.of<TripProvider>(context, listen: false);
      await tripProvider.resetTrip();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/country-selector');
      }
    }
  }

  void _toggleSection(String section) {
    setState(() {
      if (_expandedSections.contains(section)) {
        _expandedSections.remove(section);
      } else {
        _expandedSections.add(section);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, child) {
        final trip = tripProvider.currentTrip;
        final country = CountriesData.getCountryByName(
          trip?.destinationCountry ?? '',
        );

        if (trip == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '✈️',
                    style: TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No trip found',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/country-selector',
                      );
                    },
                    child: const Text('Start Planning'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.lightGradient,
            ),
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                          context, '/country-selector');
                                    },
                                    tooltip: 'Back to Planning',
                                    color: AppColors.primaryPurple,
                                  ),
                                  const Text(
                                    '✈️ Travel Made Easy',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryPink,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.person),
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/profile');
                                    },
                                    tooltip: 'Profile',
                                    color: AppColors.primaryPink,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.history),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                          context, '/trip-history');
                                    },
                                    tooltip: 'Trip History',
                                    color: AppColors.primaryPurple,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: _showResetDialog,
                                    tooltip: 'Reset Trip',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Destination banner (compact)
                          if (country != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryPink
                                        .withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${country.emojiScene}',
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              country.greeting,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryPink,
                                              ),
                                            ),
                                            Text(
                                              country.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primaryPurple,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${country.funFact}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),

                          // Feature Buttons Row (AI Assistant & Offline Map side by side)
                          Row(
                            children: [
                              // AI Assistant Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, '/ai-assistant');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6366F1),
                                          Color(0xFF8B5CF6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF8B5CF6)
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.auto_awesome,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'AI Assistant',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Smart planning',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white70,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Offline Map Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, '/offline-map');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF10B981),
                                          Color(0xFF059669),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981)
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.map,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Offline Map',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'GPS tracking',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white70,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Main content - Expandable sections
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Budget Section
                        _DashboardSection(
                          title: 'Budget',
                          icon: Icons.account_balance_wallet,
                          color: AppColors.primaryPink,
                          isExpanded: _expandedSections.contains('budget'),
                          onTap: () => _toggleSection('budget'),
                          summary: _buildBudgetSummary(trip),
                          child: const BudgetTab(),
                        ),
                        const SizedBox(height: 16),

                        // Packing Section
                        _DashboardSection(
                          title: 'Packing List',
                          icon: Icons.backpack,
                          color: AppColors.accentOrange,
                          isExpanded: _expandedSections.contains('packing'),
                          onTap: () => _toggleSection('packing'),
                          summary: _buildPackingSummary(trip),
                          child: const PackingTab(),
                        ),
                        const SizedBox(height: 16),

                        // Planner Section
                        _DashboardSection(
                          title: 'Daily Planner',
                          icon: Icons.calendar_today,
                          color: AppColors.primaryPurple,
                          isExpanded: _expandedSections.contains('planner'),
                          onTap: () => _toggleSection('planner'),
                          summary: _buildPlannerSummary(trip),
                          child: const PlannerTab(),
                        ),
                        const SizedBox(height: 16),

                        // Share Section
                        _DashboardSection(
                          title: 'Share Trip',
                          icon: Icons.share,
                          color: AppColors.accentBlue,
                          isExpanded: _expandedSections.contains('share'),
                          onTap: () => _toggleSection('share'),
                          summary: const Text(
                            'Generate shareable link',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          child: const ShareTab(),
                        ),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetSummary(Trip trip) {
    final formatter = NumberFormat('#,##0.00');
    final percentSpent = trip.percentageSpent.clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${formatter.format(trip.remainingBudget)} ${trip.homeCurrency}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryPink,
              ),
            ),
            Text(
              '${percentSpent.toStringAsFixed(0)}% spent',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentSpent / 100,
            minHeight: 6,
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
    );
  }

  Widget _buildPackingSummary(Trip trip) {
    final packedCount = trip.packingList.where((item) => item.isPacked).length;
    final totalCount = trip.packingList.length;
    final percentPacked =
        totalCount > 0 ? (packedCount / totalCount * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$packedCount of $totalCount items packed',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${percentPacked.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentPacked / 100,
            minHeight: 6,
            backgroundColor: AppColors.lightPink,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.success,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlannerSummary(Trip trip) {
    if (trip.startDate == null || trip.endDate == null) {
      return const Text(
        'Set your trip dates',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Text(
      '${trip.tripDuration} days • ${DateFormat('MMM dd').format(trip.startDate!)} - ${DateFormat('MMM dd, yyyy').format(trip.endDate!)}',
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget summary;
  final Widget child;

  const _DashboardSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.isExpanded,
    required this.onTap,
    required this.summary,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  if (!isExpanded) ...[
                    const SizedBox(height: 16),
                    summary,
                  ],
                ],
              ),
            ),
          ),

          // Expanded content
          if (isExpanded) ...[
            const Divider(height: 1),
            child,
          ],
        ],
      ),
    );
  }
}
