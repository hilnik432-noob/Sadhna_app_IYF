import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../models/sadhana_entry.dart';
import '../services/sadhana_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────
class SadhanaScreen extends StatefulWidget {
  const SadhanaScreen({super.key});
  @override
  State<SadhanaScreen> createState() => _SadhanaScreenState();
}

class _SadhanaScreenState extends State<SadhanaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final svc = context.read<SadhanaService>();
      await svc.loadUserRole();
      await svc.loadTodayEntry();
      await svc.loadHistory();
      if (mounted && !_roleSet(svc)) _showRoleDialog(svc);
    });
  }

  bool _roleSet(SadhanaService svc) =>
      svc.userRole != UserRole.student || true; // role already loaded from DB

  void _showRoleDialog(SadhanaService svc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RoleDialog(onSelected: (role) => svc.saveUserRole(role)),
    );
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sadhana'),
      actions: [
        IconButton(
          icon: const Icon(Icons.manage_accounts_rounded),
          tooltip: 'Change my role',
          onPressed: () => _showRoleDialog(context.read<SadhanaService>()),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: const [Tab(text: "Today's Log"), Tab(text: 'History')],
      ),
    ),
    body: TabBarView(
      controller: _tabController,
      children: const [_TodayLogTab(), _HistoryTab()],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Role selection dialog
// ─────────────────────────────────────────────────────────────────────────────
class _RoleDialog extends StatefulWidget {
  final ValueChanged<UserRole> onSelected;
  const _RoleDialog({required this.onSelected});
  @override
  State<_RoleDialog> createState() => _RoleDialogState();
}

class _RoleDialogState extends State<_RoleDialog> {
  UserRole? _chosen;

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text('Who are you?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('This helps us show the right sections for your sadhana log.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ...UserRole.values.map((role) => RadioListTile<UserRole>(
          value: role, groupValue: _chosen,
          activeColor: AppColors.primary,
          title: Text(role.label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
          onChanged: (v) => setState(() => _chosen = v),
        )),
      ],
    ),
    actions: [
      ElevatedButton(
        onPressed: _chosen == null ? null : () {
          widget.onSelected(_chosen!);
          Navigator.pop(context);
        },
        child: const Text('Save'),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Today's log tab
// ─────────────────────────────────────────────────────────────────────────────
class _TodayLogTab extends StatefulWidget {
  const _TodayLogTab();
  @override
  State<_TodayLogTab> createState() => _TodayLogTabState();
}

class _TodayLogTabState extends State<_TodayLogTab> {
  // Core
  int       _japaRounds    = 0;
  bool      _mangalAarti   = false;
  bool      _morningProgram= false;
  int       _readingMin    = 0;
  TimeOfDay _wakeUpTime    = const TimeOfDay(hour: 4, minute: 30);
  final     _notesCtrl     = TextEditingController();

  // Hearing
  int    _hearingMin  = 0;
  final  _hearingCtrl = TextEditingController();
  Uint8List? _hearingFileBytes;
  String     _hearingFileName = '';
  SadhanaFile? _uploadedFile;

  // Study
  int   _studyMin  = 0;
  final _studyCtrl = TextEditingController();

  // Job
  int _jobMin = 0;

  // Seva
  int   _sevaMin  = 0;
  final _sevaCtrl = TextEditingController();

  // Senses
  bool _ear = true, _eye = true, _nose = true, _tongue = true, _skin = true;
  final _senseMissedCtrl = TextEditingController();
  final _senseWrongCtrl  = TextEditingController();

  // Mobile
  int   _mobileMin  = 0;
  final _mobileCtrl = TextEditingController();
  int   _mobileVow  = 0;

  // Free time
  int   _freeTimeMin    = 0;
  final _facilitatorCtrl = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_notesCtrl, _hearingCtrl, _studyCtrl, _sevaCtrl,
      _mobileCtrl, _senseMissedCtrl, _senseWrongCtrl, _facilitatorCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf','doc','docx','txt','jpg','jpeg','png'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _hearingFileBytes  = result.files.single.bytes;
        _hearingFileName   = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final svc  = context.read<SadhanaService>();
    final uid  = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Upload file if selected
    SadhanaFile? fileData;
    if (_hearingFileBytes != null) {
      fileData = await svc.uploadHearingFile(
        bytes: _hearingFileBytes!, fileName: _hearingFileName);
    }

    final entry = SadhanaEntry(
      id: '', userId: uid,
      date:         DateTime.now(),
      userRole:     svc.userRole.name,
      japaRounds:   _japaRounds,
      mangalAarti:  _mangalAarti,
      morningProgram: _morningProgram,
      readingMinutes: _readingMin,
      wakeUpTime:   _wakeUpTime.format(context),
      notes:        _notesCtrl.text,
      hearingMinutes: _hearingMin,
      hearingRemark:  _hearingCtrl.text,
      hearingFile:    fileData,
      studyMinutes:   _studyMin,
      studyRemark:    _studyCtrl.text,
      jobMinutes:     _jobMin,
      sevaMinutes:    _sevaMin,
      sevaDescription: _sevaCtrl.text,
      senseControl: SenseControl(
        ear: _ear, eye: _eye, nose: _nose, tongue: _tongue, skin: _skin,
        missed:    _senseMissedCtrl.text,
        wrongDone: _senseWrongCtrl.text,
      ),
      mobileMinutes:  _mobileMin,
      mobileDescription: _mobileCtrl.text,
      mobileVowReduceMinutes: _mobileVow,
      freeTimeMinutes: _freeTimeMin,
      facilitatorNote: _facilitatorCtrl.text,
    );

    try {
      await svc.submitSadhana(entry);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sadhana submitted! Hare Krishna 🙏'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final svc  = context.watch<SadhanaService>();
    final role = svc.userRole;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StreakBanner(streakCount: svc.streakCount),
        const SizedBox(height: 12),
        Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Poppins')),
        const SizedBox(height: 4),
        Row(children: [
          const Text("Today's Sadhana Log",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          const Spacer(),
          Chip(
            label: Text(role.label,
                style: const TextStyle(fontSize: 11, fontFamily: 'Poppins', color: Colors.white)),
            backgroundColor: AppColors.accent,
            padding: EdgeInsets.zero,
          ),
        ]),
        const SizedBox(height: 16),

        // ── 1. Core ──────────────────────────────────────────────────────
        _SectionCard(
          title: 'Morning Program', icon: Icons.wb_sunny_rounded, color: const Color(0xFFF59E0B),
          child: Column(children: [
            _CounterTile(label: 'Japa Rounds', value: _japaRounds, suffix: 'rounds',
              onDec: () => setState(() => _japaRounds = (_japaRounds - 1).clamp(0, 64)),
              onInc: () => setState(() => _japaRounds = (_japaRounds + 1).clamp(0, 64))),
            const Divider(height: 1),
            _ToggleTile('Mangal Aarti',    _mangalAarti,    (v) => setState(() => _mangalAarti   = v)),
            const Divider(height: 1),
            _ToggleTile('Morning Program', _morningProgram, (v) => setState(() => _morningProgram = v)),
            const Divider(height: 1),
            _TimeTile(label: 'Wake-up Time', time: _wakeUpTime,
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: _wakeUpTime);
                if (t != null) setState(() => _wakeUpTime = t);
              }),
          ]),
        ),
        const SizedBox(height: 12),

        // ── 2. Reading ───────────────────────────────────────────────────
        _SectionCard(
          title: 'Reading', icon: Icons.menu_book_rounded, color: const Color(0xFF059669),
          child: _CounterTile(label: 'Reading', value: _readingMin, suffix: 'min',
            onDec: () => setState(() => _readingMin = (_readingMin - 5).clamp(0, 300)),
            onInc: () => setState(() => _readingMin = (_readingMin + 5).clamp(0, 300))),
        ),
        const SizedBox(height: 12),

        // ── 3. Hearing ───────────────────────────────────────────────────
        _SectionCard(
          title: 'Hearing', icon: Icons.headphones_rounded, color: AppColors.accent,
          child: Column(children: [
            _CounterTile(label: 'Hearing', value: _hearingMin, suffix: 'min',
              onDec: () => setState(() => _hearingMin = (_hearingMin - 5).clamp(0, 300)),
              onInc: () => setState(() => _hearingMin = (_hearingMin + 5).clamp(0, 300))),
            const SizedBox(height: 10),
            _WordLimitField(
              controller: _hearingCtrl,
              hint: 'Which lecture did you hear today? (150 words max)',
              maxWords: 150,
            ),
            const SizedBox(height: 10),
            // File upload
            Row(children: [
              Expanded(
                child: Text(
                  _hearingFileName.isEmpty ? 'Upload notes file (PDF, DOC, image)' : _hearingFileName,
                  style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 12,
                    color: _hearingFileName.isEmpty ? AppColors.textSecondary : AppColors.accent,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: kIsWeb ? null : _pickFile, // file_picker on web needs extra setup
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: Text(_hearingFileName.isEmpty ? 'Attach' : 'Change',
                    style: const TextStyle(fontFamily: 'Poppins')),
              ),
            ]),
            if (kIsWeb)
              const Text('File upload available in Android app only.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Poppins')),
          ]),
        ),
        const SizedBox(height: 12),

        // ── 4. Study (student only) ──────────────────────────────────────
        if (role.hasStudy) ...[
          _SectionCard(
            title: 'Study Time', icon: Icons.school_rounded, color: const Color(0xFF0284C7),
            child: Column(children: [
              _CounterTile(label: 'Study', value: _studyMin, suffix: 'min',
                onDec: () => setState(() => _studyMin = (_studyMin - 5).clamp(0, 600)),
                onInc: () => setState(() => _studyMin = (_studyMin + 5).clamp(0, 600))),
              const SizedBox(height: 10),
              _WordLimitField(
                controller: _studyCtrl,
                hint: 'What did you study today? (1000 words max)',
                maxWords: 1000,
                maxLines: 4,
              ),
            ]),
          ),
          const SizedBox(height: 12),
        ],

        // ── 5. Job time (job only) ────────────────────────────────────────
        if (role.hasJob) ...[
          _SectionCard(
            title: 'Job / Work Time', icon: Icons.work_rounded, color: const Color(0xFF64748B),
            child: _CounterTile(label: 'Work', value: _jobMin, suffix: 'min',
              onDec: () => setState(() => _jobMin = (_jobMin - 15).clamp(0, 720)),
              onInc: () => setState(() => _jobMin = (_jobMin + 15).clamp(0, 720))),
          ),
          const SizedBox(height: 12),
        ],

        // ── 6. Seva ──────────────────────────────────────────────────────
        _SectionCard(
          title: 'Seva', icon: Icons.volunteer_activism_rounded, color: AppColors.primary,
          child: Column(children: [
            _CounterTile(label: 'Seva', value: _sevaMin, suffix: 'min',
              onDec: () => setState(() => _sevaMin = (_sevaMin - 5).clamp(0, 300)),
              onInc: () => setState(() => _sevaMin = (_sevaMin + 5).clamp(0, 300))),
            const SizedBox(height: 10),
            TextField(
              controller: _sevaCtrl, maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'What seva did you perform?',
                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ── 7. Sense Control ─────────────────────────────────────────────
        _SectionCard(
          title: 'Sense Control', icon: Icons.self_improvement_rounded, color: const Color(0xFF7C3AED),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Were all your senses engaged in devotional activities?',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              _SenseChip('👂 Ear',    _ear,    (v) => setState(() => _ear    = v)),
              _SenseChip('👁 Eye',    _eye,    (v) => setState(() => _eye    = v)),
              _SenseChip('👃 Nose',   _nose,   (v) => setState(() => _nose   = v)),
              _SenseChip('👅 Tongue', _tongue, (v) => setState(() => _tongue = v)),
              _SenseChip('🖐 Skin',   _skin,   (v) => setState(() => _skin   = v)),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _senseMissedCtrl, maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'What devotional engagement did you miss?',
                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _senseWrongCtrl, maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Any wrong engagement of senses today?',
                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ── 8. Mobile ────────────────────────────────────────────────────
        _SectionCard(
          title: 'Mobile (Time Pass)', icon: Icons.phone_android_rounded, color: const Color(0xFFDC2626),
          child: Column(children: [
            _CounterTile(label: 'Screen time', value: _mobileMin, suffix: 'min',
              onDec: () => setState(() => _mobileMin = (_mobileMin - 5).clamp(0, 480)),
              onInc: () => setState(() => _mobileMin = (_mobileMin + 5).clamp(0, 480))),
            const SizedBox(height: 10),
            TextField(
              controller: _mobileCtrl, maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'What did you consume? (social media, videos, etc.)',
                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🙏 VOW',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                        fontSize: 14, color: AppColors.primary)),
                const SizedBox(height: 6),
                const Text('"I will reduce my screen time this week by:"',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                        fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                _CounterTile(label: 'Reduce by', value: _mobileVow, suffix: 'min/week',
                  onDec: () => setState(() => _mobileVow = (_mobileVow - 5).clamp(0, 300)),
                  onInc: () => setState(() => _mobileVow = (_mobileVow + 5).clamp(0, 300))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ── 9. Free Time ─────────────────────────────────────────────────
        _SectionCard(
          title: 'Free Time Left', icon: Icons.hourglass_empty_rounded, color: const Color(0xFF0891B2),
          child: Column(children: [
            _CounterTile(label: 'Free time remaining', value: _freeTimeMin, suffix: 'min',
              onDec: () => setState(() => _freeTimeMin = (_freeTimeMin - 5).clamp(0, 480)),
              onInc: () => setState(() => _freeTimeMin = (_freeTimeMin + 5).clamp(0, 480))),
            const SizedBox(height: 10),
            _FacilitatorGuidanceBox(
              existingNote: svc.todayEntry?.facilitatorNote ?? '',
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ── Notes ─────────────────────────────────────────────────────────
        TextField(
          controller: _notesCtrl, maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Any additional notes...',
            prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 24),

        // ── Submit ────────────────────────────────────────────────────────
        ElevatedButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check_circle_rounded),
          label: Text(_submitting ? 'Submitting...' : 'Submit Sadhana'),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// Read-only facilitator guidance box (students cannot edit)
class _FacilitatorGuidanceBox extends StatelessWidget {
  final String existingNote;
  const _FacilitatorGuidanceBox({required this.existingNote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0891B2).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0891B2).withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF0891B2)),
          const SizedBox(width: 6),
          const Text("Facilitator's Guidance",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                  fontSize: 13, color: Color(0xFF0891B2))),
        ]),
        const SizedBox(height: 8),
        existingNote.isEmpty
            ? const Text(
                'Your facilitator will add guidance for your free time here.',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                    color: AppColors.textSecondary, fontStyle: FontStyle.italic))
            : Text(existingNote,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, height: 1.5)),
        const SizedBox(height: 6),
        const Text('Only your facilitator can edit this field.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History tab
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final history = context.watch<SadhanaService>().history;
    if (history.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.history_rounded, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text('No sadhana logged yet',
              style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins')),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, i) {
        final e = history[i];
        final score = e.score;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _scoreColor(score).withOpacity(0.15),
              child: Text('$score',
                  style: TextStyle(color: _scoreColor(score),
                      fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
            ),
            title: Text(DateFormat('EEE, MMM d').format(e.date),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins')),
            subtitle: Text(
              '${e.japaRounds} rounds • ${e.readingMinutes}m read • ${e.hearingMinutes}m hear',
              style: const TextStyle(fontSize: 12, fontFamily: 'Poppins')),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (e.sevaMinutes > 0)
                    _HistoryRow('Seva', '${e.sevaMinutes} min — ${e.sevaDescription}'),
                  if (e.studyMinutes > 0)
                    _HistoryRow('Study', '${e.studyMinutes} min'),
                  if (e.jobMinutes > 0)
                    _HistoryRow('Job', '${e.jobMinutes} min'),
                  if (e.mobileMinutes > 0)
                    _HistoryRow('Mobile', '${e.mobileMinutes} min (vow: -${e.mobileVowReduceMinutes} min/wk)'),
                  if (e.freeTimeMinutes > 0)
                    _HistoryRow('Free time', '${e.freeTimeMinutes} min'),
                  if (e.hearingRemark.isNotEmpty)
                    _HistoryRow('Hearing', e.hearingRemark),
                  if (e.hearingFile != null && !e.hearingFile!.isExpired)
                    _HistoryRow('Notes file', e.hearingFile!.name),
                  if (e.hearingFile != null && e.hearingFile!.isExpired)
                    _HistoryRow('Notes file', '⏱ Expired (7-day retention)'),
                  _HistoryRow('Senses',
                    '${e.senseControl.engagedCount}/5 engaged properly'),
                  if (e.facilitatorNote.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0891B2).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Facilitator\'s Guidance',
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                                fontSize: 12, color: Color(0xFF0891B2))),
                        const SizedBox(height: 4),
                        Text(e.facilitatorNote,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                      ]),
                    ),
                ]),
              ),
            ],
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

Widget _HistoryRow(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 2),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 90, child: Text('$label:', style: const TextStyle(
        fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600,
        color: AppColors.textSecondary))),
    Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12))),
  ]),
);

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String  title;
  final IconData icon;
  final Color   color;
  final Widget  child;
  const _SectionCard({required this.title, required this.icon, required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins')),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    ),
  );
}

class _CounterTile extends StatelessWidget {
  final String   label;
  final int      value;
  final String   suffix;
  final VoidCallback onDec, onInc;
  const _CounterTile({required this.label, required this.value, required this.suffix,
    required this.onDec, required this.onInc});

  @override
  Widget build(BuildContext context) => Row(children: [
    IconButton(onPressed: onDec,
        icon: const Icon(Icons.remove_circle_outline_rounded), color: AppColors.primary, iconSize: 28),
    Expanded(child: Center(child: Text('$value $suffix',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Poppins')))),
    IconButton(onPressed: onInc,
        icon: const Icon(Icons.add_circle_outline_rounded), color: AppColors.primary, iconSize: 28),
  ]);
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final bool   value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: const TextStyle(fontSize: 14, fontFamily: 'Poppins')),
    value: value, onChanged: onChanged, activeColor: AppColors.primary,
  );
}

class _TimeTile extends StatelessWidget {
  final String   label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeTile({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: const TextStyle(fontSize: 14, fontFamily: 'Poppins')),
    trailing: TextButton(
      onPressed: onTap,
      child: Text(time.format(context),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              fontFamily: 'Poppins', color: AppColors.primary)),
    ),
  );
}

class _SenseChip extends StatelessWidget {
  final String label;
  final bool   value;
  final ValueChanged<bool> onChanged;
  const _SenseChip(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
    selected: value,
    onSelected: onChanged,
    selectedColor: AppColors.success.withOpacity(0.2),
    checkmarkColor: AppColors.success,
    backgroundColor: Colors.red.withOpacity(0.1),
  );
}

// Word-limited text field
class _WordLimitField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final int    maxWords;
  final int    maxLines;
  const _WordLimitField({
    required this.controller, required this.hint,
    required this.maxWords, this.maxLines = 3,
  });
  @override
  State<_WordLimitField> createState() => _WordLimitFieldState();
}

class _WordLimitFieldState extends State<_WordLimitField> {
  int _wordCount = 0;

  int _countWords(String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  @override
  Widget build(BuildContext context) {
    final over = _wordCount > widget.maxWords;
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      TextField(
        controller: widget.controller,
        maxLines: widget.maxLines,
        onChanged: (v) => setState(() => _wordCount = _countWords(v)),
        inputFormatters: [
          TextInputFormatter.withFunction((old, newVal) {
            if (_countWords(newVal.text) > widget.maxWords) return old;
            return newVal;
          }),
        ],
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
      ),
      const SizedBox(height: 4),
      Text('$_wordCount / ${widget.maxWords} words',
          style: TextStyle(
            fontFamily: 'Poppins', fontSize: 11,
            color: over ? AppColors.error : AppColors.textSecondary,
          )),
    ]);
  }
}

class _StreakBanner extends StatelessWidget {
  final int streakCount;
  const _StreakBanner({required this.streakCount});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFFD700)]),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: [
      const Text('🔥', style: TextStyle(fontSize: 28)),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$streakCount Day Streak!',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700,
                fontSize: 16, fontFamily: 'Poppins')),
        const Text('Keep it up, Prabhu!',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins')),
      ]),
      const Spacer(),
      const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 32),
    ]),
  );
}
