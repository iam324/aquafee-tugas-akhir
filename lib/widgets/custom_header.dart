import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/device_provider.dart';
import '../screens/settings_screen.dart';
import '../theme.dart';

class CustomHeader extends ConsumerWidget {
  const CustomHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(deviceProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AquaFeed',
                style: AppTheme.displaySmall.copyWith(color: AppTheme.primaryText),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _StatusIndicator(isActive: deviceState.isFirebaseConnected),
                  const SizedBox(width: 8),
                  Text(
                    deviceState.isFirebaseConnected ? 'System Online' : 'System Offline',
                    style: AppTheme.labelMedium.copyWith(
                      color: deviceState.isFirebaseConnected 
                          ? AppTheme.statusOnline
                          : AppTheme.secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _HeaderActionBtn(
                icon: Icons.notifications_outlined,
                onTap: () {},
              ),
              const SizedBox(width: 10),
              _HeaderActionBtn(
                icon: Icons.settings_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isActive;
  const _StatusIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.statusOnline : AppTheme.error,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          border: Border.all(color: Colors.white.withAlpha((255 * 0.05).round())),
        ),
        child: Icon(
          icon,
          color: AppTheme.secondaryText,
          size: 22,
        ),
      ),
    );
  }
}
