import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

class WaitlistScreen extends StatefulWidget {
  const WaitlistScreen({super.key});
  @override
  State<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends State<WaitlistScreen> {
  List<WaitlistItem> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await ApiService.myWaitlist();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  IconData _typeIcon(String t) => switch (t) {
    'classroom' => Icons.school_rounded,
    'laboratory' => Icons.biotech_rounded,
    'equipment' => Icons.computer_rounded,
    'event_space' => Icons.event_seat_rounded,
    'sports_facility' => Icons.sports_soccer_rounded,
    'study_room' => Icons.library_books_rounded,
    _ => Icons.business_rounded,
  };

  String _fmtTime(String t) {
    if (t.isEmpty) return '';
    final parts = t.split(':');
    if (parts.length < 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$h12:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingWidget();
    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.hourglass_empty_rounded,
        title: 'No Waitlist Entries',
        subtitle: 'When a booking slot is taken, you\'ll be added to the waitlist automatically',
      );
    }
    return RefreshIndicator(
      color: AppTheme.teal,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                AiChip(label: '✦ AI Priority Queue'),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Role-based priority scoring — faculty outranks students',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          ..._items.map((w) => AppCard(
                borderColor: AppTheme.amber.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_typeIcon(w.resourceType), size: 28, color: AppTheme.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w.resourceName,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary)),
                              Text(w.building,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'Priority: ${w.priorityScore}/10',
                            style: const TextStyle(
                                color: AppTheme.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(w.requestedDate,
                            style:
                                const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time_outlined,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                            '${_fmtTime(w.requestedStart)} – ${_fmtTime(w.requestedEnd)}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You\'ll be notified automatically if a slot opens up',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
