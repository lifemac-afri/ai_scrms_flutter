import 'package:flutter/material.dart';

class User {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final String department;
  final int noShowCount;
  final String accountStatus;
  final int unread;

  User({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.department = '',
    this.noShowCount = 0,
    this.accountStatus = 'active',
    this.unread = 0,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        userId: _int(j['user_id']),
        fullName: j['full_name'] ?? j['name'] ?? '',
        email: j['email'] ?? '',
        role: j['role'] ?? 'student',
        department: j['department'] ?? '',
        noShowCount: _int(j['no_show_count']),
        accountStatus: j['account_status'] ?? 'active',
        unread: _int(j['unread']),
      );

  bool get isAdmin => role == 'super_admin' || role == 'facility_manager';
  bool get isMaintenance => role == 'maintenance' || isAdmin;
  bool get isSuperAdmin => role == 'super_admin';

  String get roleLabel => role.replaceAll('_', ' ');
  String get initials => fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
}

class Resource {
  final int resourceId;
  final String resourceName;
  final String resourceType;
  final String building;
  final String floor;
  final String roomNumber;
  final int capacity;
  final Map<String, dynamic> features;
  final String conditionStatus;
  final bool available;

  Resource({
    required this.resourceId,
    required this.resourceName,
    required this.resourceType,
    this.building = '',
    this.floor = '',
    this.roomNumber = '',
    this.capacity = 1,
    this.features = const {},
    this.conditionStatus = 'available',
    this.available = true,
  });

  factory Resource.fromJson(Map<String, dynamic> j) => Resource(
        resourceId: _int(j['resource_id']),
        resourceName: j['resource_name'] ?? '',
        resourceType: j['resource_type'] ?? '',
        building: j['building'] ?? '',
        floor: j['floor'] ?? '',
        roomNumber: j['room_number'] ?? '',
        capacity: _int(j['capacity']),
        features: j['features'] is Map ? Map<String, dynamic>.from(j['features']) : {},
        conditionStatus: j['condition_status'] ?? 'available',
        available: j['available'] == true || j['available'] == 1,
      );

  IconData get typeIcon {
    switch (resourceType) {
      case 'classroom': return Icons.school;
      case 'laboratory': return Icons.biotech;
      case 'equipment': return Icons.computer;
      case 'event_space': return Icons.event_seat;
      case 'sports_facility': return Icons.sports_soccer;
      case 'study_room': return Icons.library_books;
      default: return Icons.business;
    }
  }

  String get typeLabel => resourceType.replaceAll('_', ' ');
  String get location => [building, floor, roomNumber].where((s) => s.isNotEmpty).join(' · ');
}

class Booking {
  final int bookingId;
  final int userId;
  final int resourceId;
  final String resourceName;
  final String building;
  final String roomNumber;
  final String resourceType;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String purpose;
  final String bookingStatus;
  final String qrCode;

  Booking({
    required this.bookingId,
    required this.userId,
    required this.resourceId,
    this.resourceName = '',
    this.building = '',
    this.roomNumber = '',
    this.resourceType = '',
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    this.purpose = '',
    required this.bookingStatus,
    this.qrCode = '',
  });

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        bookingId: _int(j['booking_id']),
        userId: _int(j['user_id']),
        resourceId: _int(j['resource_id']),
        resourceName: j['resource_name'] ?? '',
        building: j['building'] ?? '',
        roomNumber: j['room_number'] ?? '',
        resourceType: j['resource_type'] ?? '',
        bookingDate: j['booking_date'] ?? '',
        startTime: j['start_time'] ?? '',
        endTime: j['end_time'] ?? '',
        purpose: j['purpose'] ?? '',
        bookingStatus: j['booking_status'] ?? '',
        qrCode: j['qr_code'] ?? '',
      );

  bool get isActive => bookingStatus == 'confirmed' || bookingStatus == 'active';
  String get timeRange => '${_fmtTime(startTime)} – ${_fmtTime(endTime)}';

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
}

