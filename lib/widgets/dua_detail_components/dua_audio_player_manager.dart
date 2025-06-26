import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/dua_model.dart';

class DuaAudioPlayerManager extends StatefulWidget {
  final Dua currentDua;
  final Widget Function(
    PlayerState playerState,
    Duration duration,
    Duration position,
    VoidCallback onPlayPausePressed,
    ValueChanged<double> onSliderChanged,
    bool isLooping, // New
    VoidCallback onToggleLoop, // New
    double playbackSpeed, // New
    ValueChanged<double> onSpeedChanged, // New
  ) builder;

  const DuaAudioPlayerManager({
    super.key,
    required this.currentDua,
    required this.builder,
  });

  @override
  State<DuaAudioPlayerManager> createState() => _DuaAudioPlayerManagerState();
}

class _DuaAudioPlayerManagerState extends State<DuaAudioPlayerManager> {
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLooping = false; // New: for looping
  double _playbackSpeed = 1.0; // New: for playback speed

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudioPlayer();
    _loadAudioForCurrentDua();
  }

  @override
  void didUpdateWidget(covariant DuaAudioPlayerManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentDua.id != oldWidget.currentDua.id) {
      _loadAudioForCurrentDua();
    }
  }

  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        _duration = newDuration;
      });
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        _position = newPosition;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (_isLooping) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.resume();
      } else {
        setState(() {
          _playerState = PlayerState.stopped;
          _position = Duration.zero;
        });
      }
    });
  }

  void _loadAudioForCurrentDua() async {
    final String audioPath = 'assets/audio/dua_${widget.currentDua.manzilNumber}_${widget.currentDua.day.toLowerCase().replaceAll(' ', '')}.mp3';

    try {
      await _audioPlayer.stop(); // Stop any currently playing audio
      await _audioPlayer.setSourceAsset(audioPath);
      await _audioPlayer.setPlaybackRate(_playbackSpeed); // Set initial playback speed
      _position = Duration.zero; // Reset position when loading new audio
      _duration = (await _audioPlayer.getDuration()) ?? Duration.zero;
      setState(() {
        _playerState = PlayerState.stopped; // Reset player state
      });
    } catch (e) {
      debugPrint('Error loading audio for ${widget.currentDua.day}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio not available for ${widget.currentDua.day}.')),
        );
      }
      setState(() {
        _playerState = PlayerState.stopped;
        _duration = Duration.zero;
        _position = Duration.zero;
      });
    }
  }

  void _onPlayPausePressed() async {
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  void _onSliderChanged(double value) async {
    final position = Duration(seconds: value.toInt());
    await _audioPlayer.seek(position);
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });
  }

  void _setPlaybackSpeed(double speed) async {
    setState(() {
      _playbackSpeed = speed;
    });
    await _audioPlayer.setPlaybackRate(speed);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      _playerState,
      _duration,
      _position,
      _onPlayPausePressed,
      _onSliderChanged,
      _isLooping, // Pass new parameters
      _toggleLoop, // Pass new parameters
      _playbackSpeed, // Pass new parameters
      _setPlaybackSpeed, // Pass new parameters
    );
  }
}
