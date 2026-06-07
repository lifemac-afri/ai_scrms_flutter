import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
// ALL BOOKINGS (Admin)
// ─────────────────────────────────────────────
class AllBookingsScreen extends StatefulWidget {
  const AllBookingsScreen({super.key});
  @override
  State<AllBookingsScreen> createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends State<AllBookingsScreen> {
  List<Booking> _bookings = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final b = await ApiService.allBookings();
    if (mounted) setState(() { _bookings = b; _loading = false; });
  }

  List<Booking> get _filtered {
    if (_search.isEmpty) return _bookings;
    final q = _search.toLowerCase();
    return _bookings.where((b) =>
        b.resourceName.toLowerCase().contains(q) ||
        b.bookingDate.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.bgCard,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            style: const TextStyle(color: AppTheme.textPrimary),
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(hintText: 'Search bookings…'),
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : _filtered.isEmpty
                  ? const EmptyState(icon: Icons.event_busy_rounded, title: 'No Bookings', subtitle: '')
                  : RefreshIndicator(
                      color: AppTheme.teal,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final b = _filtered[i];
                          return AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text(b.resourceName,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
                                  StatusBadge(b.bookingStatus),
                                ]),
                                const SizedBox(height: 6),
                                Text('${b.building} ${b.roomNumber}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                Text('${b.bookingDate}  ${b.timeRange}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                if (b.purpose.isNotEmpty)
                                  Text(b.purpose, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// MANAGE RESOURCES (Admin)
// ─────────────────────────────────────────────
class ManageResourcesScreen extends StatefulWidget {
  const ManageResourcesScreen({super.key});
  @override
  State<ManageResourcesScreen> createState() => _ManageResourcesScreenState();
}

class _ManageResourcesScreenState extends State<ManageResourcesScreen> {
  List<Resource> _resources = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ApiService.getAllResources();
    if (mounted) setState(() { _resources = r; _loading = false; });
  }

  Future<void> _changeStatus(Resource r) async {
    final options = ['available', 'under_maintenance', 'decommissioned'];
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text('Update Status: ${r.resourceName}',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((s) {
            final selected = r.conditionStatus == s;
            return ListTile(
              title: Text(s.replaceAll('_', ' '),
                  style: const TextStyle(color: AppTheme.textPrimary)),
              leading: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppTheme.teal : AppTheme.textSecondary,
              ),
              onTap: () => Navigator.pop(ctx, s),
            );
          }).toList(),
        ),
      ),
    );
    if (picked != null && picked != r.conditionStatus) {
      final res = await ApiService.updateResourceStatus(r.resourceId, picked);
      if (res['success'] == true) {
        if (mounted) showSuccess(context, 'Status updated');
        _load();
      }
    }
  }

  Future<void> _addResource() async {
    final nameCtrl = TextEditingController();
    final buildingCtrl = TextEditingController();
    final floorCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '1');
    String type = 'classroom';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (innerCtx, setInner) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text('Add Resource', style: TextStyle(color: AppTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Resource Name')),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Type'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: type,
                      dropdownColor: AppTheme.bgCard,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      items: ['classroom', 'laboratory', 'equipment', 'event_space', 'sports_facility', 'study_room']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' '))))
                          .toList(),
                      onChanged: (v) => setInner(() => type = v ?? 'classroom'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: buildingCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Building'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: floorCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Floor'))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: roomCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Room No.'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: capCtrl, keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(labelText: 'Capacity'))),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(innerCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final res = await ApiService.addResource({
                  'resource_name': nameCtrl.text,
                  'resource_type': type,
                  'building': buildingCtrl.text,
                  'floor': floorCtrl.text,
                  'room_number': roomCtrl.text,
                  'capacity': int.tryParse(capCtrl.text) ?? 1,
                });
                if (res['success'] == true) {
                  if (innerCtx.mounted) {
                    Navigator.pop(innerCtx);
                    showSuccess(innerCtx, 'Resource added');
                  }
                  _load();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingWidget();
    return Stack(
      children: [
        RefreshIndicator(
          color: AppTheme.teal,
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: _resources.length,
            itemBuilder: (_, i) {
              final r = _resources[i];
              return AppCard(
                child: Row(
                  children: [
                    Icon(r.typeIcon, size: 28, color: AppTheme.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.resourceName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          Text(r.location, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          Text('Cap: ${r.capacity}  ·  ${r.typeLabel}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    StatusBadge(r.conditionStatus),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary, size: 20),
                      onPressed: () => _changeStatus(r),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 16, right: 16,
          child: FloatingActionButton.extended(
            onPressed: _addResource,
            backgroundColor: AppTheme.teal,
            foregroundColor: AppTheme.bgDark,
            icon: const Icon(Icons.add),
            label: const Text('Add Resource', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// USERS (Super Admin)
// ─────────────────────────────────────────────
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final u = await ApiService.usersList();
    if (mounted) setState(() { _users = u; _loading = false; });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _users;
    final q = _search.toLowerCase();
    return _users.where((u) =>
        (u['full_name'] ?? '').toLowerCase().contains(q) ||
        (u['email'] ?? '').toLowerCase().contains(q) ||
        (u['role'] ?? '').toLowerCase().contains(q)).toList();
  }

  Future<void> _updateStatus(Map<String, dynamic> u, String status) async {
    final res = await ApiService.updateUserStatus(int.tryParse(u['user_id'].toString()) ?? 0, status);
    if (res['success'] == true) {
      if (mounted) showSuccess(context, 'Status updated');
      _load();
    }
  }

  Color _roleColor(String role) => switch (role) {
    'super_admin' => AppTheme.red,
    'facility_manager' => AppTheme.purple,
    'faculty' => AppTheme.teal,
    'maintenance' => AppTheme.amber,
    _ => AppTheme.blue,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.bgCard,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            style: const TextStyle(color: AppTheme.textPrimary),
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(hintText: 'Search users…'),
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : RefreshIndicator(
                  color: AppTheme.teal,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final u = _filtered[i];
                      final role = u['role'] ?? '';
                      final status = u['account_status'] ?? 'active';
                      return AppCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _roleColor(role).withValues(alpha: 0.2),
                              child: Text(
                                (u['full_name'] ?? '?')[0].toUpperCase(),
                                style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u['full_name'] ?? '',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                  Text(u['email'] ?? '',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      StatusBadge(role),
                                      StatusBadge(status),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              color: AppTheme.bgCard,
                              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                              onSelected: (v) => _updateStatus(u, v),
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'active', child: Text('Set Active', style: TextStyle(color: AppTheme.textPrimary))),
                                const PopupMenuItem(value: 'suspended', child: Text('Suspend', style: TextStyle(color: AppTheme.amber))),
                                const PopupMenuItem(value: 'deactivated', child: Text('Deactivate', style: TextStyle(color: AppTheme.red))),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// AUDIT LEDGER (Admin)
// ─────────────────────────────────────────────
class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});
  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final l = await ApiService.auditLog();
    if (mounted) setState(() { _logs = l; _loading = false; });
  }

  Color _eventColor(String type) => switch (type) {
    'LOGIN' || 'LOGOUT' => AppTheme.blue,
    'BOOKING_CREATED' => AppTheme.teal,
    'BOOKING_CANCELLED' => AppTheme.red,
    'CHECKIN' => AppTheme.green,
    'FAULT_REPORTED' => AppTheme.amber,
    'MAINT_RESOLVED' => AppTheme.green,
    'RESOURCE_ADDED' => AppTheme.purple,
    _ => AppTheme.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingWidget();
    return RefreshIndicator(
      color: AppTheme.teal,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _logs.length,
        itemBuilder: (_, i) {
          final log = _logs[i];
          final type = log['event_type'] ?? '';
          final color = _eventColor(type);
          return AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 5, right: 12),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(type,
                            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        const Spacer(),
                        Text(log['event_timestamp'] ?? '',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      ]),
                      const SizedBox(height: 4),
                      Text(log['event_description'] ?? '',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                      if (log['full_name'] != null)
                        Text('By: ${log['full_name']}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
