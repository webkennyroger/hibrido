import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:video_player/video_player.dart';

class VideoMessageBubble extends StatefulWidget {
  final String mediaUrl;
  const VideoMessageBubble({super.key, required this.mediaUrl});

  @override
  State<VideoMessageBubble> createState() => _VideoMessageBubbleState();
}

class _VideoMessageBubbleState extends State<VideoMessageBubble> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.mediaUrl.startsWith('http')) {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.mediaUrl),
      );
    } else {
      _videoPlayerController = VideoPlayerController.file(
        File(widget.mediaUrl),
      );
    }
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await _videoPlayerController.initialize();
    setState(() {
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        placeholder: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
        additionalOptions: (context) {
          return <OptionItem>[
            OptionItem(
              onTap: (context) async {
                Navigator.pop(context);
                try {
                  await Gal.putVideo(widget.mediaUrl);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vídeo salvo na galeria!')),
                    );
                  }
                } catch (e) {
                  // Tratar erro de permissão ou falha ao salvar
                }
              },
              iconData: Icons.download,
              title: 'Baixar',
            ),
          ];
        },
        optionsTranslation: OptionsTranslation(
          playbackSpeedButtonText: 'Velocidade',
        ),
      );
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _chewieController != null &&
            _chewieController!.videoPlayerController.value.isInitialized
        ? AspectRatio(
            aspectRatio:
                _chewieController!.videoPlayerController.value.aspectRatio,
            child: Theme(
              data: Theme.of(context).copyWith(
                iconTheme: const IconThemeData(color: Colors.blue), //TODO: use theme color
              ),
              child: Chewie(controller: _chewieController!),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
