import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../theme/app_theme.dart';
import 'book_resource_screen.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});
  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  List<Resource> _resources = [];
  bool _loading = true;
  String _filterType = '';
  String _date = _today();
  String _start = '08:00';
  String _end = '18:00';
  final int _capacity = 0;
  String _search = '';

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getResources(
      type: _filterType.isEmpty ? null : _filterType,
      date: _date,
      start: _start,
      end: _end,
      capacity: _capacity > 0 ? _capacity : null,
    );
    if (mounted) setState(() { _resources = res; _loading = false; });
  }

  List<Resource> get _filtered {
    if (_search.isEmpty) return _resources;
    final q = _search.toLowerCase();
    return _resources.where((r) =>
        r.resourceName.toLowerCase().contains(q) ||
        r.building.toLowerCase().contains(q) ||
        r.resourceType.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _filterBar(),
        Expanded(
          child: _loading
              ? const LoadingWidget()
              : _filtered.isEmpty
                  ? const EmptyState(icon: Icons.search_off_rounded, title: 'No Resources Found', subtitle: 'Try adjusting your filters')
                  : RefreshIndicator(
                      color: AppTheme.teal,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => ResourceCard(
                          resource: _filtered[i],
                          onBook: _filtered[i].available
                              ? () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            BookResourceScreen(resource: _filtered[i])),
                                  ).then((_) => _load());
                                }
                              : null,
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _filterBar() {
    return Container(
      color: AppTheme.bgCard,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Search
          TextField(
            style: const TextStyle(color: AppTheme.textPrimary),
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(
              hintText: '🔍  Search resources…',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          // Type filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _typeChip('', Icons.all_inclusive_rounded, 'All'),
                _typeChip('classroom', Icons.school_rounded, 'Classroom'),
                _typeChip('laboratory', Icons.biotech_rounded, 'Lab'),
                _typeChip('study_room', Icons.library_books_rounded, 'Study'),
                _typeChip('equipment', Icons.computer_rounded, 'Equipment'),
                _typeChip('event_space', Icons.event_seat_rounded, 'Event'),
                _typeChip('sports_facility', Icons.sports_soccer_rounded, 'Sports'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Date & time
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.bgCardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: AppTheme.teal),
                        const SizedBox(width: 6),
                        Text(_date, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _timeField('From', _start, (v) => setState(() { _start = v; _load(); })),
              const SizedBox(width: 8),
              _timeField('To', _end, (v) => setState(() { _end = v; _load(); })),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: const Text('Search', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String value, IconData icon, String label) {
    final selected = _filterType == value;
    return GestureDetector(
      onTap: () { setState(() => _filterType = value); _load(); },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.teal : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.teal : AppTheme.bgCardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? AppTheme.bgDark : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppTheme.bgDark : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _timeField(String label, String value, Function(String) onChanged) {
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.bgCardBorder),
        ),
        child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
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
      _load();
    }
  }
}
