import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/spotify_service.dart';
import '../theme/app_colors.dart';
import '../utils/genre_filters.dart';
import '../widgets/song_card.dart';
import 'results.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final _controller = TextEditingController();

  bool _hasSearched = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<Song> _rawResults = [];

  static const _genreOptions = [
    'Any Genre',
    'Pop',
    'Hip-Hop',
    'Electronic',
    'Afrobeats',
    'R&B',
    'Latin',
    'Rock',
  ];

  static const _decadeOptions = [
    'Any Decade',
    '2020s',
    '2010s',
    '2000s',
    '1990s',
    '1980s',
  ];

  static const _energyOptions = [
    'Any Energy',
    'High',
    'Medium',
    'Low',
  ];

  String _genreSelection = _genreOptions.first;
  String _decadeSelection = _decadeOptions.first;
  String _energySelection = _energyOptions.first;

  List<Song> get _visibleResults => _applyFilters(_rawResults);

  List<Song> _applyFilters(List<Song> songs) {
    var list = List<Song>.from(songs);

    if (_genreSelection != 'Any Genre') {
      list =
          list.where((s) => songMatchesGenreChip(s, _genreSelection)).toList();
    }

    final decade = _decadeRange(_decadeSelection);
    if (decade != null) {
      list = list
          .where((s) => s.year >= decade.$1 && s.year < decade.$2)
          .toList();
    }

    if (_energySelection != 'Any Energy') {
      list = list.where((s) {
        switch (_energySelection) {
          case 'High':
            return s.energy >= 0.66;
          case 'Medium':
            return s.energy >= 0.33 && s.energy < 0.66;
          case 'Low':
            return s.energy < 0.33;
          default:
            return true;
        }
      }).toList();
    }

    return list;
  }

  (int, int)? _decadeRange(String label) {
    switch (label) {
      case '2020s':
        return (2020, 2030);
      case '2010s':
        return (2010, 2020);
      case '2000s':
        return (2000, 2010);
      case '1990s':
        return (1990, 2000);
      case '1980s':
        return (1980, 1990);
      default:
        return null;
    }
  }

  Future<void> _performSearch() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = false;
      _errorMessage = null;
    });

    try {
      final tracks = await SpotifyService.instance.searchTracks(q, limit: 30);
      if (!mounted) return;
      setState(() {
        _rawResults = tracks;
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _rawResults = [];
        _isLoading = false;
        _hasSearched = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFilters(),
          const _Divider(),
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _hasSearched
                    ? _buildResultsArea(context)
                    : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsArea(BuildContext context) {
    if (_errorMessage != null) {
      return _buildError(_errorMessage!);
    }
    return _buildResults(context);
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEARCH',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Find similar songs',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                onSubmitted: (_) => _performSearch(),
                decoration: InputDecoration(
                  hintText: 'Song title or artist…',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.85),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textMuted.withOpacity(0.9),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _performSearch,
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_forward,
                  color: Color(0xFF0E1114),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FILTERS',
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
                _FilterDropdown(
                  label: 'Genre',
                  options: _genreOptions,
                  value: _genreSelection,
                  onChanged: (v) => setState(() => _genreSelection = v),
                ),
                const SizedBox(width: 8),
                _FilterDropdown(
                  label: 'Decade',
                  options: _decadeOptions,
                  value: _decadeSelection,
                  onChanged: (v) => setState(() => _decadeSelection = v),
                ),
                const SizedBox(width: 8),
                _FilterDropdown(
                  label: 'Energy',
                  options: _energyOptions,
                  value: _energySelection,
                  onChanged: (v) => setState(() => _energySelection = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
              backgroundColor: AppColors.border,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Searching…',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.accent.withOpacity(0.85), size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: _performSearch,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final visible = _visibleResults;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Results for "${_controller.text}"',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withOpacity(0.25)),
                ),
                child: Text(
                  '${visible.length}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Tap a track to open similar songs from Spotify.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    _rawResults.isEmpty
                        ? 'No tracks found.'
                        : 'No tracks match these filters.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final song = visible[i];
                    return SongCard(
                      song: song,
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => Results(seedSong: song),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              Icons.music_note_rounded,
              color: AppColors.textMuted.withOpacity(0.7),
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Search for a song to get started',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Results load from Spotify.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final display = value;
    final isActive = value != options.first;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _showPicker(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppColors.accent.withOpacity(0.45) : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  display,
                  style: TextStyle(
                    color: isActive ? AppColors.accent : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: isActive ? AppColors.accent : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.55;
        return SafeArea(
          child: SizedBox(
            height: maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final opt = options[index];
                      final chosen = value == opt;
                      return ListTile(
                        dense: true,
                        title: Text(
                          opt,
                          style: TextStyle(
                            color: chosen ? AppColors.accent : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: chosen ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        trailing: chosen
                            ? const Icon(Icons.check, color: AppColors.accent, size: 18)
                            : null,
                        onTap: () {
                          onChanged(opt);
                          Navigator.pop(sheetContext);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: AppColors.border,
    );
  }
}
