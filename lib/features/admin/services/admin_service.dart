import 'package:cloud_firestore/cloud_firestore.dart';

import '../../sadhana/services/reading_hearing_stats.dart';
import '../../sadhana/services/sadhana_repository.dart';

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
  final SadhanaRepository _sadhanaRepo = SadhanaRepository();

  /// Every student's reading+hearing totals over the last [days] days,
  /// sorted highest combined time first — the super_admin "who's investing
  /// the most time in reading & hearing" report. Pass a facilitatorDikshitName
  /// to scope this to one facilitator's students instead of everyone (not
  /// used by the UI yet, but the leaderboard logic supports it for free).
  ///
  /// NOTE: this does one Firestore read per student to fetch their history
  /// — fine at the current student-body scale, but would need pagination/
  /// pre-aggregation if the school grows into the hundreds+.
  Future<List<StudentReadingHearingTotal>> fetchReadingHearingLeaderboard({
    String? facilitatorDikshitName,
    int days = 7,
  }) async {
    final students = await fetchStudents(facilitatorDikshitName: facilitatorDikshitName);
    final totals = await Future.wait(students.map((s) async {
      final history = await _sadhanaRepo.fetchHistory(s.uid, limit: days + 7); // small buffer
      final t = totalReadingHearing(history, days: days);
      return StudentReadingHearingTotal(
        uid: s.uid, name: s.name.isNotEmpty ? s.name : s.email,
        readingMinutes: t.reading, hearingMinutes: t.hearing,
      );
    }));
    totals.sort((a, b) => b.combinedMinutes.compareTo(a.combinedMinutes));
    return totals;
  }

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

  /// Whether this user doc represents a real practicing devotee to list —
  /// deliberately checked by `profileComplete`, NOT accessLevel. A
  /// facilitator/super_admin can ALSO be a genuine student logging their
  /// own sadhna (both real accounts in this app are exactly that case);
  /// excluding by accessLevel would hide their own history from every
  /// dashboard, including their own. Synthetic facilitator-only accounts
  /// (created directly by seed_facilitator_accounts.py) never go through
  /// profile setup, so this field is simply absent for them.
  bool _isPlainStudentAccount(Map<String, dynamic> data) {
    return data['profileComplete'] == true;
  }
}
