import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_colors.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final bool isCompact;

  const SongCard({
    super.key,
    required this.song,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) return _buildCompact(context);
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    const double artSize = 150;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final bounded = maxH.isFinite && maxH < 900;

        const borderSide = 1.0;
        final decoration = BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: borderSide),
        );

        Widget meta = Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                song.artist,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _StatChip(label: '${song.bpm.toInt()}', unit: 'BPM'),
                  const SizedBox(width: 4),
                  Flexible(child: _StatChip(label: song.key)),
                ],
              ),
            ],
          ),
        );

        final image = ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
          child: _AlbumArt(url: song.albumArtUrl, size: artSize),
        );

        // Horizontal ListView gives a tight height; fill it and scale metadata if needed.
        if (bounded) {
          // BoxDecoration border lays out inside the box; vertical border steals 2px from the child.
          final innerH = math.max(0.0, maxH - 2 * borderSide);
          final bottomH = math.max(0.0, innerH - artSize);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 150,
                height: maxH,
                margin: const EdgeInsets.only(right: 10),
                decoration: decoration,
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: innerH,
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: artSize,
                        width: artSize,
                        child: image,
                      ),
                      SizedBox(
                        height: bottomH,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: 150,
                            child: meta,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 10),
              decoration: decoration,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  image,
                  meta,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFull(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _AlbumArt(url: song.albumArtUrl, size: 56),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      song.artist,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${song.genre} • ${song.year}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatChip(label: '${song.bpm.toInt()}', unit: 'BPM'),
                        _StatChip(label: song.key),
                        _DanceabilityBar(value: song.danceability),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textMuted.withOpacity(0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  final String url;
  final double size;

  const _AlbumArt({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surfaceElevated,
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surfaceElevated,
          child: Icon(
            Icons.music_note,
            color: AppColors.textMuted.withOpacity(0.5),
            size: size * 0.35,
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String? unit;

  const _StatChip({required this.label, this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.accent.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: 2),
            Text(
              unit!,
              style: TextStyle(
                color: AppColors.accent.withOpacity(0.65),
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DanceabilityBar extends StatelessWidget {
  final double value;

  const _DanceabilityBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'DANCE',
          style: TextStyle(
            color: AppColors.textMuted.withOpacity(0.95),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 36,
          height: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.statDance),
            ),
          ),
        ),
      ],
    );
  }
}
