import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/sadhana_entry.dart';
import 'sadhana_repository.dart';

class SadhanaService extends ChangeNotifier {
  final FirebaseFirestore _db      = FirebaseFirestore.instance;
  final FirebaseStorage   _storage = FirebaseStorage.instance;
  final SadhanaRepository _repo    = SadhanaRepository();

  SadhanaEntry?      _todayEntry;
  List<SadhanaEntry> _history     = [];
  int                _streakCount = 0;
  UserRole           _userRole    = UserRole.student;

  SadhanaEntry?      get todayEntry  => _todayEntry;
  List<SadhanaEntry> get history     => _history;
  int                get streakCount => _streakCount;
  UserRole           get userRole    => _userRole;

  String get _uid  => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _name => FirebaseAuth.instance.currentUser?.displayName ?? '';

  // Shared with SadhanaRepository — kept as one implementation there,
  // called through this thin alias so existing call sites below don't change.
  String _dateKey(DateTime d) => SadhanaRepository.dateKey(d);

  CollectionReference get _userSadhanaRef =>
      _db.collection('users').doc(_uid).collection('sadhana');
  CollectionReference get _logsRef => _db.collection('sadhana_logs');

  // ── Sadhna category (UserRole) ────────────────────────────────────────────
  // NOTE: this is stored under 'sadhanaCategory', deliberately NOT 'role' —
  // 'role' would collide with the unrelated accessLevel/permission concept
  // (see core/constants/access_level.dart).
  Future<void> loadUserRole() async {
    if (_uid.isEmpty) return;
    final doc = await _db.collection('users').doc(_uid).get();
    final roleStr = doc.data()?['sadhanaCategory'] as String? ?? 'student';
    try {
      _userRole = UserRole.values.firstWhere((r) => r.name == roleStr);
    } catch (_) {
      _userRole = UserRole.student;
    }
    notifyListeners();
  }

  Future<void> saveUserRole(UserRole role) async {
    if (_uid.isEmpty) return;
    _userRole = role;
    await _db.collection('users').doc(_uid).update({'sadhanaCategory': role.name});
    notifyListeners();
  }

  // ── File upload (hearing notes) ───────────────────────────────────────────
  Future<SadhanaFile?> uploadHearingFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (_uid.isEmpty) return null;
    try {
      final today   = _dateKey(DateTime.now());
      final ref     = _storage.ref('sadhana_files/$_uid/$today/$fileName');
      final task    = await ref.putData(bytes, SettableMetadata(contentType: _mimeType(fileName)));
      final url     = await task.ref.getDownloadURL();
      final now     = DateTime.now();
      return SadhanaFile(
        url:        url,
        name:       fileName,
        uploadedAt: now,
        expiresAt:  now.add(const Duration(days: 7)),
      );
    } catch (e) {
      debugPrint('File upload error: $e');
      return null;
    }
  }

  String _mimeType(String name) {
    final ext = name.split('.').last.toLowerCase();
    const map = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
      'txt': 'text/plain',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  // ── Load today ────────────────────────────────────────────────────────────
  Future<void> loadTodayEntry() async {
    if (_uid.isEmpty) return;
    final today = _dateKey(DateTime.now());
    final snap  = await _userSadhanaRef
        .where('dateKey', isEqualTo: today).limit(1).get();
    _todayEntry = snap.docs.isNotEmpty
        ? SadhanaEntry.fromMap(snap.docs.first.id, snap.docs.first.data() as Map<String, dynamic>)
        : null;
    notifyListeners();
  }

  // ── Load history ──────────────────────────────────────────────────────────
  Future<void> loadHistory() async {
    if (_uid.isEmpty) return;
    _history = await _repo.fetchHistory(_uid, limit: 60);
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
      } else break;
    }
    _streakCount = streak;
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> submitSadhana(SadhanaEntry entry) async {
    if (_uid.isEmpty) return;
    final today = _dateKey(entry.date);

    final data = {
      ...entry.toMap(),
      'dateKey':   today,
      'userName':  _name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    String docId;
    if (_todayEntry != null) {
      await _userSadhanaRef.doc(_todayEntry!.id).update(data);
      docId = _todayEntry!.id;
    } else {
      final ref = await _userSadhanaRef.add({...data, 'createdAt': FieldValue.serverTimestamp()});
      docId = ref.id;
    }

    // Mirror to top-level for admin
    await _logsRef.doc('${_uid}_$today').set({
      ...data, 'uid': _uid, 'logId': docId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Update user summary
    await _db.collection('users').doc(_uid).update({
      'totalSadhanaLogs': FieldValue.increment(_todayEntry == null ? 1 : 0),
      'lastSadhanaDate':  FieldValue.serverTimestamp(),
      'streakCount':      _streakCount + (_todayEntry == null ? 1 : 0),
    });

    await loadTodayEntry();
    await loadHistory();
  }

  // ── Facilitator note (written by mentor) ──────────────────────────────────
  // Kept here for completeness (a student's own service technically could
  // call this) but in practice it's the facilitator/admin dashboards
  // (AdminService) that call SadhanaRepository.writeFacilitatorNote — a
  // student never has permission to edit their own facilitatorNote field
  // (see firestore.rules).
  Future<void> updateFacilitatorNote(SadhanaEntry entry, String note) async {
    await _repo.writeFacilitatorNote(
      studentUid: _uid, logDocId: entry.id, entryDate: entry.date, note: note,
    );
    await loadHistory();
  }

  // ── Admin helpers ─────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchAllStudentsSadhana(DateTime date) async {
    final snap = await _logsRef
        .where('dateKey', isEqualTo: _dateKey(date))
        .orderBy('score', descending: true).get();
    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }
}
