import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math' as math;

import '../models/song.dart';
import '../theme/app_colors.dart';
import '../widgets/song_card.dart';
import 'search.dart';
import 'song_detail.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _LandingTab(
            onSearchPressed: () => setState(() => _selectedTab = 1),
          ),
          const Search(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
      ),
    );
  }
}

class _LandingTab extends StatefulWidget {
  final VoidCallback onSearchPressed;

  const _LandingTab({required this.onSearchPressed});

  @override
  State<_LandingTab> createState() => _LandingTabState();
}

class _LandingTabState extends State<_LandingTab> {
  static const _genres = [
    'All',
    'Pop',
    'Hip-Hop',
    'Electronic',
    'Afrobeats',
    'R&B',
    'Latin',
  ];

  int _selectedGenreIndex = 0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _smoothedMotion = 0;
  String _motionLabel = 'Hold still to calibrate';
  String _motionHint = 'We will adapt recommendations from your movement.';

  @override
  void initState() {
    super.initState();
    _startMotionTracking();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  List<Song> get _filteredPopular {
    final label = _genres[_selectedGenreIndex];
    if (label == 'All') return SampleData.popularSongs.toList();

    return SampleData.popularSongs.where((s) => _songMatchesGenre(s, label)).toList();
  }

  bool _songMatchesGenre(Song song, String chipLabel) {
    final g = song.genre.toLowerCase();
    switch (chipLabel.toLowerCase()) {
      case 'hip-hop':
        return g.contains('hip') || g.contains('hop') || g.contains('rap');
      case 'r&b':
        return g.contains('r&b') || g.contains('rnb') || g.contains('soul');
      case 'electronic':
        return g.contains('electronic') || g.contains('edm') || g.contains('house');
      case 'latin':
        return g.contains('latin') || g.contains('reggaeton') || g.contains('salsa');
      default:
        return g == chipLabel.toLowerCase() || g.contains(chipLabel.toLowerCase());
    }
  }

  List<Song> get _motionBasedSongs {
    if (_smoothedMotion > 2.2) {
      return [...SampleData.popularSongs]..sort(
        (a, b) => b.energy.compareTo(a.energy),
      );
    }
    if (_smoothedMotion > 1.1) {
      return [...SampleData.popularSongs]..sort(
        (a, b) => b.danceability.compareTo(a.danceability),
      );
    }
    return [...SampleData.popularSongs]..sort(
      (a, b) => a.energy.compareTo(b.energy),
    );
  }

  void _startMotionTracking() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final magnitude = math.sqrt(
        (event.x * event.x) + (event.y * event.y) + (event.z * event.z),
      );
      final dynamicMotion = (magnitude - 9.81).abs();
      final next = (_smoothedMotion * 0.2) + (dynamicMotion * 0.8);

      String label;
      String hint;
      if (next > 2.2) {
        label = 'Hype mode';
        hint = 'You are moving a lot. Queueing high-energy tracks.';
      } else if (next > 1.1) {
        label = 'Groove mode';
        hint = 'Steady movement detected. Keeping it danceable.';
      } else {
        label = 'Chill mode';
        hint = 'Low movement. Serving smoother, lower-energy picks.';
      }

      if (!mounted) return;
      setState(() {
        _smoothedMotion = next;
        _motionLabel = label;
        _motionHint = hint;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPopular;

    return CustomScrollView(
      slivers: [
        _buildHero(context),
        _buildSectionHeader('Motion mix'),
        _buildMotionMix(context),
        _buildSectionHeader('Popular right now'),
        _buildHorizontalSongs(),
        _buildSectionHeader('Browse by genre'),
        _buildGenreChips(),
        _buildSectionHeader('Top picks'),
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'No sample tracks for "${_genres[_selectedGenreIndex]}" yet. Try another genre.',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.9),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          )
        else
          _buildVerticalSongs(context, filtered),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        height: 252,
        margin: const EdgeInsets.fromLTRB(16, 52, 16, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surfaceElevated, AppColors.surface],
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -24,
              top: -24,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accent.withOpacity(0.28)),
                    ),
                    child: Text(
                      'DJ4U',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Find your\nnext track.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recommendations by tempo, key, and danceability.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      onTap: widget.onSearchPressed,
                      borderRadius: BorderRadius.circular(22),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search, color: AppColors.background, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              'Search a song',
                              style: TextStyle(
                                color: AppColors.background,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.15,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSongs() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 224,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: SampleData.popularSongs.length,
          itemBuilder: (context, i) {
            final song = SampleData.popularSongs[i];
            return SongCard(
              song: song,
              isCompact: true,
              onTap: () => _openDetail(context, song),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMotionMix(BuildContext context) {
    final picks = _motionBasedSongs.take(3).toList();
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.motion_photos_on, color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  _motionLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _motionHint,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            ...picks.map(
              (song) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: const VisualDensity(vertical: -3),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    song.albumArtUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  song.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${song.artist} • ${song.genre}',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
                trailing: Text(
                  'E ${(song.energy * 100).round()}',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => _openDetail(context, song),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreChips() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _genres.length,
          itemBuilder: (context, i) {
            final selected = i == _selectedGenreIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: selected ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => setState(() => _selectedGenreIndex = i),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _genres[i],
                      style: TextStyle(
                        color: selected ? AppColors.background : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVerticalSongs(BuildContext context, List<Song> songs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final song = songs[i];
            return SongCard(
              song: song,
              onTap: () => _openDetail(context, song),
            );
          },
          childCount: songs.length,
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SongDetail(song: song)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Search',
                isSelected: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accent : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
