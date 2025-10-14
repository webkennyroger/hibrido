import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Widget para exibir a mídia (imagem ou vídeo) em tela cheia.
class FullScreenMediaViewer extends StatefulWidget {
  final File? mediaFile;
  final String? imageUrl;

  const FullScreenMediaViewer({super.key, this.mediaFile, this.imageUrl})
    : assert(
        mediaFile != null || imageUrl != null,
        'É necessário fornecer mediaFile ou imageUrl',
      );

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _isVideo =
        widget.mediaFile != null &&
        [
          '.mp4',
          '.mov',
          '.avi',
        ].any((ext) => widget.mediaFile!.path.toLowerCase().endsWith(ext));

    if (_isVideo) {
      _videoController = VideoPlayerController.file(widget.mediaFile!)
        ..initialize().then((_) {
          // Garante que o primeiro frame seja exibido e inicia o vídeo.
          setState(() {});
          _videoController?.play();
          _videoController?.setLooping(true);
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: _isVideo
            ? _buildVideoPlayer()
            : InteractiveViewer(
                child: widget.mediaFile != null
                    ? Image.file(widget.mediaFile!)
                    : Image.network(widget.imageUrl!),
              ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _videoController!.value.isPlaying
                ? _videoController!.pause()
                : _videoController!.play();
          });
        },
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              if (!_videoController!.value.isPlaying)
                const Icon(Icons.play_arrow, color: Colors.white70, size: 80),
            ],
          ),
        ),
      );
    } else {
      return const CircularProgressIndicator();
    }
  }
}
