import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../sadhana/models/sadhana_entry.dart';
import '../../sadhana/services/sadhana_repository.dart';
import '../../sadhana/services/reading_hearing_stats.dart';

/// Shows one student's sadhna history (via the shared SadhanaRepository —
/// same query used by the student's own History tab), a weekly reading/
/// hearing chart, and lets the viewing facilitator/admin write guidance
/// into `facilitatorNote` per entry. This is what finally makes the "Only
/// your facilitator can edit this field" promise shown on the student's
/// own Sadhana screen actually true.
class StudentDetailScreen extends StatefulWidget {
  final String uid;
  final String name;

  const StudentDetailScreen({super.key, required this.uid, required this.name});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _repo = SadhanaRepository();
  late Future<List<SadhanaEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchHistory(widget.uid);
  }

  void _reload() => setState(() => _future = _repo.fetchHistory(widget.uid));

  Future<void> _editNote(SadhanaEntry entry) async {
    final controller = TextEditingController(text: entry.facilitatorNote);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Guidance for ${DateFormat('EEE, MMM d').format(entry.date)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Write guidance for the free-time section...'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save Guidance'),
              ),
            ),
          ]),
        ),
      ),
    );

    if (saved == true) {
      await _repo.writeFacilitatorNote(
        studentUid: widget.uid, logDocId: entry.id, entryDate: entry.date, note: controller.text.trim(),
      );
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guidance saved'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name.isNotEmpty ? widget.name : 'Student History')),
      body: FutureBuilder<List<SadhanaEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final entries = snap.data ?? [];
          if (entries.isEmpty) {
            return const Center(child: Text('No sadhna logged yet',
                style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length + 1, // index 0 = chart header
            itemBuilder: (context, i) {
              if (i == 0) return _WeeklyReadingHearingChart(entries: entries);
              return _EntryCard(entry: entries[i - 1], onEditNote: _editNote);
            },
          );
        },
      ),
    );
  }
}

/// Weekly reading + hearing minutes, one grouped bar pair per day, last 7
/// days. Built on the shared lastNDaysReadingHearing() helper — the exact
/// same aggregation the super_admin leaderboard uses for its totals, so a
/// student's chart and their leaderboard entry can never disagree.
class _WeeklyReadingHearingChart extends StatelessWidget {
  final List<SadhanaEntry> entries;
  const _WeeklyReadingHearingChart({required this.entries});

  static const _readingColor = Color(0xFF059669);
  static const _hearingColor = AppColors.accent;

  @override
  Widget build(BuildContext context) {
    final daily = lastNDaysReadingHearing(entries, days: 7);
    final maxMinutes = daily
        .map((d) => d.readingMinutes > d.hearingMinutes ? d.readingMinutes : d.hearingMinutes)
        .fold<int>(10, (a, b) => a > b ? a : b);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Text('This Week — Reading & Hearing',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Poppins')),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _LegendDot(color: _readingColor, label: 'Reading'),
            const SizedBox(width: 16),
            _LegendDot(color: _hearingColor, label: 'Hearing'),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: (maxMinutes * 1.2).ceilToDouble(),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= daily.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(DateFormat('E').format(daily[i].date),
                              style: const TextStyle(fontSize: 11, fontFamily: 'Poppins')),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < daily.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(toY: daily[i].readingMinutes.toDouble(), color: _readingColor, width: 7,
                          borderRadius: BorderRadius.circular(3)),
                      BarChartRodData(toY: daily[i].hearingMinutes.toDouble(), color: _hearingColor, width: 7,
                          borderRadius: BorderRadius.circular(3)),
                    ]),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 12, fontFamily: 'Poppins', color: AppColors.textSecondary)),
  ]);
}

class _EntryCard extends StatelessWidget {
  final SadhanaEntry entry;
  final ValueChanged<SadhanaEntry> onEditNote;
  const _EntryCard({required this.entry, required this.onEditNote});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(child: Text('${e.score}')),
        title: Text(DateFormat('EEE, MMM d').format(e.date),
            style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
        subtitle: Text('${e.japaRounds} rounds • ${e.readingMinutes}m read • ${e.hearingMinutes}m hear',
            style: const TextStyle(fontSize: 12, fontFamily: 'Poppins')),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (e.sevaDescription.isNotEmpty) Text('Seva: ${e.sevaDescription}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
              if (e.hearingRemark.isNotEmpty) Text('Hearing: ${e.hearingRemark}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
              if (e.notes.isNotEmpty) Text('Notes: ${e.notes}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0891B2).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.facilitatorNote.isEmpty ? 'No guidance written yet.' : e.facilitatorNote,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => onEditNote(e),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Write Guidance'),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
