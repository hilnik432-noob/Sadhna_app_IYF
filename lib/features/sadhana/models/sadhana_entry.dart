import 'package:cloud_firestore/cloud_firestore.dart';

class SadhanaEntry {
  final String id;
  final String userId;
  final DateTime date;
  final int japaRounds;
  final bool mangalAarti;
  final bool morningProgram;
  final int readingMinutes;
  final String wakeUpTime;
  final String notes;

  SadhanaEntry({
    required this.id,
    required this.userId,
    required this.date,
    this.japaRounds = 0,
    this.mangalAarti = false,
    this.morningProgram = false,
    this.readingMinutes = 0,
    this.wakeUpTime = '',
    this.notes = '',
  });

  int get score {
    int s = 0;
    s += (japaRounds * 5).clamp(0, 50);
    if (mangalAarti) s += 20;
    if (morningProgram) s += 10;
    s += (readingMinutes ~/ 5).clamp(0, 20);
    return s.clamp(0, 100);
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'date': Timestamp.fromDate(date),
    'japaRounds': japaRounds,
    'mangalAarti': mangalAarti,
    'morningProgram': morningProgram,
    'readingMinutes': readingMinutes,
    'wakeUpTime': wakeUpTime,
    'notes': notes,
    'score': score,
  };

  factory SadhanaEntry.fromMap(String id, Map<String, dynamic> map) {
    return SadhanaEntry(
      id: id,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      japaRounds: map['japaRounds'] ?? 0,
      mangalAarti: map['mangalAarti'] ?? false,
      morningProgram: map['morningProgram'] ?? false,
      readingMinutes: map['readingMinutes'] ?? 0,
      wakeUpTime: map['wakeUpTime'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}
