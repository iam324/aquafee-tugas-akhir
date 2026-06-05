import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../providers/device_provider.dart';
import '../theme.dart';

class StatusCardsSection extends ConsumerWidget {
  const StatusCardsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);
    final deviceState = ref.watch(deviceProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          // Stock Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.balance, size: 16, color: AppTheme.secondaryText),
                      SizedBox(width: 8),
                      Text('Stok Pakan', style: TextStyle(fontSize: 12, color: AppTheme.secondaryText)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${feedState.currentStock.toInt()}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Text('g', style: TextStyle(fontSize: 14, color: AppTheme.secondaryText)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: feedState.currentStock / feedState.maxCapacity,
                      backgroundColor: AppTheme.cardBg,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kapasitas: ${feedState.maxCapacity.toInt()}g',
                    style: const TextStyle(fontSize: 10, color: AppTheme.success),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Device Status Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.monitor_heart_outlined, size: 16, color: AppTheme.secondaryText),
                      SizedBox(width: 8),
                      Text('Status Alat', style: TextStyle(fontSize: 12, color: AppTheme.secondaryText)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        deviceState.status,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Katup: ${deviceState.valveStatus}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.success),
                  ),
                  Text(
                    'Servo: ${deviceState.servoStatus}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.success),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
