import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/access_level.dart';

/// A student's basic identity + assignment info, for the admin/facilitator
/// list views — deliberately NOT a full sadhna entry (that's fetched
/// per-student on demand via SadhanaRepository once you drill in).
class StudentSummary {
  final String uid;
  final String name;
  final String email;
  final String groupName;
  final String facilitatorDisplay;

  const StudentSummary({
    required this.uid,
    required this.name,
    required this.email,
    required this.groupName,
    required this.facilitatorDisplay,
  });

  factory StudentSummary.fromMap(String uid, Map<String, dynamic> m) => StudentSummary(
    uid: uid,
    name: (m['name'] as String?) ?? '',
    email: (m['email'] as String?) ?? '',
    groupName: (m['groupName'] as String?) ?? '',
    facilitatorDisplay: (m['facilitatorDisplay'] as String?) ?? '',
  );
}

/// Shared query logic for both dashboards:
///   - super_admin passes facilitatorDikshitName=null -> sees every student
///   - facilitator passes their own dikshitName -> sees only their students
/// One method, one place, so "see everyone" vs "see only mine" can never
/// drift into two different (and possibly inconsistently-filtered) queries.
class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<StudentSummary>> fetchStudents({String? facilitatorDikshitName}) async {
    Query<Map<String, dynamic>> query = _db.collection('users').withConverter(
      fromFirestore: (snap, _) => snap.data() ?? {},
      toFirestore: (data, _) => data,
    );

    if (facilitatorDikshitName != null) {
      query = query.where('facilitatorName', isEqualTo: facilitatorDikshitName);
    }

    final snap = await query.get();
    return snap.docs
        .where((d) => _isPlainStudentAccount(d.data()))
        .map((d) => StudentSummary.fromMap(d.id, d.data()))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Excludes facilitator/super_admin accounts from student lists — those
  /// also live in `users`, but aren't students to show/drill into.
  bool _isPlainStudentAccount(Map<String, dynamic> data) {
    return AccessLevel.fromString(data['accessLevel'] as String?) == AccessLevel.student;
  }
}
