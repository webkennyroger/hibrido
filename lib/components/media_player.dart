import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:hibrido/core/theme/custom_colors.dart';

class MediaPlayer extends StatelessWidget {
  final String trackName;
  final String artistName;
  final bool isLoading;
  final VoidCallback onReload;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const MediaPlayer({
    super.key,
    required this.trackName,
    required this.artistName,
    required this.isLoading,
    required this.onReload,
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onReload,
                icon: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CustomColors.tertiary,
                        ),
                      )
                    : const Icon(
                        CupertinoIcons.refresh,
                        size: 28,
                        color: CustomColors.tertiary,
                      ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      trackName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CustomColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      artistName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CustomColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  CupertinoIcons.waveform,
                  size: 32,
                  color: CustomColors.tertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          /*Row( // Barra de progresso pode ser implementada no futuro
            spacing: 8,
            children: [
              Text(
                "1.05",
                style: TextStyle(
                  fontSize: 12, 
                  color: CustomColors.textDark,
                  ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    color: CustomColors.quaternary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 120,
                      height: 8,
                      decoration: BoxDecoration(
                        color: CustomColors.tertiary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                "2.38",
                style: TextStyle(
                  fontSize: 12, 
                  color: CustomColors.tertiary,
                  ),
              ),
            ],
          ),*/
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(
                  CupertinoIcons.backward_fill,
                  size: 40,
                  color: CustomColors.tertiary,
                ),
              ),
              IconButton(
                onPressed: onPlayPause,
                icon: Icon(
                  isPlaying
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  size: 50,
                  color: CustomColors.tertiary,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  CupertinoIcons.forward_fill,
                  size: 40,
                  color: CustomColors.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
