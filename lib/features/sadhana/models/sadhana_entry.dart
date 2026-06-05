import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student,
  jobGoing,
  brahmachari,
  studentAndJob;

  String get label {
    switch (this) {
      case UserRole.student:       return 'Student';
      case UserRole.jobGoing:      return 'Job Going';
      case UserRole.brahmachari:   return 'Brahmachari';
      case UserRole.studentAndJob: return 'Student + Job Going';
    }
  }

  bool get hasStudy => this == student || this == studentAndJob;
  bool get hasJob   => this == jobGoing || this == studentAndJob;
}

class SenseControl {
  final bool ear;
  final bool eye;
  final bool nose;
  final bool tongue;
  final bool skin;
  final String missed;   // what was not engaged devotionally
  final String wrongDone; // any wrong engagement of senses

  const SenseControl({
    this.ear = true, this.eye = true, this.nose = true,
    this.tongue = true, this.skin = true,
    this.missed = '', this.wrongDone = '',
  });

  int get engagedCount => [ear, eye, nose, tongue, skin].where((v) => v).length;

  Map<String, dynamic> toMap() => {
    'ear': ear, 'eye': eye, 'nose': nose, 'tongue': tongue, 'skin': skin,
    'missed': missed, 'wrongDone': wrongDone,
  };

  factory SenseControl.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const SenseControl();
    return SenseControl(
      ear:       m['ear']  ?? true,
      eye:       m['eye']  ?? true,
      nose:      m['nose'] ?? true,
      tongue:    m['tongue'] ?? true,
      skin:      m['skin'] ?? true,
      missed:    m['missed'] ?? '',
      wrongDone: m['wrongDone'] ?? '',
    );
  }
}

class SadhanaFile {
  final String url;
  final String name;
  final DateTime uploadedAt;
  final DateTime expiresAt; // 7 days after upload

