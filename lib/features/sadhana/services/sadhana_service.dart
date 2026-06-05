import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sadhana_entry.dart';

class SadhanaService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  SadhanaEntry? _todayEntry;
  List<SadhanaEntry> _history = [];
  int _streakCount = 0;

  SadhanaEntry? get todayEntry => _todayEntry;
  List<SadhanaEntry> get history => _history;
  int get streakCount => _streakCount;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _userName => FirebaseAuth.instance.currentUser?.displayName ?? '';

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── subcollection ref: users/{uid}/sadhana ──────────────────────────────
  CollectionReference get _userSadhanaRef =>
      _db.collection('users').doc(_uid).collection('sadhana');

  // ── top-level ref: sadhana_logs (for admin / cross-student queries) ──────
  CollectionReference get _logsRef => _db.collection('sadhana_logs');

  Future<void> loadTodayEntry() async {
    if (_uid.isEmpty) return;
    final today = _dateKey(DateTime.now());
    final snap = await _userSadhanaRef
        .where('dateKey', isEqualTo: today)
        .limit(1)
        .get();

    _todayEntry = snap.docs.isNotEmpty
        ? SadhanaEntry.fromMap(snap.docs.first.id, snap.docs.first.data() as Map<String, dynamic>)
        : null;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    if (_uid.isEmpty) return;
    final snap = await _userSadhanaRef
        .orderBy('date', descending: true)
        .limit(60)
        .get();

    _history = snap.docs
        .map((d) => SadhanaEntry.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
    _calculateStreak();
    notifyListeners();
  }

  void _calculateStreak() {
    if (_history.isEmpty) { _streakCount = 0; return; }
    int streak = 0;
    DateTime check = DateTime.now();
    for (final entry in _history) {
      final d = entry.date;
      if (_dateKey(d) == _dateKey(check) ||
          _dateKey(d) == _dateKey(check.subtract(const Duration(days: 1)))) {
        streak++;
        check = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    _streakCount = streak;
  }

  Future<void> submitSadhana(SadhanaEntry entry) async {
    if (_uid.isEmpty) return;
    final today = _dateKey(entry.date);

    final data = {
      ...entry.toMap(),
      'dateKey': today,
      'userName': _userName,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    String docId;

    // Write to user subcollection
    if (_todayEntry != null) {
      await _userSadhanaRef.doc(_todayEntry!.id).update(data);
      docId = _todayEntry!.id;
    } else {
      final ref = await _userSadhanaRef.add({...data, 'createdAt': FieldValue.serverTimestamp()});
      docId = ref.id;
    }

    // Mirror to top-level sadhana_logs for admin/cross-student tracking
    // Doc ID: {uid}_{dateKey} — one doc per student per day, safe to overwrite
    await _logsRef.doc('${_uid}_$today').set({
      ...data,
      'uid': _uid,
      'logId': docId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Update user's summary stats
    await _db.collection('users').doc(_uid).update({
      'totalSadhanaLogs': FieldValue.increment(_todayEntry == null ? 1 : 0),
      'lastSadhanaDate': FieldValue.serverTimestamp(),
      'streakCount': _streakCount + (_todayEntry == null ? 1 : 0),
    });

    await loadTodayEntry();
    await loadHistory();
  }

  // ── Admin: fetch all students' sadhana for a given date ─────────────────
  Future<List<Map<String, dynamic>>> fetchAllStudentsSadhana(DateTime date) async {
    final dateKey = _dateKey(date);
    final snap = await _logsRef
        .where('dateKey', isEqualTo: dateKey)
        .orderBy('score', descending: true)
        .get();
    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  // ── Admin: fetch a specific student's full history ───────────────────────
  Future<List<SadhanaEntry>> fetchStudentHistory(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('sadhana')
        .orderBy('date', descending: true)
        .get();
    return snap.docs
        .map((d) => SadhanaEntry.fromMap(d.id, d.data()))
        .toList();
  }
}
