import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hibrido/widgets/full_screen_media_viewer.dart';

class ImageMessageBubble extends StatelessWidget {
  final String mediaUrl;
  const ImageMessageBubble({super.key, required this.mediaUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => mediaUrl.startsWith('http')
                ? FullScreenMediaViewer(imageUrl: mediaUrl)
                : FullScreenMediaViewer(mediaFile: File(mediaUrl)),
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: mediaUrl.startsWith('http')
            ? Image.network(
                mediaUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              )
            : Image.file(File(mediaUrl), fit: BoxFit.cover),
      ),
    );
  }
}
