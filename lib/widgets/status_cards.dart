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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  title: 'Berat Pakan',
                  value: feedState.currentWeight.toStringAsFixed(1),
                  unit: 'gram',
                  icon: Icons.monitor_weight_outlined,
                  footer: 'Data Loadcell',
                  color: AppTheme.surfaceLight, // Lighter card for layering
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatusCard(
                  title: 'Stok (Sistem)',
                  value: '${feedState.currentStock.toInt()}',
                  unit: 'g',
                  icon: Icons.inventory_2_outlined,
                  footer: '${feedState.maxCapacity.toInt()}g',
                  progress: feedState.currentStock / feedState.maxCapacity,
                  isWarning: (feedState.maxCapacity > 0) ? (feedState.currentStock / feedState.maxCapacity) < 0.1 : false,
                  color: AppTheme.surfaceLight, // Lighter card for layering
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  title: 'Status Alat',
                  value: deviceState.status,
                  icon: Icons.sensors_outlined,
                  isStatus: true,
                  isOffline: !deviceState.isFirebaseConnected,
                  statusItems: [
                    'Katup: ${deviceState.isFirebaseConnected ? deviceState.valveStatus : '-'}',
                    'Servo: ${deviceState.isFirebaseConnected ? deviceState.servoStatus : '-'}',
                  ],
                  color: AppTheme.surface, // Darker card for layering
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final IconData icon;
  final String? footer;
  final double? progress;
  final bool isStatus;
  final List<String>? statusItems;
  final Color color;
  final bool isOffline;
  final bool isWarning;

  const _StatusCard({
    required this.title,
    required this.value,
    this.unit,
    required this.icon,
    this.footer,
    this.progress,
    this.isStatus = false,
    this.statusItems,
    required this.color,
    this.isOffline = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: Colors.white.withAlpha((255 * 0.05).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTheme.titleSmall),
              Icon(icon, size: 18, color: AppTheme.secondaryText.withAlpha((255 * 0.6).round())),
            ],
          ),
          const SizedBox(height: 16),
          if (isStatus) ...[
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOffline ? AppTheme.error : AppTheme.statusOnline,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isOffline ? 'Offline' : value,
                  style: AppTheme.headlineMedium.copyWith(
                    color: isOffline ? AppTheme.error : AppTheme.statusOnline, 
                    fontSize: 16
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (statusItems != null)
              ...statusItems!.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(item, style: AppTheme.bodySmall.copyWith(
                  fontSize: 11,
                  color: isOffline ? AppTheme.secondaryText.withAlpha((255 * 0.5).round()) : AppTheme.secondaryText,
                )),
              )),
          ] else ...[
            RichText(
              text: TextSpan(
                style: AppTheme.bodyLarge.copyWith(color: AppTheme.primaryText),
                children: [
                  TextSpan(
                    text: value,
                    style: AppTheme.displaySmall.copyWith(fontWeight: FontWeight.w600)
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: unit,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.secondaryText, 
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (progress != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.background,
                  valueColor: AlwaysStoppedAnimation<Color>(isWarning ? AppTheme.error : AppTheme.accent),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (footer != null)
              Text(footer!, style: AppTheme.bodySmall.copyWith(fontSize: 10)),
          ],
        ],
      ),
    );
  }
}
