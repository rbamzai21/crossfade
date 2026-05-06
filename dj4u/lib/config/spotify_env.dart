import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Spotify Web API credentials loaded from `.env` at startup.
abstract final class SpotifyEnv {
  static String get clientId => dotenv.env['SPOTIFY_CLIENT_ID']?.trim() ?? '';
  static String get clientSecret =>
      dotenv.env['SPOTIFY_CLIENT_SECRET']?.trim() ?? '';

  static bool get isConfigured =>
      clientId.isNotEmpty && clientSecret.isNotEmpty;
}
