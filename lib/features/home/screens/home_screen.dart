import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/services/auth_service.dart';
import '../../sadhana/screens/sadhana_screen.dart';
import '../../content/screens/content_screen.dart';
import '../../events/screens/events_screen.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _DashboardTab(),
    SadhanaScreen(),
    ContentScreen(),
    EventsScreen(),
    ProfileScreen(),
  ];

  // Donations tab removed — will be added later

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, AppStrings.home),
      (Icons.self_improvement_rounded, Icons.self_improvement_outlined, AppStrings.sadhana),
      (Icons.menu_book_rounded, Icons.menu_book_outlined, AppStrings.content),
      (Icons.event_rounded, Icons.event_outlined, AppStrings.events),
      (Icons.person_rounded, Icons.person_outlined, AppStrings.profile),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBg,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (i) {
              final isSelected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? items[i].$1 : items[i].$2,
                        color: isSelected ? AppColors.secondary : Colors.white54,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].$3,
                        style: TextStyle(
                          color: isSelected ? AppColors.secondary : Colors.white38,
                          fontSize: 10,
                          fontFamily: 'Poppins',
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFFE55A24)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Hare Krishna! 🙏',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins'),
                    ),
                    Text(
                      user?.displayName?.split(' ').first ?? 'Devotee',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!) as ImageProvider
                      : const AssetImage('assets/images/iyf_logo.jpg'),
                  backgroundColor: AppColors.secondary,
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _QuoteCard(),
                const SizedBox(height: 16),
                _QuickActionsGrid(),
                const SizedBox(height: 16),
                _TodaySadhanaCard(),
                const SizedBox(height: 16),
                _UpcomingEventCard(),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B21A8), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.format_quote_rounded, color: Colors.white54, size: 20),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('BG 9.22', style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Poppins')),
            ),
          ]),
          const SizedBox(height: 8),
          const Text(
            '"To those who are constantly devoted to serving Me with love, I give the understanding by which they can come to Me."',
            style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Poppins', height: 1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            '— Bhagavad Gita',
            style: TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Poppins', fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.self_improvement_rounded, 'Log Sadhana', AppColors.primary, 1),
      (Icons.menu_book_rounded, 'Bhagavad Gita', const Color(0xFF059669), 2),
      (Icons.event_rounded, 'Events', const Color(0xFF6B21A8), 3),
      (Icons.person_rounded, 'Profile', const Color(0xFFDC2626), 4),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: actions.map((a) {
        return GestureDetector(
          onTap: () {
            // Navigate to respective tab
            final homeState = context.findAncestorStateOfType<_HomeScreenState>();
            homeState?.setState(() => homeState._currentIndex = a.$4);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: a.$3.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: a.$3.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a.$1, color: a.$3, size: 28),
                const SizedBox(height: 6),
                Text(a.$2, style: TextStyle(color: a.$3, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TodaySadhanaCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.self_improvement_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text("Today's Sadhana", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, fontFamily: 'Poppins')),
              const Spacer(),
              TextButton(
                onPressed: () {
                  final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                  homeState?.setState(() => homeState._currentIndex = 1);
                },
                child: const Text('Log →', style: TextStyle(color: AppColors.primary, fontFamily: 'Poppins')),
              ),
            ]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniStat(label: 'Rounds', value: '0', icon: Icons.radio_button_checked_rounded),
                _MiniStat(label: 'Reading', value: '0 min', icon: Icons.menu_book_outlined),
                _MiniStat(label: 'Aarti', value: 'No', icon: Icons.music_note_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Poppins')),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'Poppins')),
      ],
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upcoming Events', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, fontFamily: 'Poppins')),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.event_rounded, color: AppColors.primary),
            ),
            title: const Text('Janmashtami Celebration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins')),
            subtitle: const Text('Aug 16 • 6:00 AM', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Poppins')),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Register', style: TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }
}
