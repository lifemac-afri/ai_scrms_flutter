import 'package:flutter_test/flutter_test.dart';

import 'package:ai_scrms/models/models.dart';

void main() {
  test('User.fromJson maps API fields', () {
    final u = User.fromJson({
      'user_id': 1,
      'full_name': 'Test User',
      'email': 't@campus.edu',
      'role': 'student',
      'department': 'CS',
    });
    expect(u.userId, 1);
    expect(u.fullName, 'Test User');
    expect(u.role, 'student');
    expect(u.initials, 'T');
  });
}
