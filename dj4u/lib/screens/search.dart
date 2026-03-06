import 'package:flutter/material.dart';
import '../models/song.dart';
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

  void _performSearch() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = false;
    });
    // Simulate a search delay (will be replaced with Spotify API call)
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
      padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEARCH',
            style: TextStyle(
              color: Color(0xFF00F5C4),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Find Similar Songs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onSubmitted: (_) => _performSearch(),
                decoration: InputDecoration(
                  hintText: 'Song title or artist...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.3),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _performSearch,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF00F5C4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Color(0xFF0A0A0F),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FILTERS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _FilterDropdown(label: 'Genre', options: const [
                'Any Genre', 'Pop', 'Hip-Hop', 'Electronic',
                'Afrobeats', 'R&B', 'Latin', 'Rock',
              ]),
              const SizedBox(width: 8),
              _FilterDropdown(label: 'Decade', options: const [
                'Any Decade', '2020s', '2010s', '2000s', '1990s', '1980s',
              ]),
              const SizedBox(width: 8),
              _FilterDropdown(label: 'Energy', options: const [
                'Any Energy', 'High', 'Medium', 'Low',
              ]),
            ],
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
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              color: const Color(0xFF00F5C4),
              strokeWidth: 2,
              backgroundColor: Colors.white.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Searching...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,
              letterSpacing: 0.3,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              Text(
                'Results for "${_controller.text}"',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5C4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${SampleData.searchResults.length}',
                  style: const TextStyle(
                    color: Color(0xFF00F5C4),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
                  MaterialPageRoute(
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.07),
              ),
            ),
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white.withOpacity(0.2),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for a song to get started',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "We'll find you something that fits perfectly.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 12,
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

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF00F5C4).withOpacity(0.1)
              : const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? const Color(0xFF00F5C4).withOpacity(0.4)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              display,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF00F5C4)
                    : Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: isActive
                  ? const Color(0xFF00F5C4)
                  : Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF13131A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.options.map((opt) => ListTile(
            title: Text(
              opt,
              style: TextStyle(
                color: _selected == opt
                    ? const Color(0xFF00F5C4)
                    : Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: _selected == opt
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
            trailing: _selected == opt
                ? const Icon(Icons.check, color: Color(0xFF00F5C4), size: 18)
                : null,
            onTap: () {
              setState(() => _selected = opt);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: Colors.white.withOpacity(0.07),
    );
  }
}