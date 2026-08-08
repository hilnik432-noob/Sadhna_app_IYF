import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sadhana_entry.dart';

/// Shared Firestore access for a student's sadhana history — used by
/// [SadhanaService] (reading/writing the SIGNED-IN user's own history) and
/// by the admin/facilitator dashboards (reading/annotating an ARBITRARY
/// student's history). Kept in one place so both call sites can never drift
/// out of sync on the query shape or the write-mirroring logic.
class SadhanaRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _userSadhanaRef(String uid) =>
      _db.collection('users').doc(uid).collection('sadhana');
  CollectionReference get _logsRef => _db.collection('sadhana_logs');

  /// Shared with SadhanaService.submitSadhana, which mirrors writes under
  /// this exact `{uid}_{dateKey}` doc ID in `sadhana_logs` — this MUST stay
  /// identical on both sides or the mirror write silently targets a
  /// nonexistent/wrong document.
  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<SadhanaEntry>> fetchHistory(String uid, {int limit = 60}) async {
    final snap = await _userSadhanaRef(uid)
        .orderBy('date', descending: true).limit(limit).get();
    return snap.docs
        .map((d) => SadhanaEntry.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  /// Writes facilitator guidance onto a specific entry — mirrors to the
  /// top-level `sadhana_logs` doc too, matching how submitSadhana mirrors
  /// writes. `entryDate` must be the entry's own `date` (used to compute the
  /// matching `sadhana_logs` doc ID — NOT the subcollection doc ID, which is
  /// a different, random ID for entries created before this field existed).
  Future<void> writeFacilitatorNote({
    required String studentUid,
    required String logDocId,
    required DateTime entryDate,
    required String note,
  }) async {
    await _userSadhanaRef(studentUid).doc(logDocId).update({'facilitatorNote': note});
    await _logsRef.doc('${studentUid}_${dateKey(entryDate)}').update({'facilitatorNote': note});
  }
}
