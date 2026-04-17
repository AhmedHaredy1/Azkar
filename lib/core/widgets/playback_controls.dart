import 'package:flutter/material.dart';

/// Canonical icon set used across every playback surface.
/// Always import these instead of `Icons.play_*` directly so that the
/// entire app speaks the same visual language.
class PlaybackIcons {
  PlaybackIcons._();
  static const IconData play = Icons.play_arrow_rounded;
  static const IconData pause = Icons.pause_rounded;
  static const IconData skipPrevious = Icons.skip_previous_rounded;
  static const IconData skipNext = Icons.skip_next_rounded;
  static const IconData stop = Icons.stop_rounded;
}

/// Filled circular play/pause button — the primary playback action.
/// One size, one shape, one icon set across the whole app.
class PlaybackPlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;

  const PlaybackPlayButton({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.onPressed,
    required this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isLoading ? null : onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: size * 0.42,
                    height: size * 0.42,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: foregroundColor,
                    ),
                  )
                : Icon(
                    isPlaying ? PlaybackIcons.pause : PlaybackIcons.play,
                    color: foregroundColor,
                    size: size * 0.58,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Ghost icon button used for secondary playback controls
/// (skip-previous, skip-next, stop). Same hit area + icon size everywhere.
class PlaybackIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final String? tooltip;
  final double iconSize;

  const PlaybackIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.tooltip,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      splashRadius: 22,
      icon: Icon(icon, color: color, size: iconSize),
      onPressed: onPressed,
    );
  }
}
