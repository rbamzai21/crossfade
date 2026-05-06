import '../models/song.dart';

/// Matches UI genre chips to Spotify-derived [Song.genre] text (artist genres).
bool songMatchesGenreChip(Song song, String chipLabel) {
  final g = song.genre.toLowerCase();
  switch (chipLabel.toLowerCase()) {
    case 'hip-hop':
      return g.contains('hip') ||
          g.contains('hop') ||
          g.contains('rap') ||
          g.contains('trap');
    case 'r&b':
      return g.contains('r&b') ||
          g.contains('rnb') ||
          g.contains('soul') ||
          g.contains('urban contemporary');
    case 'electronic':
      return g.contains('electronic') ||
          g.contains('edm') ||
          g.contains('house') ||
          g.contains('techno') ||
          g.contains('dance');
    case 'latin':
      return g.contains('latin') ||
          g.contains('reggaeton') ||
          g.contains('salsa') ||
          g.contains('bachata');
    case 'afrobeats':
      return g.contains('afro') || g.contains('afrobeats');
    default:
      return g == chipLabel.toLowerCase() ||
          g.contains(chipLabel.toLowerCase());
  }
}
