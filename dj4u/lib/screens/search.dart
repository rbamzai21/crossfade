import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_colors.dart';
import '../widgets/song_card.dart';
import 'song_detail.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final _controller = TextEditingController();
  bool _hasSearched = false;
  bool _isLoading = false;

  void _performSearch() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = false;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasSearched = true;
        });
      }
    });
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
                    ? _buildResults(context)
                    : _buildEmptyState(),
          ),
        ],
      ),
    );
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
                  options: const [
                    'Any Genre',
                    'Pop',
                    'Hip-Hop',
                    'Electronic',
                    'Afrobeats',
                    'R&B',
                    'Latin',
                    'Rock',
                  ],
                ),
                const SizedBox(width: 8),
                _FilterDropdown(
                  label: 'Decade',
                  options: const [
                    'Any Decade',
                    '2020s',
                    '2010s',
                    '2000s',
                    '1990s',
                    '1980s',
                  ],
                ),
                const SizedBox(width: 8),
                _FilterDropdown(
                  label: 'Energy',
                  options: const [
                    'Any Energy',
                    'High',
                    'Medium',
                    'Low',
                  ],
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

  Widget _buildResults(BuildContext context) {
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
                  '${SampleData.searchResults.length}',
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
            'Tap a result for overview and links.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: SampleData.searchResults.length,
            itemBuilder: (context, i) {
              final song = SampleData.searchResults[i];
              return SongCard(
                song: song,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SongDetail(song: song)),
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
            'Spotify results will appear here once connected.',
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

class _FilterDropdown extends StatefulWidget {
  final String label;
  final List<String> options;

  const _FilterDropdown({required this.label, required this.options});

  @override
  State<_FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<_FilterDropdown> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final display = _selected ?? widget.label;
    final isActive = _selected != null && _selected != widget.options.first;

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
                    widget.label,
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
                    itemCount: widget.options.length,
                    itemBuilder: (context, index) {
                      final opt = widget.options[index];
                      final chosen = _selected == opt;
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
                          setState(() => _selected = opt);
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
