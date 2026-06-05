import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../models/event_model.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('startDate')
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return _buildSampleEvents(context);
          }

          final events = snap.data!.docs
              .map((d) => EventModel.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();

          final liveEvents = events.where((e) => e.isLive || e.isOngoing).toList();
          final upcoming = events.where((e) => e.isUpcoming).toList();
          final past = events.where((e) => !e.isUpcoming && !e.isOngoing).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (liveEvents.isNotEmpty) ...[
                _SectionHeader(title: '🔴 Live Now', color: AppColors.error),
                ...liveEvents.map((e) => _EventCard(event: e, isLive: true)),
                const SizedBox(height: 8),
              ],
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(title: 'Upcoming Events'),
                ...upcoming.map((e) => _EventCard(event: e)),
                const SizedBox(height: 8),
              ],
              if (past.isNotEmpty) ...[
                _SectionHeader(title: 'Past Events', color: AppColors.textSecondary),
                ...past.map((e) => _EventCard(event: e, isPast: true)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSampleEvents(BuildContext context) {
    final now = DateTime.now();
    final sampleEvents = [
      EventModel(
        id: '1',
        title: 'Janmashtami Mahotsav 2026',
        description: 'Join us for a grand celebration of Lord Krishna\'s appearance day with kirtan, drama, and prasad.',
        startDate: DateTime(now.year, 8, 16, 6, 0),
        endDate: DateTime(now.year, 8, 16, 22, 0),
        location: 'ISKCON Temple, Mumbai',
        isFree: true,
        registeredCount: 250,
      ),
      EventModel(
        id: '2',
        title: 'Bhagavad Gita Study Camp',
        description: 'Intensive 7-day study of the Bhagavad Gita with senior devotees.',
        startDate: DateTime(now.year, 7, 10, 9, 0),
        endDate: DateTime(now.year, 7, 17, 18, 0),
        location: 'Online + Offline',
        isFree: false,
        registeredCount: 85,
      ),
      EventModel(
        id: '3',
        title: 'Sunday Love Feast',
        description: 'Weekly program with kirtan, lecture, and prasad for all.',
        startDate: DateTime(now.year, now.month, now.day + (7 - now.weekday) % 7 + 7, 17, 0),
        endDate: DateTime(now.year, now.month, now.day + (7 - now.weekday) % 7 + 7, 20, 0),
        location: 'Local Temple',
        isFree: true,
        registeredCount: 120,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader(title: 'Upcoming Events'),
        ...sampleEvents.map((e) => _EventCard(event: e)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins')),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final bool isLive;
  final bool isPast;

  const _EventCard({required this.event, this.isLive = false, this.isPast = false});

  Future<void> _launchStream(BuildContext context) async {
    final uri = Uri.tryParse(event.liveStreamUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _register(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
            const SizedBox(height: 8),
            Text(event.description, style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins', height: 1.5)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registered successfully! 🙏'), backgroundColor: AppColors.success),
                );
              },
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Confirm Registration'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 10),
                  SizedBox(width: 6),
                  Text('LIVE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Poppins', letterSpacing: 1)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isPast ? AppColors.textSecondary.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMM').format(event.startDate).toUpperCase(),
                            style: TextStyle(
                              color: isPast ? AppColors.textSecondary : AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            DateFormat('d').format(event.startDate),
                            style: TextStyle(
                              color: isPast ? AppColors.textSecondary : AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Poppins')),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat('h:mm a').format(event.startDate)} – ${DateFormat('h:mm a').format(event.endDate)}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Poppins'),
                            ),
                          ]),
                          if (event.location.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(child: Text(event.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
                            ]),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: event.isFree ? AppColors.success.withOpacity(0.1) : AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.isFree ? 'FREE' : 'PAID',
                        style: TextStyle(
                          color: event.isFree ? AppColors.success : AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(event.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Poppins', height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.people_rounded, size: 14, color: AppColors.textSecondary.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Text('${event.registeredCount} registered', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Poppins')),
                    const Spacer(),
                    if (!isPast && isLive && event.liveStreamUrl.isNotEmpty)
                      FilledButton.icon(
                        onPressed: () => _launchStream(context),
                        icon: const Icon(Icons.play_circle_rounded, size: 16),
                        label: const Text('Watch Live'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                      )
                    else if (!isPast)
                      ElevatedButton(
                        onPressed: () => _register(context),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), minimumSize: Size.zero),
                        child: const Text('Register'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
