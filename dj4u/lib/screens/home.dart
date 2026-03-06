import 'package:flutter/material.dart';
import '../models/song.dart';
import '../widgets/song_card.dart';
import 'search.dart';
import 'results.dart';

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
      backgroundColor: const Color(0xFF050545),
      body: IndexedStack(
        index: _selectedTab,
        children: const [
          _LandingTab(),
          Search(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
      ),
    );
  }
}

class _LandingTab extends StatelessWidget {
  const _LandingTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildHero(context),
        _buildSectionHeader('🔥 Popular Right Now'),
        _buildHorizontalSongs(),
        _buildSectionHeader('📈 Trending by Genre'),
        _buildGenreChips(),
        _buildSectionHeader('⚡ Top Picks'),
        _buildVerticalSongs(context),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        height: 220,
        margin: const EdgeInsets.fromLTRB(16, 56, 16, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0A2E), Color(0xFF0D1F2D)],
          ),
          border: Border.all(
            color: const Color(0xFF00F5C4).withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Decorative glow
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00F5C4).withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -10,
              bottom: -10,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF2D6B).withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F5C4).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00F5C4).withOpacity(0.4),
                            width: 0.5,
                          ),
                        ),
                        child: const Text(
                          'DJ4U',
                          style: TextStyle(
                            color: Color(0xFF00F5C4),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Find Your\nNext Track.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Song recommendations powered by\ntempo, key & danceability.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () {
                      // Navigate to search
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5C4),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search,
                            color: Color(0xFF0A0A0F),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Search a Song',
                            style: TextStyle(
                              color: Color(0xFF0A0A0F),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
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
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSongs() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: SampleData.popularSongs.length,
          itemBuilder: (context, i) {
            final song = SampleData.popularSongs[i];
            return SongCard(
              song: song,
              isCompact: true,
              onTap: () => _openResults(context, song),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGenreChips() {
    final genres = ['All', 'Pop', 'Hip-Hop', 'Electronic', 'Afrobeats', 'R&B', 'Latin'];
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: genres.length,
          itemBuilder: (context, i) {
            final isSelected = i == 0;
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00F5C4)
                    : const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00F5C4)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                genres[i],
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF0A0A0F)
                      : Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVerticalSongs(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, i) {
            final song = SampleData.popularSongs[i];
            return SongCard(
              song: song,
              onTap: () => _openResults(context, song),
            );
          },
          childCount: SampleData.popularSongs.length,
        ),
      ),
    );
  }

  void _openResults(BuildContext context, Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Results(seedSong: song),
      ),
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
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F17),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.07),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF00F5C4)
                  : Colors.white.withOpacity(0.35),
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF00F5C4)
                    : Colors.white.withOpacity(0.35),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}