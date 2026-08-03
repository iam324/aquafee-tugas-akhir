import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/schedule_provider.dart';
import '../theme.dart';

class ScheduleCard extends ConsumerWidget {
  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final FeedingSchedule schedule;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = schedule.active;
    final timeString = schedule.time;
    final label = schedule.label ?? '';
    final days = schedule.days;

    final List<String> dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final activeDays = days
        .asMap()
        .entries
        .where((entry) => entry.value)
        .map((entry) => dayNames[entry.key])
        .toList();
    final daysString = activeDays.isEmpty
        ? 'Never'
        : (activeDays.length == 7
            ? 'Everyday'
            : activeDays.length == 1
                ? activeDays.first
                : activeDays.join(', '));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: Colors.white.withAlpha((255 * 0.08).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: AppTheme.accent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          timeString,
                          style: AppTheme.displayMedium.copyWith(
                            color: AppTheme.primaryText,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (label.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  Switch(
                    value: isActive,
                    activeTrackColor: AppTheme.statusOnline,
                    onChanged: (value) => onToggle(value),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.accent, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Edit Schedule',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.error, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Delete Schedule',
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.white12),
          Row(
            children: [
              const Icon(Icons.repeat, color: AppTheme.secondaryText, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  daysString,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddScheduleButton extends ConsumerWidget {
  const AddScheduleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: () => _showAddScheduleDialog(context, ref),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add Schedule'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          ),
        ),
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController labelController = TextEditingController();

    TimeOfDay selectedTime = TimeOfDay.now();
    List<bool> selectedDays = List.filled(7, true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppTheme.background,
          title: Text(
            'Tambah Jadwal Pakan',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.primaryText),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TIME PICKER BUTTON
                InkWell(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: dialogContext,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setStateDialog(() {
                        selectedTime = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                      border: Border.all(color: AppTheme.accent.withAlpha((255 * 0.5).round())),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_filled, color: AppTheme.accent, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              style: AppTheme.displayMedium.copyWith(
                                color: AppTheme.primaryText,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Pilih Jam',
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.accent),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    labelText: 'Label (Contoh: Pakan Pagi)',
                    labelStyle: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryText),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withAlpha((255 * 0.3).round())),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.accent),
                    ),
                  ),
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.primaryText),
                ),
                const SizedBox(height: 20),
                Text(
                  'Hari Pengulangan:',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryText, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(7, (index) {
                    final dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
                    final isSel = selectedDays[index];
                    return FilterChip(
                      label: Text(
                        dayNames[index],
                        style: TextStyle(
                          color: isSel ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSel,
                      onSelected: (val) {
                        setStateDialog(() {
                          selectedDays[index] = val;
                        });
                      },
                      backgroundColor: AppTheme.surface,
                      selectedColor: AppTheme.accent,
                      showCheckmark: false,
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Batal', style: AppTheme.bodySmall.copyWith(color: AppTheme.error)),
            ),
            ElevatedButton(
              onPressed: () async {
                final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                final label = labelController.text.trim();

                try {
                  await ref.read(scheduleProvider.notifier).addSchedule(
                    timeStr,
                    25, // default hidden dosage
                    label: label.isNotEmpty ? label : null,
                    days: selectedDays,
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Gagal menyimpan jadwal: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusOnline,
                foregroundColor: Colors.black,
              ),
              child: const Text('Simpan Jadwal'),
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleView extends ConsumerWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(scheduleProvider);
    final isLoading = scheduleState.lastError != null && scheduleState.schedules.isEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: Colors.white.withAlpha((255 * 0.05).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: AppTheme.accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'JADWAL PAKAN OTOMATIS',
                        style: AppTheme.titleSmall.copyWith(color: AppTheme.accent, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const AddScheduleButton(),
            ],
          ),
          const SizedBox(height: 20),
          if (isLoading && scheduleState.lastError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha((255 * 0.15).round()),
                borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              ),
              child: Text(
                'Error: ${scheduleState.lastError}',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.error),
              ),
            )
          else if (scheduleState.schedules.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.alarm_off,
                    size: 44,
                    color: AppTheme.secondaryText.withAlpha((255 * 0.5).round()),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum Ada Jadwal Pakan',
                    style: AppTheme.titleMedium.copyWith(color: AppTheme.secondaryText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Klik tombol "+ Add Schedule" untuk menambah jam pakan otomatis',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryText),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: scheduleState.schedules.length,
              itemBuilder: (context, index) {
                final schedule = scheduleState.schedules[index];
                return ScheduleCard(
                  schedule: schedule,
                  onEdit: () => _showEditScheduleDialog(context, ref, schedule),
                  onToggle: (active) => ref.read(scheduleProvider.notifier).toggleSchedule(schedule.id, active),
                  onDelete: () => ref.read(scheduleProvider.notifier).deleteSchedule(schedule.id),
                );
              },
            ),
          const SizedBox(height: 16),
          // NEXT SCHEDULE CARD
          Consumer(
            builder: (context, ref, _) {
              final nextSchedule = ref.read(scheduleProvider.notifier).getNextScheduledFeeding();
              if (nextSchedule == null) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                  border: Border.all(color: Colors.white.withAlpha((255 * 0.08).round())),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jadwal Pakan Berikutnya',
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.accent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextSchedule.time,
                          style: AppTheme.displayMedium.copyWith(
                            color: AppTheme.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nextSchedule.label?.isNotEmpty == true
                              ? nextSchedule.label!
                              : 'Jadwal Pakan Otomatis',
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryText),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditScheduleDialog(BuildContext context, WidgetRef ref, FeedingSchedule schedule) {
    final TextEditingController labelController = TextEditingController(text: schedule.label ?? '');

    // Parse HH:mm from schedule.time
    final parts = schedule.time.split(':');
    int initialHour = int.tryParse(parts[0]) ?? 8;
    int initialMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    TimeOfDay selectedTime = TimeOfDay(hour: initialHour, minute: initialMinute);

    List<bool> selectedDays = List<bool>.from(schedule.days);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppTheme.background,
          title: Text(
            'Edit Jadwal Pakan',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.primaryText),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TIME PICKER BUTTON
                InkWell(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: dialogContext,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setStateDialog(() {
                        selectedTime = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                      border: Border.all(color: AppTheme.accent.withAlpha((255 * 0.5).round())),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_filled, color: AppTheme.accent, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              style: AppTheme.displayMedium.copyWith(
                                color: AppTheme.primaryText,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Ubah Jam',
                          style: AppTheme.bodySmall.copyWith(color: AppTheme.accent),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    labelText: 'Label (Opsional)',
                    labelStyle: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryText),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withAlpha((255 * 0.3).round())),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.accent),
                    ),
                  ),
                  style: AppTheme.bodyLarge.copyWith(color: AppTheme.primaryText),
                ),
                const SizedBox(height: 20),
                Text(
                  'Hari Pengulangan:',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryText, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(7, (index) {
                    final dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
                    final isSel = selectedDays[index];
                    return FilterChip(
                      label: Text(
                        dayNames[index],
                        style: TextStyle(
                          color: isSel ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSel,
                      onSelected: (val) {
                        setStateDialog(() {
                          selectedDays[index] = val;
                        });
                      },
                      backgroundColor: AppTheme.surface,
                      selectedColor: AppTheme.accent,
                      showCheckmark: false,
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Batal', style: AppTheme.bodySmall.copyWith(color: AppTheme.error)),
            ),
            ElevatedButton(
              onPressed: () async {
                final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                final label = labelController.text.trim();

                final updatedSchedule = schedule.copyWith(
                  time: timeStr,
                  dosage: schedule.dosage,
                  label: label.isNotEmpty ? label : null,
                  days: selectedDays,
                );

                try {
                  await ref.read(scheduleProvider.notifier).updateSchedule(schedule.id, updatedSchedule);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Gagal memperbarui jadwal: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusOnline,
                foregroundColor: Colors.black,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}