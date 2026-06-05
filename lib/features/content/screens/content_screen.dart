import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../models/content_item.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    ('Gita', ContentType.gita, Icons.auto_stories_rounded),
    ('Lectures', ContentType.lecture, Icons.headphones_rounded),
    ('Kirtans', ContentType.kirtan, Icons.music_note_rounded),
    ('Books', ContentType.book, Icons.book_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
        title: const Text('Devotional Content'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(icon: Icon(t.$3, size: 18), text: t.$1)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((t) => _ContentList(type: t.$2)).toList(),
      ),
    );
  }
}

class _ContentList extends StatelessWidget {
  final ContentType type;
  const _ContentList({required this.type});

  @override
  Widget build(BuildContext context) {
    if (type == ContentType.gita) return const _GitaChapterList();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('content')
          .where('type', isEqualTo: type.name)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _EmptyContent(type: type);
        }
        final items = snap.data!.docs.map((d) => ContentItem.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, i) => _ContentCard(item: items[i]),
        );
      },
    );
  }
}

class _GitaChapterList extends StatelessWidget {
  const _GitaChapterList();

  static const _chapters = [
    ('Chapter 1', 'Observing the Armies on the Battlefield', 47),
    ('Chapter 2', 'Contents of the Gita Summarized', 72),
    ('Chapter 3', 'Karma-yoga', 43),
    ('Chapter 4', 'Transcendental Knowledge', 42),
    ('Chapter 5', 'Karma-yoga — Action in Krsna Consciousness', 29),
    ('Chapter 6', 'Dhyana-yoga', 47),
    ('Chapter 7', 'Knowledge of the Absolute', 30),
    ('Chapter 8', 'Attaining the Supreme', 28),
    ('Chapter 9', 'The Most Confidential Knowledge', 34),
    ('Chapter 10', 'The Opulence of the Absolute', 42),
    ('Chapter 11', 'The Universal Form', 55),
    ('Chapter 12', 'Devotional Service', 20),
    ('Chapter 13', 'Nature, the Enjoyer, and Consciousness', 35),
    ('Chapter 14', 'The Three Modes of Material Nature', 27),
    ('Chapter 15', 'The Yoga of the Supreme Person', 20),
    ('Chapter 16', 'The Divine and Demoniac Natures', 24),
    ('Chapter 17', 'The Divisions of Faith', 28),
    ('Chapter 18', 'Conclusion — The Perfection of Renunciation', 78),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _chapters.length,
      itemBuilder: (context, i) {
        final ch = _chapters[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.accent.withOpacity(0.1),
              child: Text('${i + 1}', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
            ),
            title: Text(ch.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins')),
            subtitle: Text(ch.$2, style: const TextStyle(fontSize: 12, fontFamily: 'Poppins')),
            trailing: Text('${ch.$3} verses', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'Poppins')),
            onTap: () => _showChapterDialog(context, i + 1, ch.$1, ch.$2),
          ),
        );
      },
    );
  }

  void _showChapterDialog(BuildContext context, int num, String title, String subtitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: AppColors.accent.withOpacity(0.1),
                child: Text('$num', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Poppins')),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Poppins')),
              ])),
            ]),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.auto_stories_rounded),
              label: const Text('Read Chapter'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ContentItem item;
  const _ContentCard({required this.item});

  Color get _typeColor {
    switch (item.type) {
      case ContentType.lecture: return AppColors.accent;
      case ContentType.kirtan: return AppColors.primary;
      default: return AppColors.success;
    }
  }

  IconData get _typeIcon {
    switch (item.type) {
      case ContentType.lecture: return Icons.headphones_rounded;
      case ContentType.kirtan: return Icons.music_note_rounded;
      default: return Icons.play_circle_rounded;
    }
  }

  Future<void> _launch(BuildContext context) async {
    final uri = Uri.tryParse(item.contentUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _launch(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon, color: _typeColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins')),
                    const SizedBox(height: 3),
                    Text(item.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Poppins')),
                    if (item.durationLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item.durationLabel, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontFamily: 'Poppins')),
                    ],
                  ],
                ),
              ),
              Icon(Icons.play_circle_filled_rounded, color: _typeColor, size: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  final ContentType type;
  const _EmptyContent({required this.type});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_music_rounded, size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('No ${type.name} content yet', style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins')),
          const SizedBox(height: 6),
          const Text('Content will appear here once added', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}
