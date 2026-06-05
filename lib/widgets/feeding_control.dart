import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../providers/log_provider.dart';
import '../theme.dart';

class FeedingControlPanel extends ConsumerWidget {
  const FeedingControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);
    final feedNotifier = ref.read(feedProvider.notifier);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBg, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INPUT DOSIS PAKAN',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondaryText, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${feedState.dosage}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accent),
                        ),
                        const SizedBox(width: 8),
                        const Text('g', style: TextStyle(fontSize: 18, color: AppTheme.accent)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  _buildSmallButton(Icons.keyboard_arrow_up, feedNotifier.incrementDosage),
                  const SizedBox(height: 8),
                  _buildSmallButton(Icons.keyboard_arrow_down, feedNotifier.decrementDosage),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                final dosage = feedState.dosage;
                feedNotifier.dispenseFeed();
                
                // Menambah log ke Activity Log
                final now = DateTime.now();
                final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
                
                ref.read(logProvider.notifier).addLog(
                  ActivityLog(
                    title: 'Pakan ${dosage}g diberikan',
                    time: 'Hari ini $timeStr',
                    type: LogType.success,
                    status: 'Selesai',
                    dosage: dosage,
                    timestamp: now,
                  ),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Memberikan ${dosage}g pakan...'),
                    backgroundColor: AppTheme.accent,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cardBg,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.surface, width: 1),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.set_meal, size: 20),
                  SizedBox(width: 12),
                  Text('Beri Makan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.surface, width: 1),
        ),
        child: Icon(icon, color: AppTheme.primaryText, size: 24),
      ),
    );
  }
}
