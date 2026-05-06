import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math' as math;

import '../models/song.dart';
import '../services/spotify_service.dart';
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

  /// One list of tracks per featured playlist (same order as [SpotifyService.featuredPlaylists]).
  List<List<Song>> _featuredTracksList = List.generate(
    SpotifyService.featuredPlaylists.length,
    (_) => [],
  );
  bool _loadingFeatured = true;
  String? _featuredError;

  late final PageController _featuredPageController;
  int _featuredIndex = 0;

  /// Cached tracks per genre chip label (Pop, Hip-Hop, …). Filled when user selects that genre.
  final Map<String, List<Song>> _genreTracksCache = {};
  String? _genreLoadingLabel;
  final Map<String, String> _genreErrors = {};

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  double _smoothedMotion = 0;

  int _motionTier = 0;

  DateTime? _vibeCooldownEndsAt;

  int _motionPickSeed = math.Random().nextInt(0x7fffffff);

  static const _grooveCooldown = Duration(seconds: 10);

  static const List<String> _motionTierKeys = ['chill', 'groove', 'hype'];

  Duration _randomHypeCooldown() =>
      Duration(seconds: 10 + math.Random().nextInt(6));

  String _motionLabel = 'Chill mode';
  String _motionHint =
      'Low movement — random picks from Afrobeats & R&B playlists.';

  String get _motionTierKey => _motionTierKeys[_motionTier.clamp(0, 2)];

  @override
  void initState() {
    super.initState();
    _featuredPageController = PageController();
    _loadFeatured();
    _startMotionTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureMotionVibeGenresLoaded();
    });
  }

  List<Song> get _pooledTracks {
    final byId = <String, Song>{};
    for (final list in _featuredTracksList) {
      for (final s in list) {
        byId[s.id] = s;
      }
    }
    return byId.values.toList();
  }

  Future<void> _loadFeatured() async {
    setState(() {
      _loadingFeatured = true;
      _featuredError = null;
    });
    final svc = SpotifyService.instance;
    final lists = <List<Song>>[];
    Object? firstError;
    for (final p in SpotifyService.featuredPlaylists) {
      try {
        lists.add(await svc.fetchPlaylistTracks(p.id, limit: 45));
      } catch (e) {
        lists.add([]);
        firstError ??= e;
      }
    }
    if (!mounted) return;
    setState(() {
      _featuredTracksList = lists;
      _loadingFeatured = false;
      _featuredError = lists.every((l) => l.isEmpty)
          ? (firstError?.toString() ?? 'Could not load playlists.')
          : null;
    });
  }

  void _ensureGenreLoaded(String label) {
    if (!SpotifyService.browseGenrePlaylists.containsKey(label)) return;
    final cachedOk =
        _genreTracksCache.containsKey(label) && !_genreErrors.containsKey(label);
    if (cachedOk) return;
    if (_genreLoadingLabel == label) return;
    _loadGenrePlaylist(label);
  }

  Future<void> _loadGenrePlaylist(String label) async {
    final meta = SpotifyService.browseGenrePlaylists[label];
    if (meta == null) return;
    setState(() {
      _genreLoadingLabel = label;
      _genreErrors.remove(label);
    });
    try {
      final tracks =
          await SpotifyService.instance.fetchPlaylistTracks(meta.id, limit: 50);
      if (!mounted) return;
      setState(() {
        _genreTracksCache[label] = tracks;
        _genreLoadingLabel = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _genreLoadingLabel = null;
        _genreErrors[label] = e.toString();
      });
    }
  }

  void _goFeaturedPage(int index) {
    if (index == _featuredIndex) return;
    _featuredPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _featuredPageController.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  static const double _hypeMotionThreshold = 2.5;
  static const double _grooveMotionThreshold = 1.38;

  static int _tierFromMotion(double m) {
    if (m > _hypeMotionThreshold) return 2;
    if (m > _grooveMotionThreshold) return 1;
    return 0;
  }

  void _setMotionCopyForTier() {
    switch (_motionTier) {
      case 2:
        _motionLabel = 'Hype mode';
        _motionHint =
            'High energy — random picks from Electronic & Hip-Hop playlists.';
        break;
      case 1:
        _motionLabel = 'Groove mode';
        _motionHint =
            'Steady movement — random picks from Latin & Pop playlists.';
        break;
      default:
        _motionLabel = 'Chill mode';
        _motionHint =
            'Low movement — random picks from Afrobeats & R&B playlists.';
    }
  }

  void _ensureMotionVibeGenresLoaded() {
    final labels = SpotifyService.motionVibeGenres[_motionTierKey];
    if (labels == null) return;
    for (final label in labels) {
      _ensureGenreLoaded(label);
    }
  }

  bool get _motionVibeGenresStillLoading {
    final labels = SpotifyService.motionVibeGenres[_motionTierKey];
    if (labels == null) return false;
    for (final label in labels) {
      if (_genreErrors.containsKey(label)) continue;
      if (!_genreTracksCache.containsKey(label)) return true;
    }
    return false;
  }

  List<Song> get _motionVibePicks {
    final labels = SpotifyService.motionVibeGenres[_motionTierKey];
    if (labels != null) {
      final byId = <String, Song>{};
      for (final label in labels) {
        final tracks = _genreTracksCache[label];
        if (tracks == null) continue;
        for (final s in tracks) {
          byId[s.id] = s;
        }
      }
      final pool = byId.values.toList();
      if (pool.isNotEmpty) {
        final rnd = math.Random(_motionPickSeed);
        final copy = [...pool]..shuffle(rnd);
        return copy.take(3).toList();
      }
    }

    final featured = _pooledTracks;
    if (featured.isEmpty) return [];
    List<Song> ordered;
    switch (_motionTier) {
      case 2:
        ordered = [...featured]..sort((a, b) => b.energy.compareTo(a.energy));
        break;
      case 1:
        ordered = [...featured]
          ..sort((a, b) => b.danceability.compareTo(a.danceability));
        break;
      default:
        ordered = [...featured]..sort((a, b) => a.energy.compareTo(b.energy));
    }
    final slice = ordered.take(24).toList()..shuffle(math.Random(_motionPickSeed));
    return slice.take(3).toList();
  }

  void _startMotionTracking() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final magnitude = math.sqrt(
        (event.x * event.x) + (event.y * event.y) + (event.z * event.z),
      );
      final dynamicMotion = (magnitude - 9.81).abs();
      const riseAlpha = 0.58;
      const fallAlpha = 0.22;
      final alpha =
          dynamicMotion > _smoothedMotion ? riseAlpha : fallAlpha;
      final nextMotion =
          _smoothedMotion * (1 - alpha) + dynamicMotion * alpha;
      final instantTier = _tierFromMotion(nextMotion);

      if (!mounted) return;

      final now = DateTime.now();
      final cooldownActive =
          _vibeCooldownEndsAt != null && now.isBefore(_vibeCooldownEndsAt!);

      if (cooldownActive) {
        if (instantTier == 2 && _motionTier < 2) {
          final beforeTier = _motionTier;
          setState(() {
            _smoothedMotion = nextMotion;
            _motionTier = 2;
            _vibeCooldownEndsAt = now.add(_randomHypeCooldown());
            if (beforeTier != 2) {
              _motionPickSeed = math.Random().nextInt(0x7fffffff);
            }
            _setMotionCopyForTier();
          });
          if (beforeTier != 2) _ensureMotionVibeGenresLoaded();
        } else {
          setState(() => _smoothedMotion = nextMotion);
        }
        return;
      }

      final beforeTier = _motionTier;
      setState(() {
        _smoothedMotion = nextMotion;
        if (instantTier == 2) {
          final tierJump = _motionTier != 2;
          _motionTier = 2;
          _vibeCooldownEndsAt = now.add(_randomHypeCooldown());
          if (tierJump) {
            _motionPickSeed = math.Random().nextInt(0x7fffffff);
          }
          _setMotionCopyForTier();
        } else if (instantTier == 1) {
          final tierJump = _motionTier != 1;
          _motionTier = 1;
          _vibeCooldownEndsAt = now.add(_grooveCooldown);
          if (tierJump) {
            _motionPickSeed = math.Random().nextInt(0x7fffffff);
          }
          _setMotionCopyForTier();
        } else {
          _motionTier = 0;
          _vibeCooldownEndsAt = null;
          if (beforeTier != 0) {
            _motionPickSeed = math.Random().nextInt(0x7fffffff);
          }
          _setMotionCopyForTier();
        }
      });
      if (_motionTier != beforeTier) _ensureMotionVibeGenresLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildHero(context),
        _buildSectionHeader('Motion mix'),
        _buildMotionMix(context),
        _buildSectionHeader('Featured'),
        if (_featuredError != null) _buildFeaturedError(),
        if (_loadingFeatured) _buildFeaturedLoading(),
        if (!_loadingFeatured && _featuredError == null) _buildFeaturedSection(context),
        _buildSectionHeader('Browse by genre'),
        _buildGenreChips(),
        _buildSectionHeader('Top picks'),
        ..._topPicksSlivers(context),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  List<Widget> _topPicksSlivers(BuildContext context) {
    final label = _genres[_selectedGenreIndex];

    if (label == 'All') {
      if (_loadingFeatured) {
        return [_topPicksLoading()];
      }
      final tracks = _pooledTracks;
      if (tracks.isEmpty) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _featuredError != null
                    ? 'Featured playlists did not load — fix connection or retry above.'
                    : 'No tracks in featured playlists yet.',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.9),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ];
      }
      return [_buildVerticalSongs(context, tracks)];
    }

    if (_genreLoadingLabel == label) {
      return [_topPicksLoading()];
    }

    final genreErr = _genreErrors[label];
    if (genreErr != null) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not load the $label playlist.',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.95),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  genreErr,
                  style: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.9),
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _loadGenrePlaylist(label),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (!_genreTracksCache.containsKey(label)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _genres[_selectedGenreIndex] != label) return;
        _ensureGenreLoaded(label);
      });
      return [_topPicksLoading()];
    }

    final genreTracks = _genreTracksCache[label]!;
    if (genreTracks.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'No tracks in this playlist.',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ];
    }
    return [_buildVerticalSongs(context, genreTracks)];
  }

  Widget _topPicksLoading() {
    return const SliverToBoxAdapter(
      child: SizedBox(
        height: 88,
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
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

  Widget _buildFeaturedLoading() {
    return const SliverToBoxAdapter(
      child: SizedBox(
        height: 120,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedError() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Could not load featured playlists.',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.95),
                fontSize: 12,
              ),
            ),
            if (_featuredError != null) ...[
              const SizedBox(height: 6),
              Text(
                _featuredError!,
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.9),
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadFeatured,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(BuildContext context) {
    final playlists = SpotifyService.featuredPlaylists;
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Swipe or tap a set to browse tracks from that playlist.',
              style: TextStyle(
                color: AppColors.textMuted.withOpacity(0.95),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: playlists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = i == _featuredIndex;
                return Material(
                  color: selected ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () => _goFeaturedPage(i),
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
                        playlists[i].title,
                        style: TextStyle(
                          color: selected ? AppColors.background : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 224,
            child: PageView.builder(
              controller: _featuredPageController,
              onPageChanged: (i) => setState(() => _featuredIndex = i),
              itemCount: playlists.length,
              itemBuilder: (context, pageIndex) {
                final songs = _featuredTracksList[pageIndex];
                if (songs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'No tracks in “${playlists[pageIndex].title}”.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: songs.length,
                  itemBuilder: (context, i) {
                    final song = songs[i];
                    return SongCard(
                      song: song,
                      isCompact: true,
                      onTap: () => _openDetail(context, song),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              playlists.length,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _featuredIndex == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _featuredIndex == i ? AppColors.accent : AppColors.border,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMotionMix(BuildContext context) {
    final picks = _motionVibePicks;
    final waitingForGenres =
        picks.isEmpty && _motionVibeGenresStillLoading && !_loadingFeatured;
    if (picks.isEmpty && !_loadingFeatured && !waitingForGenres) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    if (picks.isEmpty && (_loadingFeatured || waitingForGenres)) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
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
                  Expanded(
                    child: Text(
                      _motionLabel,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                waitingForGenres
                    ? 'Loading playlist picks for this vibe…'
                    : 'Loading tracks…',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }
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
                  onTap: () {
                    final lbl = _genres[i];
                    setState(() => _selectedGenreIndex = i);
                    if (lbl != 'All') {
                      _ensureGenreLoaded(lbl);
                    }
                  },
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
