import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../sadhana/models/sadhana_entry.dart';
import '../../sadhana/services/sadhana_repository.dart';

/// Shows one student's sadhna history (via the shared SadhanaRepository —
/// same query used by the student's own History tab) and lets the viewing
/// facilitator/admin write guidance into `facilitatorNote` per entry. This
/// is what finally makes the "Only your facilitator can edit this field"
/// promise shown on the student's own Sadhana screen actually true.
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
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
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
                                onPressed: () => _editNote(e),
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
            },
          );
        },
      ),
    );
  }
}
