# Crossfade
 
A DJ-focused music discovery app built with Flutter. Find your next track by tempo, key, and danceability — the way a DJ actually thinks about music.
 
---
 
## Overview
 
Most music apps recommend songs based on listening history. Crossfade is built for DJs and music producers who need to know if two tracks are *compatible* — in key, tempo, and energy. It surfaces the analytical data you need to make confident track selections, without breaking your flow.
 
## Features
 
- **DJ-Focused Recommendations** — discover similar tracks seeded by BPM, musical key, danceability, and energy
- **Spotify Integration** — real-time track search, audio features, and playlist data pulled live from the Spotify Web API
- **Motion Mix** — uses your phone's accelerometer to detect energy in the room (chill / groove / hype) and reorders recommendations accordingly
- **Song Detail View** — see tempo, key, danceability, energy, genre, and release year for any track at a glance
- **Filters** — narrow results by genre, decade, and energy level
- **In-app Preview** — play a short audio clip directly in the app, or open the track in Spotify
 
## Tech Stack
 
- **Flutter** — cross-platform mobile framework
- **Spotify Web API** — track metadata, audio features, playlists, and recommendations
- **sensor_plus** — accelerometer access for Motion Mix
- **flutter_dotenv** — secure credential loading from `.env`
- **url_launcher** — deep-link into Spotify
## Getting Started
 
### Prerequisites
 
- Flutter SDK
- A [Spotify Developer](https://developer.spotify.com/dashboard) account and app credentials
### Setup
 
1. Clone the repo
```bash
   git clone https://github.com/rbamzai21/crossfade.git
   cd crossfade
```
 
2. Install dependencies
```bash
   flutter pub get
```
 
3. Create a `.env` file in the project root
```
   SPOTIFY_CLIENT_ID=your_client_id_here
   SPOTIFY_CLIENT_SECRET=your_client_secret_here
```
 
4. Run the app
```bash
   flutter run
```
 
> **Note:** Spotify API credentials are loaded from `.env` and are never hardcoded. Never commit your `.env` file.
 
## How It Works
 
### Motion Mix
The accelerometer reads motion magnitude continuously, smooths it over time, and maps it to one of three energy modes: **Chill**, **Groove**, or **Hype**. A cooldown period between tier changes keeps the UI stable. The home screen's top picks reorder themselves by danceability and energy to match the detected mode.
 
### Recommendations
Selecting a track opens a Results screen seeded with that song. A row of filter chips lets you narrow by Same Key, ±5 BPM, High Energy, Same Genre, or 2020s. Audio feature data (tempo, key, danceability, energy) is pulled from Spotify's audio features API and displayed on each song's detail view.
 
## Roadmap
 
- [ ] User login via Spotify OAuth (Authorization Code flow)
- [ ] History tab — revisit previously searched tracks
- [ ] Saved playlists — build and store sets in-app (Firebase + Firestore)
- [ ] Live BPM detection via device microphone
## Authors
 
Rishab Bamzai & Maanas Gopi

