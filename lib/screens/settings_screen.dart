import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
import '../providers/demo_mode_provider.dart';

import '../theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isReminderEnabled = false;
  TimeOfDay? _reminderTime;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isReminderEnabled = prefs.getBool('feeding_reminder_enabled') ?? false;
        final hour = prefs.getInt('feeding_reminder_hour') ?? 8;
        final minute = prefs.getInt('feeding_reminder_minute') ?? 0;
        _reminderTime = TimeOfDay(hour: hour, minute: minute);
      });
    } catch (e) {
      // Error loading settings
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveReminderSettings(bool enabled, TimeOfDay? time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('feeding_reminder_enabled', enabled);
    if (time != null) {
      await prefs.setInt('feeding_reminder_hour', time.hour);
      await prefs.setInt('feeding_reminder_minute', time.minute);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accent,
              surface: AppTheme.surfaceLight,
              onSurface: AppTheme.primaryText,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppTheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      await _saveReminderSettings(_isReminderEnabled, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _BackBtn(onTap: () => Navigator.of(context).pop()),
        title: Text('Settings', style: AppTheme.headlineMedium),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildSectionHeader('Automations'),
                  _buildReminderCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Testing'),
                  _buildDemoModeCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Storage Management'),
                  _buildStockCard(feedState),
                  const SizedBox(height: 24),
                  _buildSectionHeader('System Info'),
                  _buildAboutCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: AppTheme.titleSmall,
      ),
    );
  }

  Widget _buildReminderCard() {
    return _SettingsCard(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Daily Reminder', style: AppTheme.titleMedium),
            subtitle: Text(
              _isReminderEnabled && _reminderTime != null
                  ? 'Remind every day at ${_reminderTime!.format(context)}'
                  : 'Get notified when it\'s feeding time',
              style: AppTheme.bodySmall,
            ),
            value: _isReminderEnabled,
            onChanged: (value) async {
              setState(() => _isReminderEnabled = value);
              await _saveReminderSettings(value, _reminderTime);
            },
            activeColor: AppTheme.accent,
          ),
          if (_isReminderEnabled) ...[
            const Divider(height: 32, color: AppTheme.surfaceLight),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.accent.withAlpha((255 * 0.1).round()), borderRadius: BorderRadius.circular(AppTheme.radiusInput)),
                child: const Icon(Icons.access_time_outlined, color: AppTheme.accent, size: 20),
              ),
              title: Text('Reminder Time', style: AppTheme.bodyMedium),
              trailing: Text(
                _reminderTime?.format(context) ?? '-',
                style: AppTheme.labelLarge.copyWith(color: AppTheme.accent),
              ),
              onTap: _selectTime,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDemoModeCard() {
    final isDemoMode = ref.watch(demoModeProvider);
    return _SettingsCard(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Text('Demo Mode', style: AppTheme.titleMedium),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withAlpha((255 * 0.2).round()),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Text(
                    'TESTING',
                    style: AppTheme.labelMedium.copyWith(
                      color: AppTheme.warning,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              isDemoMode
                  ? 'Aktif: Tombol pakan berfungsi tanpa ESP32'
                  : 'Nonaktif: Tombol pakan hanya aktif saat alat online',
              style: AppTheme.bodySmall,
            ),
            value: isDemoMode,
            onChanged: (value) async {
              await ref.read(demoModeProvider.notifier).toggleDemoMode();
            },
            activeColor: AppTheme.warning,
          ),
          const Divider(height: 32, color: AppTheme.surfaceLight),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warning.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              ),
              child: const Icon(Icons.science_outlined, color: AppTheme.warning, size: 20),
            ),
            title: Text('Mode Pengujian', style: AppTheme.bodyMedium),
            subtitle: Text(
              'Digunakan untuk demo TA tanpa hardware',
              style: AppTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(FeedState feedState) {
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.warning.withAlpha((255 * 0.1).round()), borderRadius: BorderRadius.circular(AppTheme.radiusInput)),
                child: const Icon(Icons.inventory_2_outlined, color: AppTheme.warning, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reset Food Stock', style: AppTheme.titleMedium),
                    Text('Refill the inventory to maximum', style: AppTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ActionBtn(
            label: 'Refill to ${feedState.maxCapacity.toInt()}g',
            icon: Icons.refresh_rounded,
            color: AppTheme.warning,
            onTap: () async {
              await ref.read(feedProvider.notifier).resetStock();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Inventory refilled successfully'),
                    backgroundColor: AppTheme.statusOnline,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusButton)),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return _SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                ),
                child: const Icon(Icons.eco_outlined, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AquaFeed Pro', style: AppTheme.titleLarge),
                  Text('Version 1.0.0 (Stable)', style: AppTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Industrial-grade IoT monitoring and automatic feeding system designed for smart aquaculture management.',
            style: AppTheme.bodySmall.copyWith(height: 1.6),
          ),
          const Divider(height: 32, color: AppTheme.surfaceLight),
          _InfoRow(label: 'Platform', value: 'Flutter + Riverpod'),
          _InfoRow(label: 'Backend', value: 'Firebase RTDB'),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: Colors.white.withAlpha((255 * 0.05).round())),
      ),
      child: child,
    );
  }
}

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryText, size: 18),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withAlpha((255 * 0.1).round()),
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            border: Border.all(color: color.withAlpha((255 * 0.2).round())),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: AppTheme.labelLarge.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodySmall),
          Text(value, style: AppTheme.labelMedium.copyWith(color: AppTheme.secondaryText)),
        ],
      ),
    );
  }
}