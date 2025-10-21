import 'package:audioplayers/audioplayers.dart' as audio_players;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';

class AudioMessageBubble extends StatefulWidget {
  final String mediaUrl;
  final Duration duration;
  final bool isMyMessage;

  const AudioMessageBubble({
    super.key,
    required this.mediaUrl,
    required this.duration,
    required this.isMyMessage,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final audio_players.AudioPlayer _audioPlayer = audio_players.AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == audio_players.PlayerState.playing);
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _currentPosition = position);
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play(
        audio_players.DeviceFileSource(widget.mediaUrl),
      ); // Correto para arquivos locais
    }
  }

  void _setSpeed(double speed) {
    _audioPlayer.setPlaybackRate(speed);
    setState(() {
      _playbackSpeed = speed;
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final iconColor = widget.isMyMessage
        ? AppColors.dark().background
        : colors.text;

    return SizedBox(
      width: 250,
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: iconColor,
            ),
            onPressed: _playPause,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: _currentPosition.inMilliseconds.toDouble(),
                  max: widget.duration.inMilliseconds.toDouble().clamp(
                    1.0,
                    double.infinity,
                  ),
                  onChanged: (value) {
                    _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                  },
                  activeColor: iconColor,
                  inactiveColor: iconColor.withAlpha((255 * 0.3).round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: GoogleFonts.lexend(
                        color: iconColor.withAlpha((255 * 0.8).round()),
                        fontSize: 12,
                      ),
                    ),
                    PopupMenuButton<double>(
                      onSelected: _setSpeed,
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                        const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                        const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: iconColor.withAlpha((255 * 0.5).round())),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_playbackSpeed}x',
                          style: GoogleFonts.lexend(
                            color: iconColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
