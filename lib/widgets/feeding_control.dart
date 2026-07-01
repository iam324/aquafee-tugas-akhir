import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          Row(
            children: [
              Expanded(
                child: _DosageDisplay(dosage: feedState.dosage.toInt()),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  _ControlBtn(
                    icon: Icons.add_rounded,
                    onTap: feedNotifier.incrementDosage,
                  ),
                  const SizedBox(height: 12),
                  _ControlBtn(
                    icon: Icons.remove_rounded,
                    onTap: feedNotifier.decrementDosage,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _FeedButton(
            isOffline: !canFeed,
            isDemoMode: isDemoMode,
            onPressed: () async {
              final dosage = feedState.dosage;
              if (dosage <= 0) {
                _showError(context, 'Dosis harus lebih dari 0g');
                return;
              }

              // Jika demo mode, pake dispensing lokal
              if (isDemoMode) {
                feedNotifier.dispenseFeedLocal();
              } else {
                await feedNotifier.dispenseFeed();
              }
              
              final now = DateTime.now();
              final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
              final logTitle = isDemoMode 
                  ? 'Pakan ${dosage}g (DEMO)' 
                  : 'Pakan ${dosage}g diberikan';
              
              await ref.read(logProvider.notifier).addLog(
                ActivityLog(
                  title: logTitle,
                  time: timeStr,
                  type: LogType.success,
                  status: isDemoMode ? 'Demo' : 'Selesai',
                  dosage: dosage,
                  timestamp: now,
                ),
              );

              if (context.mounted) {
                final msg = isDemoMode
                    ? 'DEMO: ${dosage}g pakan (tidak terkirim ke alat)'
                    : 'Memberikan ${dosage}g pakan...';
                _showSuccess(context, msg);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
      ),
    );
  }

  void _showSuccess(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.statusOnline,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
      ),
    );
  }
}

class _DosageDisplay extends StatelessWidget {
  final int dosage;
  const _DosageDisplay({required this.dosage});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: AppTheme.background, // Darker than surface for depth
        borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        border: Border.all(color: Colors.white.withAlpha((255 * 0.05).round())),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Dosis Terpilih', style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.primaryText),
              children: [
                TextSpan(
                  text: '$dosage',
                  style: AppTheme.displayLarge.copyWith(fontWeight: FontWeight.w700)
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: 'gram',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.secondaryText, 
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ControlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            border: Border.all(color: Colors.white.withAlpha((255 * 0.08).round())),
          ),
          child: Icon(icon, color: AppTheme.primaryText, size: 24),
        ),
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
