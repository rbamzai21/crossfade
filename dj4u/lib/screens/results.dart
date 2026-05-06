import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/song.dart';
import '../services/spotify_service.dart';
import '../theme/app_colors.dart';
import 'song_detail.dart';

class Results extends StatefulWidget {
  final Song seedSong;

  const Results({super.key, required this.seedSong});

  @override
  State<Results> createState() => _ResultsState();
}

class _ResultsState extends State<Results> {
  List<Song> _recommendations = [];
  bool _loading = true;
  String? _error;
  String _refine = 'All';

  Song get _seed => widget.seedSong;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await SpotifyService.instance.getRecommendations(
        seedTrackId: _seed.id,
        limit: 40,
      );
      if (!mounted) return;
      setState(() {
        _recommendations = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Song> get _filteredRecommendations {
    switch (_refine) {
      case 'All':
        return List<Song>.from(_recommendations);
      case 'Same key':
        return _recommendations.where((s) => s.key == _seed.key).toList();
      case '±5 BPM':
        return _recommendations
            .where((s) => (s.bpm - _seed.bpm).abs() <= 5)
            .toList();
      case 'High energy':
        return _recommendations.where((s) => s.energy >= 0.66).toList();
      case 'Same genre':
        return _recommendations.where(_matchesSeedGenre).toList();
      case '2020s':
        return _recommendations
            .where((s) => s.year >= 2020 && s.year < 2030)
            .toList();
      default:
        return List<Song>.from(_recommendations);
    }
  }

  bool _matchesSeedGenre(Song s) {
    if (_seed.genre == 'Unknown' || _seed.genre.isEmpty) return true;
    final target = s.genre.toLowerCase();
    for (final fragment in _seed.genre.toLowerCase().split(',')) {
      final t = fragment.trim();
      if (t.isNotEmpty && target.contains(t)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          _buildSeedCard(),
          _buildSeedActions(context),
          _buildAttributes(),
          _buildFilters(),
          if (!_loading && _error == null) _buildResultsHeader(),
          if (_loading) _buildLoadingSliver(),
          if (!_loading && _error != null) _buildErrorSliver(),
          if (!_loading && _error == null) _buildResultsList(context),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error ?? 'Error',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadRecommendations,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      pinned: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            Icons.arrow_back,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),
      ),
      title: const Text(
        'Similar songs',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSeedCard() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 64,
                height: 64,
                color: AppColors.surfaceElevated,
                child: Image.network(
                  _seed.albumArtUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.music_note,
                    color: AppColors.textMuted.withOpacity(0.5),
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SEED TRACK',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _seed.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _seed.artist,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedActions(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: _ActionChip(
                icon: Icons.info_outline_rounded,
                label: 'Details',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SongDetail(song: _seed)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionChip(
                icon: Icons.open_in_new_rounded,
                label: 'Spotify',
                onTap: () => _launch(context, _seed.spotifyUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributes() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _AttributeCard(
                icon: Icons.speed_rounded,
                label: 'TEMPO',
                value: '${_seed.bpm.toInt()}',
                unit: 'BPM',
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AttributeCard(
                icon: Icons.music_note_rounded,
                label: 'KEY',
                value: _seed.key,
                color: AppColors.statKey,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AttributeCard(
                icon: Icons.directions_run_rounded,
                label: 'DANCE',
                value: '${(_seed.danceability * 100).toInt()}',
                unit: '%',
                color: AppColors.statDance,
                showBar: true,
                barValue: _seed.danceability,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'REFINE',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _refine == 'All',
                    onTap: () => setState(() => _refine = 'All'),
                  ),
                  _FilterChip(
                    label: 'Same key',
                    selected: _refine == 'Same key',
                    onTap: () => setState(() => _refine = 'Same key'),
                  ),
                  _FilterChip(
                    label: '±5 BPM',
                    selected: _refine == '±5 BPM',
                    onTap: () => setState(() => _refine = '±5 BPM'),
                  ),
                  _FilterChip(
                    label: 'High energy',
                    selected: _refine == 'High energy',
                    onTap: () => setState(() => _refine = 'High energy'),
                  ),
                  _FilterChip(
                    label: 'Same genre',
                    selected: _refine == 'Same genre',
                    onTap: () => setState(() => _refine = 'Same genre'),
                  ),
                  _FilterChip(
                    label: '2020s',
                    selected: _refine == '2020s',
                    onTap: () => setState(() => _refine = '2020s'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${_filteredRecommendations.length} songs',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    final songs = _filteredRecommendations;
    if (songs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Text(
            _recommendations.isEmpty
                ? 'No recommendations returned for this track.'
                : 'No tracks match this refine filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final song = songs[i];
            return _ResultRow(
              song: song,
              index: i,
              onOpenDetails: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SongDetail(song: song)),
              ),
              onOpenSpotify: () => _launch(context, song.spotifyUrl),
            );
          },
          childCount: songs.length,
        ),
      ),
    );
  }

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open link')),
    );
  }
}

class _AttributeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final Color color;
  final bool showBar;
  final double? barValue;

  const _AttributeCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.unit,
    this.showBar = false,
    this.barValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color.withOpacity(0.9), size: 12),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        color: color.withOpacity(0.55),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showBar && barValue != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: barValue,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected ? AppColors.accent.withOpacity(0.14) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.accent : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final Song song;
  final int index;
  final VoidCallback onOpenDetails;
  final VoidCallback onOpenSpotify;

  const _ResultRow({
    required this.song,
    required this.index,
    required this.onOpenDetails,
    required this.onOpenSpotify,
  });

  @override
  Widget build(BuildContext context) {
    final matchPct = 95 - (index * 7);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Text(
                  '$matchPct',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '%',
                  style: TextStyle(
                    color: AppColors.accent.withOpacity(0.55),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: AppColors.border,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 48,
              height: 48,
              color: AppColors.surfaceElevated,
              child: Image.network(
                song.albumArtUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.music_note,
                  color: AppColors.textMuted.withOpacity(0.5),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _MiniStat(
                      label: '${song.bpm.toInt()} BPM',
                      color: AppColors.accent,
                    ),
                    _MiniStat(
                      label: song.key,
                      color: AppColors.statKey,
                    ),
                    _MiniStat(
                      label: '${(song.danceability * 100).toInt()}% dance',
                      color: AppColors.statDance,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  Icons.info_outline,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                onPressed: onOpenDetails,
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  Icons.open_in_new_rounded,
                  color: AppColors.accent.withOpacity(0.9),
                  size: 18,
                ),
                onPressed: onOpenSpotify,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniStat({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withOpacity(0.92),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: AppColors.accent),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