class AppNotification {
  final int notificationId;
  final String notificationType;
  final String messageBody;
  final bool isRead;
  final String createdAt;

  AppNotification({
    required this.notificationId,
    required this.notificationType,
    required this.messageBody,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        notificationId: _int(j['notification_id']),
        notificationType: j['notification_type'] ?? '',
        messageBody: j['message_body'] ?? '',
        isRead: j['is_read'] == 1 || j['is_read'] == true,
        createdAt: j['created_at'] ?? '',
      );
}

class WaitlistItem {
  final int waitlistId;
  final int resourceId;
  final String resourceName;
  final String building;
  final String resourceType;
  final String requestedDate;
  final String requestedStart;
  final String requestedEnd;
  final int priorityScore;
  final String status;

  WaitlistItem({
    required this.waitlistId,
    required this.resourceId,
    this.resourceName = '',
    this.building = '',
    this.resourceType = '',
    required this.requestedDate,
    required this.requestedStart,
    required this.requestedEnd,
    this.priorityScore = 5,
    this.status = 'waiting',
  });

  factory WaitlistItem.fromJson(Map<String, dynamic> j) => WaitlistItem(
        waitlistId: _int(j['waitlist_id']),
        resourceId: _int(j['resource_id']),
        resourceName: j['resource_name'] ?? '',
        building: j['building'] ?? '',
        resourceType: j['resource_type'] ?? '',
        requestedDate: j['requested_date'] ?? '',
        requestedStart: j['requested_start'] ?? '',
        requestedEnd: j['requested_end'] ?? '',
        priorityScore: _int(j['priority_score']),
        status: j['status'] ?? 'waiting',
      );
}

class MaintenanceRequest {
  final int requestId;
  final int resourceId;
  final String resourceName;
  final String reporter;
  final String faultDescription;
  final String severity;
  final String requestStatus;
  final String reportedAt;

  MaintenanceRequest({
    required this.requestId,
    required this.resourceId,
    this.resourceName = '',
    this.reporter = '',
    this.faultDescription = '',
    this.severity = 'medium',
    this.requestStatus = 'open',
    this.reportedAt = '',
  });

  factory MaintenanceRequest.fromJson(Map<String, dynamic> j) => MaintenanceRequest(
        requestId: _int(j['request_id']),
        resourceId: _int(j['resource_id']),
        resourceName: j['resource_name'] ?? '',
        reporter: j['reporter'] ?? '',
        faultDescription: j['fault_description'] ?? '',
        severity: j['severity'] ?? 'medium',
        requestStatus: j['request_status'] ?? 'open',
        reportedAt: j['reported_at'] ?? '',
      );
}

class AnalyticsData {
  final int totalBookings;
  final int noShows;
  final int activeUsers;
  final int totalResources;
  final int pendingMaintenance;
  final int waitlisted;
  final List<Map<String, dynamic>> byType;
  final List<Map<String, dynamic>> trend;
  final List<Map<String, dynamic>> topResources;

  AnalyticsData({
    this.totalBookings = 0,
    this.noShows = 0,
    this.activeUsers = 0,
    this.totalResources = 0,
    this.pendingMaintenance = 0,
    this.waitlisted = 0,
    this.byType = const [],
    this.trend = const [],
    this.topResources = const [],
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> j) => AnalyticsData(
        totalBookings: _int(j['total_bookings']),
        noShows: _int(j['no_shows']),
        activeUsers: _int(j['active_users']),
        totalResources: _int(j['total_resources']),
        pendingMaintenance: _int(j['pending_maintenance']),
        waitlisted: _int(j['waitlisted']),
        byType: List<Map<String, dynamic>>.from(j['by_type'] ?? []),
        trend: List<Map<String, dynamic>>.from(j['trend'] ?? []),
        topResources: List<Map<String, dynamic>>.from(j['top_resources'] ?? []),
      );
}

int _int(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
