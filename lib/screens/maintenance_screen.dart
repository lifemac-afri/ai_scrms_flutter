import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});
  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  List<MaintenanceRequest> _requests = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ApiService.maintenanceList();
    if (mounted) setState(() { _requests = r; _loading = false; });
  }

  Future<void> _resolve(MaintenanceRequest req) async {
    final notesCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Resolve Request', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Resolving: ${req.resourceName}',
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 1,
              decoration: const InputDecoration(labelText: 'Resolution Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final res = await ApiService.resolveMaintenance(req.requestId, notesCtrl.text);
      if (res['success'] == true) {
        if (mounted) showSuccess(context, 'Request resolved');
        _load();
      }
    }
  }

  Future<void> _reportFault() async {
    final resources = await ApiService.getAllResources();
    if (!mounted) return;
    int? selectedResource;
    String selectedSeverity = 'medium';
    final descCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (innerCtx, setInner) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text('Report Fault', style: TextStyle(color: AppTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Resource'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: selectedResource,
                      hint: const Text('Select resource', style: TextStyle(color: AppTheme.textMuted)),
                      dropdownColor: AppTheme.bgCard,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      items: resources
                          .map((r) => DropdownMenuItem(
                                value: r.resourceId,
                                child: Text(r.resourceName),
                              ))
                          .toList(),
                      onChanged: (v) => setInner(() => selectedResource = v),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  maxLines: 1,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Severity'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedSeverity,
                      dropdownColor: AppTheme.bgCard,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'critical', child: Text('Critical')),
                      ],
                      onChanged: (v) => setInner(() => selectedSeverity = v ?? 'medium'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(innerCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedResource == null || descCtrl.text.isEmpty) return;
                final res = await ApiService.reportFault(
                  resourceId: selectedResource!,
                  description: descCtrl.text,
                  severity: selectedSeverity,
                );
                if (res['success'] == true) {
                  if (innerCtx.mounted) {
                    Navigator.pop(innerCtx);
                    showSuccess(innerCtx, 'Fault reported');
                  }
                  _load();
                }
              },
              child: const Text('Report'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (_loading) return const LoadingWidget();
    return Stack(
      children: [
        _requests.isEmpty
            ? const EmptyState(
                icon: Icons.build_circle_rounded,
                title: 'No Maintenance Requests',
                subtitle: 'All clear!')
            : RefreshIndicator(
                color: AppTheme.teal,
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _requests.length,
                  itemBuilder: (_, i) {
                    final r = _requests[i];
                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(r.resourceName,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary)),
                              ),
                              StatusBadge(r.severity),
                              const SizedBox(width: 8),
                              StatusBadge(r.requestStatus),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(r.faultDescription,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text('Reported by ${r.reporter}',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppTheme.textSecondary)),
                              const Spacer(),
                              Text(r.reportedAt,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                          if (user?.isMaintenance == true &&
                              r.requestStatus != 'resolved' &&
                              r.requestStatus != 'closed') ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => _resolve(r),
                                child: const Text('Mark as Resolved'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _reportFault,
            backgroundColor: AppTheme.teal,
            foregroundColor: AppTheme.bgDark,
            icon: const Icon(Icons.add),
            label: const Text('Report Fault', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
