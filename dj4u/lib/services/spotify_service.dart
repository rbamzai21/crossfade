import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/spotify_env.dart';
import '../models/song.dart';

/// Curated playlist shown in the Home “Featured” carousel.
class FeaturedPlaylist {
  const FeaturedPlaylist({required this.id, required this.title});

  final String id;
  final String title;
}

/// Thrown when auth fails, credentials are missing, or the API returns an error.
class SpotifyApiException implements Exception {
  SpotifyApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Spotify Web API (client credentials). Fetches tracks, audio features, and artist genres.
class SpotifyService {
  SpotifyService._();
  static final SpotifyService instance = SpotifyService._();

  static const _accountsBase = 'https://accounts.spotify.com';
  static const _apiBase = 'https://api.spotify.com/v1';

  /// Three featured sets (playlist IDs from Spotify share links).
  static const List<FeaturedPlaylist> featuredPlaylists = [
    FeaturedPlaylist(
      id: '75nSj7KWESotz27qYZfmTW',
      title: 'Desert Rave',
    ),
    FeaturedPlaylist(
      id: '3Cy5oNFQhg86s987Dw3LfA',
      title: 'Zak & Mack Trance',
    ),
    FeaturedPlaylist(
      id: '2l3XKRkKBTLWZ4ITPpwB7D',
      title: '2000s Hits',
    ),
  ];

  /// Keys match Home genre chips (excluding `All`). Values are public playlist IDs.
  static const Map<String, FeaturedPlaylist> browseGenrePlaylists = {
    'Pop': FeaturedPlaylist(
      id: '1WH6WVBwPBz35ZbWsgCpgr',
      title: 'Pop',
    ),
    'Hip-Hop': FeaturedPlaylist(
      id: '62y3BHKehWnb1hlaPclDAA',
      title: 'Hip-hop',
    ),
    'Electronic': FeaturedPlaylist(
      id: '5PCv6afEatU3z9cq2fBPDs',
      title: 'Electronic',
    ),
    'Afrobeats': FeaturedPlaylist(
      id: '25Y75ozl2aI0NylFToefO5',
      title: 'Afrobeats',
    ),
    'R&B': FeaturedPlaylist(
      id: '2T3BSpqN34Z4sppHDNWoeE',
      title: 'R&B',
    ),
    'Latin': FeaturedPlaylist(
      id: '2UBikaEIZWV9LOAjE0dBgx',
      title: 'Latin',
    ),
  };

  static const Map<String, List<String>> motionVibeGenres = {
    'chill': ['Afrobeats', 'R&B'],
    'groove': ['Latin', 'Pop'],
    'hype': ['Electronic', 'Hip-Hop'],
  };

  String? _accessToken;
  DateTime? _tokenExpiry;

  void _ensureConfigured() {
    if (!SpotifyEnv.isConfigured) {
      throw SpotifyApiException(
        'Spotify is not configured. Add SPOTIFY_CLIENT_ID and '
        'SPOTIFY_CLIENT_SECRET to .env.',
      );
    }
  }

