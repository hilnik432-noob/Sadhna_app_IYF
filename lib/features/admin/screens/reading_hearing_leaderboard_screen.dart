import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../sadhana/services/reading_hearing_stats.dart';
import '../services/admin_service.dart';

/// Every student ranked by combined reading + hearing minutes over the
/// last 7 days, highest investment of time first. Shared by both roles:
///   - super_admin: facilitatorDikshitName = null -> every student
///   - facilitator: facilitatorDikshitName = their own name -> only theirs
class ReadingHearingLeaderboardScreen extends StatefulWidget {
  final String? facilitatorDikshitName;
  const ReadingHearingLeaderboardScreen({super.key, this.facilitatorDikshitName});

  @override
  State<ReadingHearingLeaderboardScreen> createState() => _ReadingHearingLeaderboardScreenState();
}

class _ReadingHearingLeaderboardScreenState extends State<ReadingHearingLeaderboardScreen> {
  final _adminService = AdminService();
  late Future<List<StudentReadingHearingTotal>> _future;

  @override
  void initState() {
    super.initState();
    _future = _adminService.fetchReadingHearingLeaderboard(
      facilitatorDikshitName: widget.facilitatorDikshitName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.facilitatorDikshitName == null
          ? 'Reading & Hearing — Weekly Report (All Students)'
          : 'Reading & Hearing — Weekly Report (My Students)')),
      body: FutureBuilder<List<StudentReadingHearingTotal>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to load report: ${snap.error}',
                style: const TextStyle(fontFamily: 'Poppins')));
          }
          final rows = snap.data ?? [];
          if (rows.isEmpty) {
            return const Center(child: Text('No students found',
                style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = rows[i];
              final isTop = i == 0 && r.combinedMinutes > 0;
              return Card(
                margin: EdgeInsets.zero,
                color: isTop ? AppColors.primary.withOpacity(0.06) : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isTop ? AppColors.primary : AppColors.primary.withOpacity(0.1),
                    child: Text('${i + 1}',
                        style: TextStyle(
                          color: isTop ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w700, fontFamily: 'Poppins',
                        )),
                  ),
                  title: Text(r.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins')),
                  subtitle: Text(
                    'Reading: ${r.readingMinutes}m  •  Hearing: ${r.hearingMinutes}m',
                    style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${r.combinedMinutes}m',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16,
                              fontFamily: 'Poppins', color: AppColors.primary)),
                      const Text('combined', style: TextStyle(fontSize: 10, fontFamily: 'Poppins', color: AppColors.textSecondary)),
                    ],
                  ),
                  isThreeLine: false,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
