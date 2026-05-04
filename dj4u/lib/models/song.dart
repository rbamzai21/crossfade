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

// Hardcoded sample data
class SampleData {
  static const List<Song> popularSongs = [
    Song(
      id: '1',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      album: 'After Hours',
      albumArtUrl: 'https://i.scdn.co/image/ab67616d0000b273ef017e899c0547766997d874',
      spotifyUrl: 'https://open.spotify.com/track/0VjIjW4GlUZAMYd2vXMi3b',
      previewUrl: null,
      bpm: 171.0,
      key: 'F Minor',
      danceability: 0.51,
      energy: 0.73,
      genre: 'Pop',
      year: 2020,
      durationSeconds: 200,
    ),
    Song(
      id: '2',
      title: 'Levitating',
      artist: 'Dua Lipa',
      album: 'Future Nostalgia',
      albumArtUrl: 'https://i.scdn.co/image/ab67616d0000b27340b93e60c5bba0e8f7f2c936',
      spotifyUrl: 'https://open.spotify.com/track/463CkQjx2Zk1yXoBuierM9',
      previewUrl: null,
      bpm: 103.0,
      key: 'B Minor',
      danceability: 0.70,
      energy: 0.74,
      genre: 'Pop',
      year: 2020,
      durationSeconds: 203,
    ),
    Song(
      id: '3',
      title: 'Essence',
      artist: 'Wizkid ft. Tems',
      album: 'Made in Lagos',
      albumArtUrl: 'https://i.scdn.co/image/ab67616d0000b27337842b718e6e02b2c4af6d7a',
      spotifyUrl: 'https://open.spotify.com/track/5FG7Tl93LdH117jEKYl3Cm',
      previewUrl: null,
      bpm: 109.0,
      key: 'A♭ Major',
      danceability: 0.73,
      energy: 0.54,
      genre: 'Afrobeats',
      year: 2020,
      durationSeconds: 249,
    ),
    Song(
      id: '4',
      title: 'As It Was',
      artist: 'Harry Styles',
      album: "Harry's House",
      albumArtUrl: 'https://i.scdn.co/image/ab67616d0000b2732e8ed79e177ff6011076f5f0',
      spotifyUrl: 'https://open.spotify.com/track/4LRPiXqCikLlN15c3yImP7',
      previewUrl: null,
      bpm: 174.0,
      key: 'A Minor',
      danceability: 0.52,
      energy: 0.73,
      genre: 'Pop',
      year: 2022,
      durationSeconds: 167,
    ),
    Song(
      id: '5',
      title: 'Calm Down',
      artist: 'Rema & Selena Gomez',
      album: 'Rave & Roses Ultra',
      albumArtUrl: 'https://i.scdn.co/image/ab67616d0000b273ef46bf37cc6d6bb3e2c27e3e',
      spotifyUrl: 'https://open.spotify.com/track/0WtM2NBVQNNJLh6scP13H8',
      previewUrl: null,
      bpm: 107.0,
      key: 'E Minor',
      danceability: 0.80,
      energy: 0.57,
      genre: 'Afropop',
      year: 2022,
      durationSeconds: 239,
    ),
    Song(
      id: '6',
      title: 'Unholy',
      artist: 'Sam Smith & Kim Petras',
      album: 'Gloria',
      albumArtUrl: 'https://i.scdn.co/image/ab67616d0000b273b47b33d2b3a2cd44e99d9d2b',
      spotifyUrl: 'https://open.spotify.com/track/3nqQXoyQOWXiESFLlDF1hG',
      previewUrl: null,
      bpm: 131.0,
      key: 'G Minor',
      danceability: 0.68,
      energy: 0.66,
      genre: 'Pop',
      year: 2022,
      durationSeconds: 156,
    ),
  ];

  static const List<Song> searchResults = [
    Song(
      id: '7',
      title: 'Starboy',
      artist: 'The Weeknd ft. Daft Punk',
      album: 'Starboy',
      albumArtUrl: 'https://i.scdn.co/image/ab67616d0000b2734718e2b124f79258be7bc452',
      spotifyUrl: 'https://open.spotify.com/track/7MXVkk9YMctZqd1Srtv4MB',
      previewUrl: null,
      bpm: 186.0,
      key: 'E Minor',
      danceability: 0.60,
      energy: 0.58,
      genre: 'Pop',
      year: 2016,
      durationSeconds: 230,
    ),
    Song(
      id: '8',
      title: 'Save Your Tears',
      artist: 'The Weeknd',
      album: 'After Hours',
      albumArtUrl: 'https://i.scdn.co/image/ab67616d0000b273ef017e899c0547766997d874',
      spotifyUrl: 'https://open.spotify.com/track/37BZB0z9T8Xu7U3e65qxFy',
      previewUrl: null,
      bpm: 118.0,
      key: 'A Major',
      danceability: 0.63,
      energy: 0.63,
      genre: 'Pop',
      year: 2021,
      durationSeconds: 215,
    ),
    Song(
      id: '9',
      title: 'Out of Time',
      artist: 'The Weeknd',
      album: 'Dawn FM',
      albumArtUrl: 'https://i.scdn.co/image/ab67616d0000b2737fda4a9f0fde83c3b3a9f6a8',
      spotifyUrl: 'https://open.spotify.com/track/2SLwbpExuoBDZBpjfefCtV',
      previewUrl: null,
      bpm: 105.0,
      key: 'F Major',
      danceability: 0.64,
      energy: 0.60,
      genre: 'Pop',
      year: 2022,
      durationSeconds: 214,
    ),
  ];
}