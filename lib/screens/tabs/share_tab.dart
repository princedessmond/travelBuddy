import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_colors.dart';
import '../../providers/trip_provider.dart';

class ShareTab extends StatelessWidget {
  const ShareTab({super.key});

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
              // Header
              const Text(
                'Share Trip ✈️',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Generate a shareable link with your packing list, daily plans, outfits, and budget summary. Friends can view everything in a read-only page!',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              // Share illustration
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: AppColors.lightGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🔗📱💕',
                      style: TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'One Link. Complete Trip.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No sign-up required. Works everywhere.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Share buttons
              _ShareButton(
                icon: Icons.share,
                label: 'Share Link',
                description: 'Send via message, email, or social media',
                color: AppColors.primaryPink,
                onPressed: () => _shareTrip(context, tripProvider),
              ),
              const SizedBox(height: 12),
              _ShareButton(
                icon: Icons.copy,
                label: 'Copy Link',
                description: 'Copy to clipboard',
                color: AppColors.primaryPurple,
                onPressed: () => _copyLink(context, tripProvider),
              ),
              const SizedBox(height: 30),

              // Preview section
              Container(
                padding: const EdgeInsets.all(20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 What\'s Included',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _IncludedItem(
                      icon: Icons.flag,
                      label: 'Destination',
                      value: trip.destinationCountry,
                    ),
                    _IncludedItem(
                      icon: Icons.account_balance_wallet,
                      label: 'Budget Summary',
                      value: '${trip.budget.toStringAsFixed(2)} ${trip.homeCurrency}',
                    ),
                    _IncludedItem(
                      icon: Icons.backpack,
                      label: 'Packing List',
                      value: '${trip.packingList.length} items',
                    ),
                    _IncludedItem(
                      icon: Icons.calendar_today,
                      label: 'Daily Plans',
                      value: '${trip.dailyPlans.length} days',
                    ),
                    _IncludedItem(
                      icon: Icons.receipt,
                      label: 'Expenses',
                      value: '${trip.expenses.length} logged',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // How it works
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentBlue.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.accentBlue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'How Sharing Works',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your trip data is encoded directly in the URL - no server, no database, no accounts needed. Friends can view your complete trip in read-only mode.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareTrip(BuildContext context, TripProvider tripProvider) {
    try {
      final encoded = tripProvider.generateShareLink();
      final shareUrl = 'https://yourapp.com/shared#$encoded';
      final message = '✈️ Check out my trip plan!\n\n$shareUrl\n\nOpened with Travel Companion';

      Share.share(message);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }

  void _copyLink(BuildContext context, TripProvider tripProvider) {
    try {
      final encoded = tripProvider.generateShareLink();
      final shareUrl = 'https://yourapp.com/shared#$encoded';

      Clipboard.setData(ClipboardData(text: shareUrl));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Link copied to clipboard!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error copying: $e')),
      );
    }
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onPressed;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _IncludedItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _IncludedItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primaryPink,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