  SadhanaFile({
    required this.url, required this.name,
    required this.uploadedAt, required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() => {
    'url': url, 'name': name,
    'uploadedAt': Timestamp.fromDate(uploadedAt),
    'expiresAt':  Timestamp.fromDate(expiresAt),
  };

  factory SadhanaFile.fromMap(Map<String, dynamic> m) => SadhanaFile(
    url:        m['url'] ?? '',
    name:       m['name'] ?? '',
    uploadedAt: (m['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    expiresAt:  (m['expiresAt']  as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
  );
}

class SadhanaEntry {
  final String id;
  final String userId;
  final String userName;
  final DateTime date;
  final String userRole; // UserRole.name

  // ── Core ──────────────────────────────────────────────
  final int    japaRounds;
  final bool   mangalAarti;
  final bool   morningProgram;
  final int    readingMinutes;
  final String wakeUpTime;
  final String notes;

  // ── Hearing ───────────────────────────────────────────
  final int    hearingMinutes;
  final String hearingRemark;     // 150 words max
  final SadhanaFile? hearingFile; // uploaded notes file

  // ── Study (student / student+job) ─────────────────────
  final int    studyMinutes;
  final String studyRemark;       // 1000 words max

  // ── Job (jobGoing / student+job) ──────────────────────
  final int jobMinutes;

  // ── Seva ──────────────────────────────────────────────
  final int    sevaMinutes;
  final String sevaDescription;

  // ── Sense Control ─────────────────────────────────────
  final SenseControl senseControl;

  // ── Mobile ────────────────────────────────────────────
  final int    mobileMinutes;
  final String mobileDescription;
  final int    mobileVowReduceMinutes; // vow: reduce by this many min/week

  // ── Free Time ─────────────────────────────────────────
  final int    freeTimeMinutes;
  final String facilitatorNote;   // written by facilitator/mentor

  SadhanaEntry({
    required this.id,
    required this.userId,
    this.userName = '',
    required this.date,
    this.userRole = 'student',
    this.japaRounds = 0,
    this.mangalAarti = false,
    this.morningProgram = false,
    this.readingMinutes = 0,
    this.wakeUpTime = '',
    this.notes = '',
    this.hearingMinutes = 0,
    this.hearingRemark = '',
    this.hearingFile,
    this.studyMinutes = 0,
    this.studyRemark = '',
    this.jobMinutes = 0,
    this.sevaMinutes = 0,
    this.sevaDescription = '',
    SenseControl? senseControl,
    this.mobileMinutes = 0,
    this.mobileDescription = '',
    this.mobileVowReduceMinutes = 0,
    this.freeTimeMinutes = 0,
    this.facilitatorNote = '',
  }) : senseControl = senseControl ?? const SenseControl();

  // ── Score (0–100) ──────────────────────────────────────
  int get score {
    int s = 0;
    s += (japaRounds * 5).clamp(0, 50);
    if (mangalAarti) s += 10;
    if (morningProgram) s += 5;
    s += (readingMinutes  ~/ 5).clamp(0, 10);
    s += (hearingMinutes  ~/ 10).clamp(0, 10);
    s += (sevaMinutes     ~/ 15).clamp(0, 10);
    s += senseControl.engagedCount * 1; // up to 5
    return s.clamp(0, 100);
  }

  Map<String, dynamic> toMap() => {
    'userId':       userId,
    'userName':     userName,
    'date':         Timestamp.fromDate(date),
    'userRole':     userRole,
    'japaRounds':   japaRounds,
    'mangalAarti':  mangalAarti,
    'morningProgram': morningProgram,
    'readingMinutes': readingMinutes,
    'wakeUpTime':   wakeUpTime,
    'notes':        notes,
    'hearingMinutes': hearingMinutes,
    'hearingRemark':  hearingRemark,
    'hearingFile':    hearingFile?.toMap(),
    'studyMinutes':   studyMinutes,
    'studyRemark':    studyRemark,
    'jobMinutes':     jobMinutes,
    'sevaMinutes':    sevaMinutes,
    'sevaDescription': sevaDescription,
    'senseControl':   senseControl.toMap(),
    'mobileMinutes':  mobileMinutes,
    'mobileDescription': mobileDescription,
    'mobileVowReduceMinutes': mobileVowReduceMinutes,
    'freeTimeMinutes': freeTimeMinutes,
    'facilitatorNote': facilitatorNote,
    'score': score,
  };

  factory SadhanaEntry.fromMap(String id, Map<String, dynamic> m) {
    final fileMap = m['hearingFile'] as Map<String, dynamic>?;
    return SadhanaEntry(
      id:           id,
      userId:       m['userId'] ?? '',
      userName:     m['userName'] ?? '',
      date:         (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userRole:     m['userRole'] ?? 'student',
      japaRounds:   m['japaRounds'] ?? 0,
      mangalAarti:  m['mangalAarti'] ?? false,
      morningProgram: m['morningProgram'] ?? false,
      readingMinutes: m['readingMinutes'] ?? 0,
      wakeUpTime:   m['wakeUpTime'] ?? '',
      notes:        m['notes'] ?? '',
      hearingMinutes: m['hearingMinutes'] ?? 0,
      hearingRemark:  m['hearingRemark'] ?? '',
      hearingFile:    fileMap != null ? SadhanaFile.fromMap(fileMap) : null,
      studyMinutes:   m['studyMinutes'] ?? 0,
      studyRemark:    m['studyRemark'] ?? '',
      jobMinutes:     m['jobMinutes'] ?? 0,
      sevaMinutes:    m['sevaMinutes'] ?? 0,
      sevaDescription: m['sevaDescription'] ?? '',
      senseControl:   SenseControl.fromMap(m['senseControl'] as Map<String, dynamic>?),
      mobileMinutes:  m['mobileMinutes'] ?? 0,
      mobileDescription: m['mobileDescription'] ?? '',
      mobileVowReduceMinutes: m['mobileVowReduceMinutes'] ?? 0,
      freeTimeMinutes: m['freeTimeMinutes'] ?? 0,
      facilitatorNote: m['facilitatorNote'] ?? '',
    );
  }
}
