import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static String _baseUrl = 'http://192.168.0.34/api/index.php';
  static String _cookieHeader = '';

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url.endsWith('/') ? '${url}api/index.php' : '$url/api/index.php';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', url);
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? 'http://192.168.0.34';
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_cookieHeader.isNotEmpty) 'X-Session-Id': _cookieHeader,
      };

  static Future<Map<String, dynamic>> post(String action, [Map<String, dynamic>? data]) async {
    try {
      final body = {'action': action, ...?data};
      final res = await http
          .post(Uri.parse(_baseUrl), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      _saveCookie(res);
      final parsed = _parse(res.body);
      _saveSession(parsed);
      return parsed;
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> get(String action, [Map<String, dynamic>? params]) async {
    try {
      final query = {'action': action, ...?params?.map((k, v) => MapEntry(k, v.toString()))};
      final uri = Uri.parse(_baseUrl).replace(queryParameters: query);
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      _saveCookie(res);
      return _parse(res.body);
    } catch (e) {
      return {'error': 'Network error: $e'};
    }
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cookieHeader = prefs.getString('session_id') ?? '';
    final savedUrl = prefs.getString('base_url');
    if (savedUrl != null) {
      _baseUrl = savedUrl.endsWith('/') ? '${savedUrl}api/index.php' : '$savedUrl/api/index.php';
    }
  }

  static void _saveSessionId(String sid) {
    _cookieHeader = sid;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('session_id', sid);
    });
  }

  static void _saveCookie(http.Response res) {
    // Mobile fallback
    final cookie = res.headers['set-cookie'];
    if (cookie != null && cookie.isNotEmpty) {
      final sess = cookie.split(';').firstWhere((c) => c.trim().startsWith('PHPSESSID='), orElse: () => '');
      if (sess.isNotEmpty) {
        _saveSessionId(sess.split('=')[1]);
      }
    }
  }

  static void _saveSession(Map<String, dynamic> data) {
    if (data.containsKey('session_id')) {
      _saveSessionId(data['session_id']);
    }
  }

  static Map<String, dynamic> _parse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is List) return {'list': decoded};
      return {'error': 'Unexpected response'};
    } catch (_) {
      return {'error': 'Server error. Is XAMPP running?'};
    }
  }

  // ── AUTH ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) =>
      post('login', {'email': email, 'password': password});

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String department = '',
  }) =>
      post('register', {
        'full_name': fullName,
        'email': email,
        'password': password,
        'role': role,
        'department': department,
      });

  static Future<Map<String, dynamic>> logout() async {
    final res = await post('logout');
    _cookieHeader = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_id');
    return res;
  }

  static Future<User?> me() async {
    final res = await get('me');
    if (res.containsKey('error')) return null;
    return User.fromJson(res);
  }

  // ── RESOURCES ────────────────────────────────────────────────
  static Future<List<Resource>> getResources({
    String? type,
    String? date,
    String? start,
    String? end,
    int? capacity,
  }) async {
    final params = <String, dynamic>{
      if (type != null && type.isNotEmpty) 'type': type,
      if (date != null) 'date': date,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (capacity != null && capacity > 0) 'capacity': capacity,
    };
    final res = await get('resources', params);
    if (res.containsKey('list')) {
      return (res['list'] as List).map((r) => Resource.fromJson(r)).toList();
    }
    return [];
  }

  static Future<List<Resource>> getAllResources() async {
    final res = await get('all_resources');
    if (res.containsKey('list')) {
      return (res['list'] as List).map((r) => Resource.fromJson(r)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> addResource(Map<String, dynamic> data) =>
      post('add_resource', data);

  static Future<Map<String, dynamic>> updateResourceStatus(int resourceId, String status) =>
      post('update_resource_status', {'resource_id': resourceId, 'status': status});

  // ── BOOKINGS ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> book({
    required int resourceId,
    required String date,
    required String startTime,
    required String endTime,
    String purpose = '',
  }) =>
      post('book', {
        'resource_id': resourceId,
        'booking_date': date,
        'start_time': startTime,
        'end_time': endTime,
        'purpose': purpose,
      });

  static Future<List<Booking>> myBookings([String? status]) async {
    final res = await get('my_bookings', status != null ? {'status': status} : null);
    if (res.containsKey('list')) {
      return (res['list'] as List).map((b) => Booking.fromJson(b)).toList();
    }
    return [];
  }

  static Future<List<Booking>> allBookings() async {
    final res = await get('all_bookings');
    if (res.containsKey('list')) {
      return (res['list'] as List).map((b) => Booking.fromJson(b)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> cancelBooking(int bookingId) =>
      post('cancel_booking', {'booking_id': bookingId});

  static Future<Map<String, dynamic>> checkIn(String qrToken) =>
      post('checkin', {'qr_token': qrToken});

  // ── WAITLIST ────────────────────────────────────────────────
  static Future<List<WaitlistItem>> myWaitlist() async {
    final res = await get('my_waitlist');
    if (res.containsKey('list')) {
      return (res['list'] as List).map((w) => WaitlistItem.fromJson(w)).toList();
    }
    return [];
  }

  // ── MAINTENANCE ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> reportFault({
    required int resourceId,
    required String description,
    required String severity,
  }) =>
      post('report_fault', {
        'resource_id': resourceId,
        'description': description,
        'severity': severity,
      });

  static Future<List<MaintenanceRequest>> maintenanceList() async {
    final res = await get('maintenance_list');
    if (res.containsKey('list')) {
      return (res['list'] as List).map((m) => MaintenanceRequest.fromJson(m)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> resolveMaintenance(int requestId, String notes) =>
      post('resolve_maintenance', {'request_id': requestId, 'notes': notes});

  // ── ANALYTICS ────────────────────────────────────────────────
  static Future<AnalyticsData?> analytics() async {
    final res = await get('analytics');
    if (res.containsKey('error')) return null;
    return AnalyticsData.fromJson(res);
  }

  static Future<List<Resource>> recommendations() async {
    final res = await get('recommendations');
    final list = res['recommendations'];
    if (list is List) return list.map((r) => Resource.fromJson(r)).toList();
    return [];
  }

  static Future<List<Map<String, dynamic>>> demandForecast() async {
    final res = await get('demand_forecast');
    if (res.containsKey('list')) return List<Map<String, dynamic>>.from(res['list']);
    return [];
  }

  // ── NOTIFICATIONS ────────────────────────────────────────────
  static Future<List<AppNotification>> notifications() async {
    final res = await get('notifications');
    if (res.containsKey('list')) {
      return (res['list'] as List).map((n) => AppNotification.fromJson(n)).toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> markRead() => post('mark_read');

  // ── AUDIT ────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> auditLog() async {
    final res = await get('audit_log');
    if (res.containsKey('list')) return List<Map<String, dynamic>>.from(res['list']);
    return [];
  }

  // ── USERS ────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> usersList() async {
    final res = await get('users_list');
    if (res.containsKey('list')) return List<Map<String, dynamic>>.from(res['list']);
    return [];
  }

  static Future<Map<String, dynamic>> updateUserStatus(int userId, String status) =>
      post('update_user_status', {'user_id': userId, 'status': status});
}
