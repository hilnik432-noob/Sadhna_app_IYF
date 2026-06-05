import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../models/sadhana_entry.dart';
import '../services/sadhana_service.dart';

class SadhanaScreen extends StatefulWidget {
  const SadhanaScreen({super.key});

  @override
  State<SadhanaScreen> createState() => _SadhanaScreenState();
}

class _SadhanaScreenState extends State<SadhanaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SadhanaService>().loadTodayEntry();
      context.read<SadhanaService>().loadHistory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sadhana'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Today's Log"),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TodayLogTab(),
          _HistoryTab(),
        ],
      ),
    );
  }
}

class _TodayLogTab extends StatefulWidget {
  const _TodayLogTab();

  @override
  State<_TodayLogTab> createState() => _TodayLogTabState();
}

class _TodayLogTabState extends State<_TodayLogTab> {
  int _japaRounds = 0;
  bool _mangalAarti = false;
  bool _morningProgram = false;
  int _readingMinutes = 0;
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 4, minute: 30);
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final entry = SadhanaEntry(
      id: '',
      userId: uid,
      date: DateTime.now(),
      japaRounds: _japaRounds,
      mangalAarti: _mangalAarti,
      morningProgram: _morningProgram,
      readingMinutes: _readingMinutes,
      wakeUpTime: _wakeUpTime.format(context),
      notes: _notesController.text,
    );
    try {
      await context.read<SadhanaService>().submitSadhana(entry);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sadhana submitted! Hare Krishna 🙏'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SadhanaService>();
    final streakCount = service.streakCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StreakBanner(streakCount: streakCount),
          const SizedBox(height: 16),
          Text(
            DateFormat('EEEE, MMMM d').format(DateTime.now()),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 4),
          const Text("Today's Sadhana Log", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          const SizedBox(height: 20),

          // Japa rounds
          _SadhanaCard(
            title: 'Japa Rounds',
            icon: Icons.radio_button_checked_rounded,
            color: AppColors.primary,
            child: _CounterRow(
              value: _japaRounds,
              onDecrement: () => setState(() => _japaRounds = (_japaRounds - 1).clamp(0, 64)),
              onIncrement: () => setState(() => _japaRounds = (_japaRounds + 1).clamp(0, 64)),
              suffix: 'rounds',
            ),
          ),
          const SizedBox(height: 12),

          // Morning program
          _SadhanaCard(
            title: 'Morning Program',
            icon: Icons.wb_sunny_rounded,
            color: const Color(0xFFF59E0B),
            child: Column(
              children: [
                _ToggleRow(
                  label: 'Mangal Aarti',
                  value: _mangalAarti,
                  onChanged: (v) => setState(() => _mangalAarti = v),
                ),
                const Divider(height: 1),
                _ToggleRow(
                  label: 'Morning Program',
                  value: _morningProgram,
                  onChanged: (v) => setState(() => _morningProgram = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Reading
          _SadhanaCard(
            title: 'Reading',
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF059669),
            child: _CounterRow(
              value: _readingMinutes,
              onDecrement: () => setState(() => _readingMinutes = (_readingMinutes - 5).clamp(0, 120)),
              onIncrement: () => setState(() => _readingMinutes = (_readingMinutes + 5).clamp(0, 120)),
              suffix: 'min',
            ),
          ),
          const SizedBox(height: 12),

          // Wake-up time
          _SadhanaCard(
            title: 'Wake-up Time',
            icon: Icons.alarm_rounded,
            color: const Color(0xFF6B21A8),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _wakeUpTime.format(context),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
              ),
              trailing: TextButton(
                onPressed: () async {
                  final t = await showTimePicker(context: context, initialTime: _wakeUpTime);
                  if (t != null) setState(() => _wakeUpTime = t);
                },
                child: const Text('Change', style: TextStyle(color: AppColors.primary)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Notes
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add notes (optional)...',
              prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.check_circle_rounded),
            label: Text(_submitting ? 'Submitting...' : 'Submit Sadhana'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  final int streakCount;
  const _StreakBanner({required this.streakCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFFD700)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$streakCount Day Streak!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Poppins')),
              const Text('Keep it up, Prabhu!', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins')),
            ],
          ),
          const Spacer(),
          const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 32),
        ],
      ),
    );
  }
}

class _SadhanaCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _SadhanaCard({required this.title, required this.icon, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins')),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final String suffix;

  const _CounterRow({required this.value, required this.onDecrement, required this.onIncrement, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          color: AppColors.primary,
          iconSize: 30,
        ),
        Expanded(
          child: Center(
            child: Text('$value $suffix', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          ),
        ),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add_circle_outline_rounded),
          color: AppColors.primary,
          iconSize: 30,
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14, fontFamily: 'Poppins')),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final history = context.watch<SadhanaService>().history;

    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('No sadhana logged yet', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins')),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, i) {
        final entry = history[i];
        final score = entry.score;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _scoreColor(score).withOpacity(0.15),
              child: Text('$score', style: TextStyle(color: _scoreColor(score), fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
            ),
            title: Text(DateFormat('EEE, MMM d').format(entry.date), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins')),
            subtitle: Text('${entry.japaRounds} rounds • ${entry.readingMinutes} min reading', style: const TextStyle(fontSize: 12, fontFamily: 'Poppins')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (entry.mangalAarti) const Icon(Icons.music_note_rounded, size: 16, color: AppColors.primary),
                if (entry.morningProgram) const Icon(Icons.wb_sunny_rounded, size: 16, color: Color(0xFFF59E0B)),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.secondary;
    return AppColors.error;
  }
}
