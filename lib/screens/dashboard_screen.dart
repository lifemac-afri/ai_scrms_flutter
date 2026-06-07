import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';
import 'book_resource_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AnalyticsData? _analytics;
  List<Booking> _myBookings = [];
  List<Resource> _recommendations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = context.read<AuthProvider>().user;
    if (user?.isAdmin ?? false) {
      final a = await ApiService.analytics();
      final r = await ApiService.recommendations();
      if (mounted) setState(() { _analytics = a; _recommendations = r; _loading = false; });
    } else {
      final b = await ApiService.myBookings();
      final r = await ApiService.recommendations();
      if (mounted) setState(() { _myBookings = b; _recommendations = r; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (_loading) return const LoadingWidget();
    return RefreshIndicator(
      color: AppTheme.teal,
      onRefresh: _load,
      child: user?.isAdmin ?? false ? _adminDash(user!) : _userDash(user!),
    );
  }

  Widget _adminDash(User user) {
    final a = _analytics;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SectionHeader(
          title: 'Welcome back, ${user.fullName.split(' ').first} 👋',
          subtitle: "Here's your campus resource overview",
          trailing: const AiChip(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              StatCard(icon: Icons.calendar_today_rounded, value: a?.totalBookings ?? 0, label: 'Bookings This Month', color: AppTheme.teal),
              StatCard(icon: Icons.business_rounded, value: a?.totalResources ?? 0, label: 'Active Resources', color: AppTheme.amber),
              StatCard(icon: Icons.people_rounded, value: a?.activeUsers ?? 0, label: 'Active Users', color: AppTheme.green),
              StatCard(icon: Icons.cancel_rounded, value: a?.noShows ?? 0, label: 'No-Shows', color: AppTheme.red),
              StatCard(icon: Icons.build_rounded, value: a?.pendingMaintenance ?? 0, label: 'Maintenance', color: AppTheme.purple),
              StatCard(icon: Icons.hourglass_empty_rounded, value: a?.waitlisted ?? 0, label: 'On Waitlist', color: AppTheme.blue),
            ],
          ),
        ),
        if (a?.topResources.isNotEmpty ?? false) ...[
          const SizedBox(height: 16),
          const SectionHeader(title: '🔥 Top Resources', subtitle: 'Most booked in last 30 days'),
          ...a!.topResources.map((r) => AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(r['resource_name'] ?? '',
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${r['cnt']} bookings',
                          style: const TextStyle(color: AppTheme.teal, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              )),
        ],
        if (_recommendations.isNotEmpty) ...[
          const SizedBox(height: 8),
          const SectionHeader(title: '🤖 AI Recommendations', trailing: AiChip(label: '✦ Personalised')),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recommendations.length,
              itemBuilder: (_, i) => _recCard(_recommendations[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _userDash(User user) {
    final upcoming = _myBookings.where((b) => b.isActive).toList();
    final completed = _myBookings.where((b) => b.bookingStatus == 'completed').length;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SectionHeader(
          title: 'Hello, ${user.fullName.split(' ').first} 👋',
          subtitle: 'Your campus resource hub',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
            children: [
              StatCard(icon: Icons.calendar_month_rounded, value: upcoming.length, label: 'Upcoming', color: AppTheme.teal),
              StatCard(icon: Icons.check_circle_rounded, value: completed, label: 'Completed', color: AppTheme.green),
              StatCard(icon: Icons.report_problem_rounded, value: user.noShowCount, label: 'No-Shows', color: AppTheme.red),
            ],
          ),
        ),
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionHeader(title: '⏰ Upcoming Bookings'),
          ...upcoming.take(3).map((b) => BookingCard(
                booking: b,
                onQr: () => _showQr(b),
              )),
        ],
        if (_recommendations.isNotEmpty) ...[
          const SizedBox(height: 8),
          const SectionHeader(title: '🤖 AI Recommendations', trailing: AiChip(label: '✦ Personalised')),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recommendations.length,
              itemBuilder: (_, i) => _recCard(_recommendations[i]),
            ),
          ),
        ],
        if (upcoming.isEmpty && _recommendations.isEmpty)
          const EmptyState(
            icon: Icons.layers_clear_rounded,
            title: 'No Activity Yet',
            subtitle: 'Browse resources and make your first booking!',
          ),
      ],
    );
  }

  Widget _recCard(Resource r) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => BookResourceScreen(resource: r)));
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.teal.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(r.typeIcon, size: 24, color: AppTheme.teal),
            const SizedBox(height: 8),
            Text(r.resourceName,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            Text('Cap: ${r.capacity}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
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
}
