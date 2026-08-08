import '../models/sadhana_entry.dart';

/// Reading/hearing minutes for one calendar day — used to build the
/// per-student weekly chart on the facilitator/admin dashboards.
class DailyReadingHearing {
  final DateTime date;
  final int readingMinutes;
  final int hearingMinutes;

  const DailyReadingHearing({
    required this.date,
    required this.readingMinutes,
    required this.hearingMinutes,
  });
}

/// Reading/hearing totals for one student over a window — used for the
/// super_admin leaderboard report. Shared with the per-student chart logic
/// below so both features can never disagree on what "this week" means or
/// how minutes are summed.
class StudentReadingHearingTotal {
  final String uid;
  final String name;
  final int readingMinutes;
  final int hearingMinutes;

  const StudentReadingHearingTotal({
    required this.uid,
    required this.name,
    required this.readingMinutes,
    required this.hearingMinutes,
  });

  int get combinedMinutes => readingMinutes + hearingMinutes;
}

String _dateOnlyKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// Builds exactly [days] consecutive days ending today (oldest first), each
/// filled in with that day's reading/hearing minutes from [entries], or 0 if
/// nothing was logged that day — so the chart's X-axis is always complete,
/// never skipping a day just because nothing was submitted.
List<DailyReadingHearing> lastNDaysReadingHearing(List<SadhanaEntry> entries, {int days = 7}) {
  final byDate = <String, SadhanaEntry>{};
  for (final e in entries) {
    byDate[_dateOnlyKey(e.date)] = e;
  }

  final today = DateTime.now();
  final result = <DailyReadingHearing>[];
  for (int i = days - 1; i >= 0; i--) {
    final day = DateTime(today.year, today.month, today.day - i);
    final entry = byDate[_dateOnlyKey(day)];
    result.add(DailyReadingHearing(
      date: day,
      readingMinutes: entry?.readingMinutes ?? 0,
      hearingMinutes: entry?.hearingMinutes ?? 0,
    ));
  }
  return result;
}

/// Sums reading + hearing minutes over the last [days] days — the building
/// block for both the chart (per day) and the leaderboard (per student).
({int reading, int hearing}) totalReadingHearing(List<SadhanaEntry> entries, {int days = 7}) {
  final daily = lastNDaysReadingHearing(entries, days: days);
  final reading = daily.fold<int>(0, (sum, d) => sum + d.readingMinutes);
  final hearing = daily.fold<int>(0, (sum, d) => sum + d.hearingMinutes);
  return (reading: reading, hearing: hearing);
}
