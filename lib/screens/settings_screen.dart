import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final activeTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.colors.primaryText, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: AppTheme.colors.headlineMedium,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionHeader('APPEARANCE'),
          const SizedBox(height: 12),
          _buildThemeSelector(activeTheme),
          const SizedBox(height: 32),
          _buildSectionHeader('SYSTEM INFO'),
          const SizedBox(height: 12),
          _buildAppInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTheme.colors.titleSmall.copyWith(letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildThemeSelector(AppThemeColors activeTheme) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.colors.radiusCard),
        border: Border.all(color: AppTheme.colors.isDark ? Colors.white.withAlpha((255 * 0.05).round()) : Colors.black.withAlpha((255 * 0.05).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App Theme', style: AppTheme.colors.titleLarge),
                const SizedBox(height: 4),
                Text('Pilih tema tampilan aplikasi', style: AppTheme.colors.bodySmall),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          ...AppTheme.availableThemes.map((theme) {
            final isSelected = theme.name == activeTheme.name;
            return InkWell(
              onTap: () {
                ref.read(themeProvider.notifier).setTheme(theme);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? theme.accent.withAlpha((255 * 0.1).round()) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.accent, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: theme.surface,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        theme.name,
                        style: AppTheme.colors.bodyLarge.copyWith(
                          color: isSelected ? theme.accent : AppTheme.colors.primaryText,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: theme.accent),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.colors.radiusCard),
        border: Border.all(color: AppTheme.colors.isDark ? Colors.white.withAlpha((255 * 0.05).round()) : Colors.black.withAlpha((255 * 0.05).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.colors.accent.withAlpha((255 * 0.15).round()),
                  borderRadius: BorderRadius.circular(AppTheme.colors.radiusButton),
                ),
                child: Icon(Icons.water_drop_rounded, color: AppTheme.colors.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AquaFeed Pro', style: AppTheme.colors.titleLarge),
                  const SizedBox(height: 4),
                  Text('Version 1.0.0 (Stable)', style: AppTheme.colors.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Industrial-grade IoT monitoring and automatic feeding system designed for smart aquaculture management.',
            style: AppTheme.colors.bodyMedium,
          ),
        ],
      ),
    );
  }
}