  Future<String> _getAccessToken() async {
    _ensureConfigured();
    final now = DateTime.now();
    if (_accessToken != null &&
        _tokenExpiry != null &&
        now.isBefore(_tokenExpiry!.subtract(const Duration(seconds: 30)))) {
      return _accessToken!;
    }

    final credentials = base64Encode(
      utf8.encode('${SpotifyEnv.clientId}:${SpotifyEnv.clientSecret}'),
    );

    final response = await http.post(
      Uri.parse('$_accountsBase/api/token'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (response.statusCode != 200) {
      throw SpotifyApiException(
        'Spotify auth failed (${response.statusCode}). ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = data['access_token'] as String;
    final expiresIn = data['expires_in'] as int? ?? 3600;
    _tokenExpiry = now.add(Duration(seconds: expiresIn));
    return _accessToken!;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Uri _apiUri(String path, [Map<String, String>? query]) {
    final p = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$_apiBase/$p').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = _apiUri(path, query);
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode != 200) {
      throw SpotifyApiException(
        'Spotify API ${response.statusCode} for $uri — ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Same as [_getJson] but returns `null` on failure (used for optional enrichment).
  Future<Map<String, dynamic>?> _getJsonOrNull(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = _apiUri(path, query);
    try {
      final response = await http.get(uri, headers: await _authHeaders());
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Tracks from a public playlist (audio features + artist genres when allowed).
  Future<List<Song>> fetchPlaylistTracks(
    String playlistId, {
    int limit = 50,
  }) async {
    final data = await _getJson(
      'playlists/$playlistId/tracks',
      query: {
        'limit': limit.clamp(1, 100).toString(),
        'market': 'US',
      },
    );

    final items = data['items'] as List<dynamic>? ?? [];
    final tracks = <Map<String, dynamic>>[];
    for (final item in items) {
      final map = item as Map<String, dynamic>;
      final track = map['track'];
      if (track is! Map<String, dynamic>) continue;
      if (track['id'] == null) continue;
      tracks.add(track);
    }
    return _enrichTracks(tracks);
  }

  /// Search tracks by text query.
  Future<List<Song>> searchTracks(String query, {int limit = 25}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final data = await _getJson(
      'search',
      query: {
        'q': trimmed,
        'type': 'track',
        'limit': limit.clamp(1, 50).toString(),
        'market': 'US',
      },
    );

    final tracksObj = data['tracks'] as Map<String, dynamic>?;
    final items = tracksObj?['items'] as List<dynamic>? ?? [];
    final tracks = items
        .whereType<Map<String, dynamic>>()
        .where((t) => t['id'] != null)
        .toList();

    return _enrichTracks(tracks);
  }

  /// Recommendation seeds by track id (excludes the seed from the returned list).
  Future<List<Song>> getRecommendations({
    required String seedTrackId,
    int limit = 30,
  }) async {
    final data = await _getJson(
      'recommendations',
      query: {
        'seed_tracks': seedTrackId,
        'limit': limit.clamp(1, 100).toString(),
        'market': 'US',
      },
    );

    final raw = (data['tracks'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .where((t) => t['id'] != null)
        .toList();

    var songs = await _enrichTracks(raw);
    songs = songs.where((s) => s.id != seedTrackId).toList();
    return songs;
  }

  Future<List<Song>> _enrichTracks(List<Map<String, dynamic>> tracks) async {
    if (tracks.isEmpty) return [];

    final ids = tracks.map((t) => t['id'] as String).toList();
    final featuresMap = await _fetchAudioFeatures(ids);

    final artistIds = <String>{};
    for (final t in tracks) {
      final artists = t['artists'] as List<dynamic>? ?? [];
      for (final a in artists) {
        if (a is Map<String, dynamic> && a['id'] != null) {
          artistIds.add(a['id'] as String);
        }
      }
    }
    final artistsMap = await _fetchArtists(artistIds.toList());

    return tracks
        .map(
          (t) => _buildSong(
            track: t,
            features: featuresMap[t['id'] as String],
            artistsById: artistsMap,
          ),
        )
        .toList();
  }

  /// Loads audio features in small GET batches to stay under URL length limits.
  /// If Spotify returns 403 or any error for a batch, that batch is skipped and
  /// tracks fall back to defaults in [_buildSong] (no audio-features required).
  Future<Map<String, Map<String, dynamic>>> _fetchAudioFeatures(
    List<String> ids,
  ) async {
    final out = <String, Map<String, dynamic>>{};
    if (ids.isEmpty) return out;
    // Spotify allows up to 100 ids; use 20 so query URLs stay well under ~2k chars.
    const chunk = 20;
    for (var i = 0; i < ids.length; i += chunk) {
      final end = i + chunk > ids.length ? ids.length : i + chunk;
      final slice = ids.sublist(i, end);
      final data = await _getJsonOrNull(
        'audio-features',
        query: {'ids': slice.join(',')},
      );
      if (data == null) continue;
      final list = data['audio_features'] as List<dynamic>? ?? [];
      for (final feature in list) {
        if (feature is Map<String, dynamic> && feature['id'] != null) {
          out[feature['id'] as String] = feature;
        }
      }
    }
    return out;
  }

  /// Loads artists in batches; failed batches are skipped (genres show as Unknown).
  Future<Map<String, Map<String, dynamic>>> _fetchArtists(List<String> ids) async {
    final out = <String, Map<String, dynamic>>{};
    if (ids.isEmpty) return out;
    const chunk = 50;
    for (var i = 0; i < ids.length; i += chunk) {
      final end = i + chunk > ids.length ? ids.length : i + chunk;
      final slice = ids.sublist(i, end);
      final data = await _getJsonOrNull(
        'artists',
        query: {'ids': slice.join(',')},
      );
      if (data == null) continue;
      final list = data['artists'] as List<dynamic>? ?? [];
      for (final artist in list) {
        if (artist is Map<String, dynamic> && artist['id'] != null) {
          out[artist['id'] as String] = artist;
        }
      }
    }
    return out;
  }

  Song _buildSong({
    required Map<String, dynamic> track,
    Map<String, dynamic>? features,
    required Map<String, Map<String, dynamic>> artistsById,
  }) {
    final album = track['album'] as Map<String, dynamic>? ?? {};
    final images = album['images'] as List<dynamic>? ?? [];
    var artUrl = '';
    if (images.isNotEmpty && images.first is Map) {
      artUrl = (images.first as Map)['url'] as String? ?? '';
    }
    if (artUrl.isEmpty) {
      artUrl =
          'https://via.placeholder.com/300x300/1a1d21/b39ddb?text=%E2%99%AA';
    }

    final artistList = track['artists'] as List<dynamic>? ?? [];
    final names = <String>[];
    final genreParts = <String>{};
    for (final a in artistList) {
      if (a is! Map<String, dynamic>) continue;
      final name = a['name'] as String?;
      if (name != null) names.add(name);
      final aid = a['id'] as String?;
      if (aid != null && artistsById.containsKey(aid)) {
        final g = artistsById[aid]!['genres'] as List<dynamic>? ?? [];
        for (final x in g) {
          if (x is String && x.isNotEmpty) {
            genreParts.add(_titleGenreWords(x));
          }
        }
      }
    }

    final genreStr =
        genreParts.isEmpty ? 'Unknown' : genreParts.take(4).join(', ');

    final ext = track['external_urls'] as Map<String, dynamic>?;
    final spotifyUrl = ext?['spotify'] as String? ?? 'https://open.spotify.com';

    final tempo = (features?['tempo'] as num?)?.toDouble();
    final dance = (features?['danceability'] as num?)?.toDouble();
    final energy = (features?['energy'] as num?)?.toDouble();
    final keyVal = features?['key'];
    final modeVal = features?['mode'];
    final keyLabel = (keyVal is int && modeVal is int)
        ? _pitchClassKey(keyVal, modeVal)
        : '—';

    final release = album['release_date'] as String?;
    final year = _parseYear(release);

    final durMs = (track['duration_ms'] as num?)?.toInt() ?? 0;

    return Song(
      id: track['id'] as String,
      title: track['name'] as String? ?? 'Unknown',
      artist: names.isEmpty ? 'Unknown' : names.join(', '),
      album: album['name'] as String? ?? '',
      albumArtUrl: artUrl,
      spotifyUrl: spotifyUrl,
      previewUrl: track['preview_url'] as String?,
      bpm: (tempo != null && tempo > 0) ? tempo : 120.0,
      key: keyLabel,
      danceability: (dance ?? 0.5).clamp(0.0, 1.0),
      energy: (energy ?? 0.5).clamp(0.0, 1.0),
      genre: genreStr,
      year: year,
      durationSeconds: (durMs / 1000).round(),
    );
  }

  static String _titleGenreWords(String raw) {
    return raw
        .split(' ')
        .map(
          (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
        )
        .join(' ');
  }

  static int _parseYear(String? releaseDate) {
    if (releaseDate == null || releaseDate.length < 4) return 2000;
    return int.tryParse(releaseDate.substring(0, 4)) ?? 2000;
  }

  static const _pitchNames = [
    'C',
    'C♯',
    'D',
    'D♯',
    'E',
    'F',
    'F♯',
    'G',
    'G♯',
    'A',
    'A♯',
    'B',
  ];

  static String _pitchClassKey(int key, int mode) {
    if (key < 0 || key > 11) return '—';
    final name = _pitchNames[key];
    final modeLabel = mode == 1 ? 'Major' : 'Minor';
    return '$name $modeLabel';
  }
}
