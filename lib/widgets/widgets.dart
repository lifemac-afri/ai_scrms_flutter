import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

// ── STAT CARD ─────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final IconData icon;
  final dynamic value;
  final String label;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bgCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── SECTION HEADER ────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                if (subtitle != null)
                  Text(subtitle!,
                      style:
                          const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── STATUS BADGE ──────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _map(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  (Color, String) _map(String s) => switch (s) {
        'confirmed' => (AppTheme.teal, 'Confirmed'),
        'active' => (AppTheme.green, 'Active'),
        'completed' => (AppTheme.blue, 'Completed'),
        'cancelled' => (AppTheme.textSecondary, 'Cancelled'),
        'no_show' => (AppTheme.red, 'No Show'),
        'pending' => (AppTheme.amber, 'Pending'),
        'available' => (AppTheme.green, 'Available'),
        'under_maintenance' => (AppTheme.amber, 'Maintenance'),
        'decommissioned' => (AppTheme.red, 'Decommissioned'),
        'waiting' => (AppTheme.amber, 'Waiting'),
        'promoted' => (AppTheme.teal, 'Promoted'),
        'open' => (AppTheme.red, 'Open'),
        'in_progress' => (AppTheme.amber, 'In Progress'),
        'resolved' => (AppTheme.green, 'Resolved'),
        'low' => (AppTheme.green, 'Low'),
        'medium' => (AppTheme.amber, 'Medium'),
        'high' => (AppTheme.red, 'High'),
        'critical' => (const Color(0xFFFF0066), 'Critical'),
        _ => (AppTheme.textSecondary, s),
      };
}

// ── APP CARD ──────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? AppTheme.bgCardBorder),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

// ── RESOURCE CARD ─────────────────────────────────────────
class ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback? onBook;
  final bool showActions;

  const ResourceCard({
    super.key,
    required this.resource,
    this.onBook,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: resource.available ? AppTheme.teal.withValues(alpha: 0.2) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(resource.typeIcon, size: 28, color: AppTheme.teal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resource.resourceName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    Text(resource.location,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              StatusBadge(resource.conditionStatus),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(Icons.people_outline, '${resource.capacity}'),
              _chip(Icons.category_outlined, resource.typeLabel),
              if (resource.features['ac'] == true)
                _chip(Icons.ac_unit, 'AC'),
              if (resource.features['projector'] == true)
                _chip(Icons.videocam_outlined, 'Proj'),
            ],
          ),
          if (showActions && resource.available && onBook != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBook,
                child: const Text('Book Now'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.bgCardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      );
}

// ── BOOKING CARD ─────────────────────────────────────────
class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;
  final VoidCallback? onQr;

  const BookingCard({super.key, required this.booking, this.onCancel, this.onQr});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(booking.resourceName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ),
              StatusBadge(booking.bookingStatus),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('${booking.building} ${booking.roomNumber}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('${booking.bookingDate}  ${booking.timeRange}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          if (booking.purpose.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.notes, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(booking.purpose,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          if (booking.isActive && (onCancel != null || onQr != null)) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onQr != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onQr,
                      icon: const Icon(Icons.qr_code, size: 16),
                      label: const Text('QR Code'),
                    ),
                  ),
                if (onCancel != null && onQr != null) const SizedBox(width: 8),
                if (onCancel != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.red,
                          side: const BorderSide(color: AppTheme.red)),
                      child: const Text('Cancel'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── EMPTY STATE ───────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

// ── LOADING WIDGET ────────────────────────────────────────
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.teal),
          SizedBox(height: 16),
          Text('Loading…', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ── AI CHIP ───────────────────────────────────────────────
class AiChip extends StatelessWidget {
  final String label;
  const AiChip({super.key, this.label = '✦ AI-Powered'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [AppTheme.teal.withValues(alpha: 0.2), AppTheme.purple.withValues(alpha: 0.2)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.teal.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, color: AppTheme.teal, fontWeight: FontWeight.w600)),
    );
  }
}

// ── SNACKBAR HELPERS ─────────────────────────────────────
void showSuccess(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle, color: AppTheme.green, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(msg)),
    ]),
    backgroundColor: AppTheme.bgCard,
    behavior: SnackBarBehavior.floating,
  ));
}

void showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [
      const Icon(Icons.error, color: AppTheme.red, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(msg)),
    ]),
    backgroundColor: AppTheme.bgCard,
    behavior: SnackBarBehavior.floating,
  ));
}
