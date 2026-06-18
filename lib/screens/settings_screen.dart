import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/feed_provider.dart';
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
      print('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
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
              onPrimary: Colors.white,
              surface: AppTheme.surface,
            ),
            dialogBackgroundColor: AppTheme.surface,
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

  Future<void> _resetStock() async {
    final feedNotifier = ref.read(feedProvider.notifier);
    await feedNotifier.resetStock();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok pakan direset ke kapasitas maksimum'),
          backgroundColor: AppTheme.success,
        ),
      );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pengaturan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Pemberian Pakan Otomatis'),
                  const SizedBox(height: 12),
                  _buildReminderCard(),
                  const SizedBox(height: 24),
                  _buildSection('Manajemen Stok'),
                  const SizedBox(height: 12),
                  _buildStockCard(feedState),
                  const SizedBox(height: 24),
                  _buildSection('Tentang Aplikasi'),
                  const SizedBox(height: 12),
                  _buildAboutCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTheme.titleSmall.copyWith(color: AppTheme.secondaryText),
    );
  }

  Widget _buildReminderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBg, width: 1),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Aktifkan Reminder Harian',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
            subtitle: Text(
              _isReminderEnabled && _reminderTime != null
                  ? 'Setiap hari: ${_reminderTime!.format(context)}'
                  : 'Nonaktif',
              style: AppTheme.captionSmall,
            ),
            value: _isReminderEnabled,
            onChanged: (value) async {
              setState(() => _isReminderEnabled = value);
              await _saveReminderSettings(value, _reminderTime);
            },
            activeColor: AppTheme.accent,
          ),
          if (_isReminderEnabled) ...[
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Waktu Reminder',
                style: AppTheme.bodyMedium.copyWith(color: Colors.white),
              ),
              trailing: Text(
                _reminderTime?.format(context) ?? '-',
                style: AppTheme.labelMedium.copyWith(color: AppTheme.accent),
              ),
              onTap: _selectTime,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockCard(FeedState feedState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBg, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppTheme.warning, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset Stok Pakan',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white),
                ),
                Text(
                  'Current: ${feedState.currentStock.toInt()}g / ${feedState.maxCapacity.toInt()}g',
                  style: AppTheme.captionSmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _resetStock,
            child: Text(
              'RESET',
              style: AppTheme.labelMedium.copyWith(color: AppTheme.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBg, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AquaFeed v1.0.0',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.accent),
          ),
          const SizedBox(height: 8),
          Text(
            'Aplikasi monitoring dan kontrol pemberian pakan otomatis untuk sistem IoT budidaya.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 4),
          Text(
            'Dibuat dengan Flutter & Riverpod',
            style: AppTheme.captionSmall,
          ),
        ],
      ),
    );
  }
}