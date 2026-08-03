import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/feed_provider.dart';
import '../providers/log_provider.dart';
import '../providers/device_provider.dart';
import '../providers/demo_mode_provider.dart';

import '../theme.dart';

class FeedingControlPanel extends ConsumerWidget {
  const FeedingControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);
    final feedNotifier = ref.read(feedProvider.notifier);
    final deviceState = ref.watch(deviceProvider);
    final isDemoMode = ref.watch(demoModeProvider);
    final isOnline = deviceState.isFirebaseConnected;
    final canFeed = isOnline || isDemoMode;



    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: Colors.white.withAlpha((255 * 0.05).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_outlined, color: AppTheme.accent, size: 18),
              const SizedBox(width: 10),
              Text(
                'KONTROL PAKAN',
                style: AppTheme.titleSmall,
              ),
              const Spacer(),
              if (isDemoMode)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withAlpha((255 * 0.15).round()),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(color: AppTheme.warning.withAlpha((255 * 0.3).round())),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.science_outlined, size: 12, color: AppTheme.warning),
                      const SizedBox(width: 4),
                      Text(
                        'DEMO',
                        style: AppTheme.labelMedium.copyWith(
                          color: AppTheme.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 16),
          _FeedButton(
            isOffline: !canFeed,
            isDemoMode: isDemoMode,
            onPressed: () async {
              // Haptic feedback
              final hasVibrator = await Vibration.hasVibrator() ?? false;
              if (hasVibrator) {
                await Vibration.vibrate(duration: 50);
              }

              try {
                // Jika demo mode, pake dispensing lokal
                if (isDemoMode) {
                  feedNotifier.dispenseFeedLocal();
                } else {
                  await feedNotifier.dispenseFeed();
                }

                final now = DateTime.now();
                final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
                final logTitle = isDemoMode
                    ? 'Pakan diberikan (DEMO)'
                    : 'Pakan diberikan';

                await ref.read(logProvider.notifier).addLog(
                  ActivityLog(
                    title: logTitle,
                    time: timeStr,
                    type: LogType.success,
                    status: isDemoMode ? 'Demo' : 'Selesai',
                    timestamp: now,
                  ),
                );

                if (context.mounted) {
                  Fluttertoast.showToast(
                    msg: isDemoMode
                        ? 'DEMO: Pakan (tidak terkirim ke alat)'
                        : 'Berhasil memberikan pakan',
                    backgroundColor: AppTheme.statusOnline,
                    textColor: Colors.black,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Fluttertoast.showToast(
                    msg: 'Gagal memberi pakan: $e',
                    backgroundColor: AppTheme.error,
                    textColor: Colors.white,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  }


class _FeedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isOffline;
  final bool isDemoMode;
  const _FeedButton({required this.onPressed, this.isOffline = false, this.isDemoMode = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isOffline ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOffline ? AppTheme.surfaceLight : AppTheme.accent,
          foregroundColor: isOffline ? AppTheme.secondaryText : Colors.black,
          disabledBackgroundColor: AppTheme.surfaceLight,
          disabledForegroundColor: AppTheme.secondaryText,
          shadowColor: Colors.transparent, // No glow
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isOffline && !isDemoMode ? Icons.offline_bolt_rounded : isDemoMode ? Icons.science_outlined : Icons.bolt_rounded, 
                 color: isOffline ? AppTheme.secondaryText : Colors.black, size: 22),
            const SizedBox(width: 12),
            Text(
              isOffline && !isDemoMode ? 'ALAT OFFLINE' : isDemoMode ? 'BERI PAKAN (DEMO)' : 'BERI PAKAN SEKARANG',
              style: AppTheme.labelLarge.copyWith(
                color: isOffline ? AppTheme.secondaryText : Colors.black, 
                letterSpacing: 0.5
              ),
            ),
          ],
        ),
      ),
    );
  }
}
