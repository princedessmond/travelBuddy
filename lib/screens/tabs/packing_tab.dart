import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_colors.dart';
import '../../providers/trip_provider.dart';
import '../../models/trip_model.dart';

class PackingTab extends StatefulWidget {
  const PackingTab({super.key});

  @override
  State<PackingTab> createState() => _PackingTabState();
}

class _PackingTabState extends State<PackingTab> {
  final TextEditingController _itemController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _speechAvailable = await _speech.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) => print('Speech status: $status'),
      );
      setState(() {});
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available'),
        ),
      );
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _itemController.text = result.recognizedWords;
        });
      },
      listenMode: stt.ListenMode.dictation,
    );
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    await _speech.stop();
  }

  void _addItem() {
    if (_itemController.text.trim().isEmpty) return;

    Provider.of<TripProvider>(context, listen: false)
        .addPackingItem(_itemController.text.trim());

    _itemController.clear();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, child) {
        final trip = tripProvider.currentTrip;
        if (trip == null) return const SizedBox.shrink();

        final packedCount =
            trip.packingList.where((item) => item.isPacked).length;
        final totalCount = trip.packingList.length;
        final percentPacked =
            totalCount > 0 ? (packedCount / totalCount * 100) : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Packing List 🎒',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (totalCount > 0)
                Text(
                  '$packedCount of $totalCount items packed (${percentPacked.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 20),

              // Smart Suggestions Button
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: tripProvider.isLoading
                      ? null
                      : () {
                          Provider.of<TripProvider>(context, listen: false)
                              .addSmartPackingSuggestions();
                        },
                  icon: tripProvider.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    tripProvider.isLoading
                        ? 'Getting Suggestions...'
                        : 'Get Smart Suggestions',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primaryPurple,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Add item input
              Container(
                padding: const EdgeInsets.all(16),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _itemController,
                            decoration: InputDecoration(
                              hintText: 'Add an item...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            onSubmitted: (_) => _addItem(),
                          ),
                        ),
                        IconButton(
                          onPressed: _isListening ? _stopListening : _startListening,
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                          color: _isListening ? AppColors.primaryPurple : AppColors.textSecondary,
                        ),
                        IconButton(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_circle),
                          color: AppColors.primaryPink,
                        ),
                      ],
                    ),
                    if (_isListening)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.mic,
                              size: 16,
                              color: AppColors.primaryPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Listening...',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Progress bar
              if (totalCount > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentPacked / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.lightPink,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Packing list
              if (trip.packingList.isNotEmpty) ...[
                ...trip.packingList.map(
                  (item) => _PackingItemCard(item: item),
                ),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        const Text(
                          '🎒',
                          style: TextStyle(fontSize: 64),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items yet — type or use the mic!',
                          textAlign: TextAlign.center,
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

class _PackingItemCard extends StatelessWidget {
  final PackingItem item;

  const _PackingItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isPacked
              ? AppColors.success.withOpacity(0.3)
              : AppColors.lightGrey,
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {
              Provider.of<TripProvider>(context, listen: false)
                  .togglePackingItem(item.id);
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isPacked ? AppColors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.isPacked
                      ? AppColors.success
                      : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: item.isPacked
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),

          // Item name
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: item.isPacked
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                decoration: item.isPacked
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),

          // Delete button
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              Provider.of<TripProvider>(context, listen: false)
                  .deletePackingItem(item.id);
            },
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}
