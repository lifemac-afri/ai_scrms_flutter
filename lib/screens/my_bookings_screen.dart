import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});
  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Booking> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final b = await ApiService.myBookings();
    if (mounted) setState(() { _all = b; _loading = false; });
  }

  List<Booking> _filter(List<String> statuses) =>
      _all.where((b) => statuses.contains(b.bookingStatus)).toList();

  Future<void> _cancel(Booking b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Cancel Booking?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Cancel booking for ${b.resourceName} on ${b.bookingDate}?',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, Cancel', style: TextStyle(color: AppTheme.red))),
        ],
      ),
    );
    if (confirm == true) {
      final res = await ApiService.cancelBooking(b.bookingId);
      if (res['success'] == true) {
        if (mounted) showSuccess(context, 'Booking cancelled');
        _load();
      } else {
        if (mounted) showError(context, res['error'] ?? 'Failed');
      }
    }
  }

  void _showQr(Booking b) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(b.resourceName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Text('${b.bookingDate}  ${b.timeRange}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: b.qrCode,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Scan at the resource to check in',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Text(b.qrCode,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.bgCard,
          child: TabBar(
            controller: _tab,
            dividerColor: AppTheme.bgCardBorder,
            indicatorColor: AppTheme.teal,
            labelColor: AppTheme.teal,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : TabBarView(
                  controller: _tab,
                  children: [
                    _list(_filter(['confirmed', 'active']), showActions: true),
                    _list(_filter(['completed', 'no_show'])),
                    _list(_filter(['cancelled'])),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _list(List<Booking> items, {bool showActions = false}) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_late_rounded,
        title: 'No Bookings Here',
        subtitle: 'Your bookings will appear here',
      );
    }
    return RefreshIndicator(
      color: AppTheme.teal,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: items.length,
        itemBuilder: (_, i) => BookingCard(
          booking: items[i],
          onCancel: showActions ? () => _cancel(items[i]) : null,
          onQr: showActions && items[i].qrCode.isNotEmpty ? () => _showQr(items[i]) : null,
        ),
      ),
    );
  }
}
