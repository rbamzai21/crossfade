class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String albumArtUrl;
  final String spotifyUrl;
  final String? previewUrl;
  final double bpm;
  final String key;
  final double danceability;
  final double energy;
  final String genre;
  final int year;
  final int durationSeconds;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumArtUrl,
    required this.spotifyUrl,
    this.previewUrl,
    required this.bpm,
    required this.key,
    required this.danceability,
    required this.energy,
    required this.genre,
    required this.year,
    required this.durationSeconds,
  });
}
