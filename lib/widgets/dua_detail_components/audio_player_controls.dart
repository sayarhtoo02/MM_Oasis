import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerControls extends StatelessWidget {
  final PlayerState playerState;
  final Duration duration;
  final Duration position;
  final VoidCallback onPlayPausePressed;
  final ValueChanged<double> onSliderChanged;
  final bool isLooping; // New: for looping
  final VoidCallback onToggleLoop; // New: for looping
  final double playbackSpeed; // New: for playback speed
  final ValueChanged<double> onSpeedChanged; // New: for playback speed

  const AudioPlayerControls({
    super.key,
    required this.playerState,
    required this.duration,
    required this.position,
    required this.onPlayPausePressed,
    required this.onSliderChanged,
    required this.isLooping, // Add to constructor
    required this.onToggleLoop, // Add to constructor
    required this.playbackSpeed, // Add to constructor
    required this.onSpeedChanged, // Add to constructor
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround, // Distribute controls
            children: [
              IconButton(
                icon: Icon(
                  isLooping
                      ? Icons.repeat_one_on
                      : Icons.repeat_one, // Loop icon
                  color: isLooping
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                onPressed: onToggleLoop,
              ),
              IconButton(
                icon: Icon(
                  playerState == PlayerState.playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: onPlayPausePressed,
              ),
              DropdownButton<double>(
                value: playbackSpeed,
                icon: Icon(
                  Icons.speed,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                underline: const SizedBox.shrink(),
                onChanged: (double? newValue) {
                  if (newValue != null) {
                    onSpeedChanged(newValue);
                  }
                },
                items: const <double>[0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                    .map<DropdownMenuItem<double>>((double value) {
                      return DropdownMenuItem<double>(
                        value: value,
                        child: Text(
                          '${value}x',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
            ],
          ),
          Slider(
            min: 0,
            max: duration.inSeconds.toDouble(),
            value: position.inSeconds.toDouble(),
            onChanged: onSliderChanged,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.3),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
