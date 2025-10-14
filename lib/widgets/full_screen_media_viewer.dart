import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:video_player/video_player.dart';
import 'package:hibrido/core/theme/custom_colors.dart';

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
    // Determina se é um vídeo com base no mediaFile ou no imageUrl
    final path = widget.mediaFile?.path ?? widget.imageUrl;
    if (path != null) {
      _isVideo = [
        '.mp4',
        '.mov',
        '.avi',
      ].any((ext) => path.toLowerCase().endsWith(ext));
    }

    if (_isVideo) {
      // Inicializa o controller correto com base na fonte (arquivo ou rede)
      if (widget.mediaFile != null) {
        _videoController = VideoPlayerController.file(widget.mediaFile!);
      } else if (widget.imageUrl != null) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.imageUrl!),
        );
      }
      _videoController?.initialize().then((_) {
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
        actions: [
          // Mostra o menu de download apenas se for uma imagem
          if (!_isVideo)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppColors.primary),
              onSelected: (value) async {
                if (value == 'download') {
                  try {
                    // Usa o caminho do arquivo local ou a URL da imagem
                    final path = widget.mediaFile?.path ?? widget.imageUrl!;
                    await Gal.putImage(path);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Imagem salva na galeria!'),
                        ),
                      );
                    }
                  } catch (e) {
                    // Tratar erro de permissão ou falha ao salvar
                  }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'download',
                  child: Text('Baixar imagem'),
                ),
              ],
            ),
        ],
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
