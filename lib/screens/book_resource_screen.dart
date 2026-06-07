import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

class BookResourceScreen extends StatefulWidget {
  final Resource resource;
  const BookResourceScreen({super.key, required this.resource});

  @override
  State<BookResourceScreen> createState() => _BookResourceScreenState();
}

class _BookResourceScreenState extends State<BookResourceScreen> {
  final _purpose = TextEditingController();
  String _date = _today();
  String _start = '09:00';
  String _end = '11:00';
  bool _loading = false;

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Compares `HH:mm` strings by clock order.
  static int _timeToMinutes(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  Future<void> _book() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_timeToMinutes(_start) >= _timeToMinutes(_end)) {
      showError(context, 'End time must be after start time');
      return;
    }
    setState(() => _loading = true);
    final res = await ApiService.book(
      resourceId: widget.resource.resourceId,
      date: _date,
      startTime: '$_start:00',
      endTime: '$_end:00',
      purpose: _purpose.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      showSuccess(context, 'Booking confirmed! QR code generated.');
      Navigator.pop(context, true);
    } else if (res['waitlisted'] == true) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text('Added to Waitlist', style: TextStyle(color: AppTheme.textPrimary)),
          content: Text(res['message'] ?? 'You have been added to the waitlist.',
              style: const TextStyle(color: AppTheme.textSecondary)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, true);
              },
              child: const Text('OK', style: TextStyle(color: AppTheme.teal)),
            ),
          ],
        ),
      );
    } else {
      showError(context, res['error'] ?? 'Booking failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resource;
    return Scaffold(
      appBar: AppBar(title: Text('Book ${r.resourceName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resource info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(r.typeIcon, size: 36, color: AppTheme.teal),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.resourceName,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 4),
                        Text(r.location,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Capacity: ${r.capacity}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date
            const Text('Date', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.bgCardBorder),
                ),
                child: Text(_date, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 16),

            // Time
            const Text('Time', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _timePicker('Start', _start, (v) => setState(() => _start = v))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('→', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
                ),
                Expanded(child: _timePicker('End', _end, (v) => setState(() => _end = v))),
              ],
            ),
            const SizedBox(height: 16),

            // Purpose
            const Text('Purpose (optional)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _purpose,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: 'e.g. CS101 Lecture, Group Study…',
              ),
            ),
            const SizedBox(height: 16),

            // Features
            if (r.features.isNotEmpty) ...[
              const Text('Features',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: r.features.entries
                    .where((e) => e.value == true)
                    .map((e) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.bgCardBorder),
                          ),
                          child: Text(
                              e.key.replaceAll('_', ' '),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _book,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Confirm Booking →'),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'If this slot is taken, you\'ll be added to the waitlist automatically',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePicker(String label, String value, Function(String) onChanged) {
    return InkWell(
      onTap: () async {
        final parts = value.split(':');
        final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        final picked = await showTimePicker(context: context, initialTime: initial);
        if (picked != null) {
          onChanged('${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.bgCardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.teal),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _date =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }
}
