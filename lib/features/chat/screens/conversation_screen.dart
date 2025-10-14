import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart' as audio_players;
import 'package:chewie/chewie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/chat/models/chat_argument.dart';
import 'package:hibrido/widgets/full_screen_media_viewer.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:video_player/video_player.dart';

enum MessageType { text, image, video, audio, document }

class ChatMessage {
  final String id;
  final String text;
  final MessageType type;
  final String? mediaUrl;
  final Duration? audioDuration;
  final bool isSentByMe;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    this.mediaUrl,
    this.audioDuration,
    required this.isSentByMe,
    required this.timestamp,
  });
}

class ConversationScreen extends StatefulWidget {
  final ChatArgument chat;
  const ConversationScreen({super.key, required this.chat});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      text: 'Olá, tudo bem?',
      type: MessageType.text,
      isSentByMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ChatMessage(
      id: '2',
      text: 'Tudo ótimo! E com você?',
      type: MessageType.text,
      isSentByMe: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
    ),
    ChatMessage(
      id: '3',
      text: 'Olha essa foto que tirei!',
      type: MessageType.image,
      mediaUrl: 'https://picsum.photos/seed/picsum/400/600',
      isSentByMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    ChatMessage(
      id: '4',
      text: 'Que legal!',
      type: MessageType.text,
      isSentByMe: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  // Audio recording state
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _recordingPath;
  // NOVO: Estado para controlar a visibilidade do menu de anexos
  bool _showAttachmentMenu = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException(
        'Permissão para microfone não concedida',
      );
    }
    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) return;
    final tempDir = await getTemporaryDirectory();
    _recordingPath =
        '${tempDir.path}/flutter_sound_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(toFile: _recordingPath, codec: Codec.aacADTS);
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopAndSendRecording() async {
    if (!_isRecorderInitialized) return;

    final result = await _recorder.stopRecorder();
    if (result != null) {
      final audioPlayerForDuration = audio_players.AudioPlayer();
      // Para arquivos locais, use setSourceDeviceFile
      if (!kIsWeb) {
        await audioPlayerForDuration.setSource(
          audio_players.DeviceFileSource(result),
        );
      }
      // getDuration() pode ser nulo, então fornecemos um valor padrão.
      final duration =
          await audioPlayerForDuration.getDuration() ?? Duration.zero;
      await audioPlayerForDuration.dispose();

      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '',
        type: MessageType.audio,
        mediaUrl: result,
        audioDuration: duration,
        isSentByMe: true,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(newMessage);
        _isRecording = false;
        _recordingPath = null;
      });
    }
  }

  void _sendMessage() {
    if (_textController.text.isNotEmpty) {
      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _textController.text,
        type: MessageType.text,
        isSentByMe: true,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(newMessage);
        _textController.clear();
      });
    }
  }

  // NOVO: Função para selecionar e enviar mídias
  Future<void> _pickAndSendMedia(FileType type) async {
    FilePickerResult? result;
    if (type == FileType.image || type == FileType.video) {
      final XFile? pickedFile = type == FileType.image
          ? await _picker.pickImage(source: ImageSource.gallery)
          : await _picker.pickVideo(source: ImageSource.gallery);

      if (pickedFile != null) {
        final fileLength = await pickedFile.length();
        result = FilePickerResult([
          PlatformFile(
            path: pickedFile.path,
            name: pickedFile.name,
            size: fileLength,
          ),
        ]);
      }
    } else {
      result = await FilePicker.platform.pickFiles(type: type);
    }

    if (result != null) {
      final file = result.files.single;
      final path = file.path;
      if (path == null) return;

      MessageType messageType;
      if ([
        'jpg',
        'jpeg',
        'png',
        'gif',
      ].any((ext) => path.toLowerCase().endsWith(ext))) {
        messageType = MessageType.image;
      } else if ([
        'mp4',
        'mov',
        'avi',
      ].any((ext) => path.toLowerCase().endsWith(ext))) {
        messageType = MessageType.video;
      } else if ([
        'mp3',
        'wav',
      ].any((ext) => path.toLowerCase().endsWith(ext))) {
        messageType = MessageType.audio;
      } else {
        // Qualquer outro tipo de arquivo será tratado como um documento.
        messageType = MessageType.document;
      }

      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: file.name, // Mostra o nome do arquivo
        type: messageType,
        mediaUrl: path,
        isSentByMe: true,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(newMessage);
        _showAttachmentMenu = false; // Fecha o menu de anexos
      });
    }
  }

  // NOVO: Função para capturar mídia pela câmera e enviar
  Future<void> _captureAndSendMedia({required bool isVideo}) async {
    final XFile? pickedFile = isVideo
        ? await _picker.pickVideo(source: ImageSource.camera)
        : await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: pickedFile.name,
        type: isVideo ? MessageType.video : MessageType.image,
        mediaUrl: pickedFile.path,
        isSentByMe: true,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(newMessage);
      });
    }
  }

  // NOVO: Mostra um menu para escolher entre tirar foto ou gravar vídeo
  void _showCameraActionSheet(BuildContext context) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_camera, color: colors.text),
                title: Text('Tirar Foto', style: TextStyle(color: colors.text)),
                onTap: () {
                  Navigator.of(context).pop();
                  _captureAndSendMedia(isVideo: false);
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam, color: colors.text),
                title: Text(
                  'Gravar Vídeo',
                  style: TextStyle(color: colors.text),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _captureAndSendMedia(isVideo: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // NOVO: Função para lidar com a atualização da conversa
  Future<void> _handleRefresh() async {
    // Simula uma chamada de rede para buscar mensagens mais antigas.
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        // Adiciona uma mensagem de exemplo no início da lista para simular o carregamento.
        _messages.insert(
          0,
          ChatMessage(
            id: 'old_${DateTime.now().millisecondsSinceEpoch}',
            text: 'Mensagem antiga carregada.',
            type: MessageType.text,
            isSentByMe: false,
            timestamp: _messages.first.timestamp.subtract(
              const Duration(minutes: 1),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(widget.chat.image)),
            const SizedBox(width: 16.0 * 0.75),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.name,
                  style: GoogleFonts.lexend(
                    color: colors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              // NOVO: Adiciona o RefreshIndicator para permitir "puxar para atualizar"
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(0),
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    // Invertendo a lista para mostrar a mais recente no final
                    final message = _messages.reversed.toList()[index];
                    return Align(
                      alignment: message.isSentByMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: _buildMessageBubble(message),
                    );
                  },
                ),
              ),
            ),
          ),
          _buildMessageInput(colors), // O input de mensagem
          if (_showAttachmentMenu)
            _buildAttachmentMenu(colors), // O menu de anexo
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final colors = AppColors.of(context);
    final isMyMessage = message.isSentByMe;
    final alignment = isMyMessage
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final bubbleColor = isMyMessage ? AppColors.primary : colors.surface;
    final textColor = isMyMessage ? AppColors.dark().background : colors.text;

    Widget messageContent;
    switch (message.type) {
      case MessageType.image:
        messageContent = _ImageMessageBubble(mediaUrl: message.mediaUrl!);
        break;
      case MessageType.video:
        messageContent = _VideoMessageBubble(mediaUrl: message.mediaUrl!);
        break;
      case MessageType.audio:
        messageContent = _AudioMessageBubble(
          mediaUrl: message.mediaUrl!,
          duration: message.audioDuration ?? Duration.zero,
          isMyMessage: isMyMessage,
        );
        break;
      case MessageType.document:
        messageContent = _DocumentMessageBubble(
          fileName: message.text,
          filePath: message.mediaUrl!,
        );
        break;
      case MessageType.text:
      default:
        messageContent = Text(
          message.text,
          style: GoogleFonts.lexend(color: textColor, fontSize: 16),
        );
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(15),
            ),
            // O ClipRRect agora envolve a mensagem para aplicar o borderRadius à mídia.
            // O padding é aplicado apenas para mensagens de texto.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: message.type == MessageType.text
                    ? const EdgeInsets.symmetric(vertical: 10, horizontal: 14)
                    : EdgeInsets.zero,
                child: messageContent,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(message.timestamp),
            style: GoogleFonts.lexend(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: colors.surface,
      child: SafeArea(
        child: Row(
          children: [
            // NOVO: Ícone de anexo
            IconButton(
              icon: Icon(Icons.attach_file, color: colors.textSecondary),
              onPressed: () =>
                  setState(() => _showAttachmentMenu = !_showAttachmentMenu),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: _isRecording
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          const Icon(Icons.mic, color: Colors.red, size: 28),
                          StreamBuilder<RecordingDisposition>(
                            stream: _recorder.onProgress,
                            builder: (context, snapshot) {
                              final duration = snapshot.hasData
                                  ? snapshot.data!.duration
                                  : Duration.zero;
                              String twoDigits(int n) =>
                                  n.toString().padLeft(2, '0');
                              final twoDigitMinutes = twoDigits(
                                duration.inMinutes.remainder(60),
                              );
                              final twoDigitSeconds = twoDigits(
                                duration.inSeconds.remainder(60),
                              );
                              return Text(
                                '$twoDigitMinutes:$twoDigitSeconds',
                                style: GoogleFonts.lexend(color: colors.text),
                              );
                            },
                          ),
                          const Text(
                            "Gravando...",
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      )
                    : TextField(
                        controller: _textController,
                        onChanged: (text) => setState(() {}),
                        style: GoogleFonts.lexend(color: colors.text),
                        decoration: InputDecoration(
                          hintText: 'Digite uma mensagem...',
                          hintStyle: GoogleFonts.lexend(
                            color: colors.textSecondary,
                          ),
                          contentPadding: const EdgeInsets.only(
                            left: 20,
                            right: 10,
                            top: 10,
                            bottom: 10,
                          ),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              color: colors.textSecondary,
                            ),
                            onPressed: () => _showCameraActionSheet(context),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressUp: _stopAndSendRecording,
              child: InkWell(
                onTap: () {
                  if (_textController.text.isNotEmpty) {
                    _sendMessage();
                  } else {
                    // Se o campo de texto estiver vazio, um toque rápido no microfone pode mostrar uma dica
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Segure para gravar um áudio.'),
                      ),
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    _isRecording
                        ? Icons.stop
                        : (_textController.text.isNotEmpty
                              ? Icons.send
                              : Icons.mic),
                    color: AppColors.dark().background,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NOVO: Widget para o menu de anexos
  Widget _buildAttachmentMenu(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: colors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentMenuItem(
            icon: Icons.insert_drive_file,
            label: 'Documento',
            onTap: () => _pickAndSendMedia(FileType.any),
            colors: colors,
          ),
          _buildAttachmentMenuItem(
            icon: Icons.photo,
            label: 'Foto',
            onTap: () => _pickAndSendMedia(FileType.image),
            colors: colors,
          ),
          _buildAttachmentMenuItem(
            icon: Icons.headset,
            label: 'Áudio',
            onTap: () => _pickAndSendMedia(FileType.audio),
            colors: colors,
          ),
          _buildAttachmentMenuItem(
            icon: Icons.videocam,
            label: 'Vídeo',
            onTap: () => _pickAndSendMedia(FileType.video),
            colors: colors,
          ),
        ],
      ),
    );
  }

  // NOVO: Widget para um item do menu de anexos
  Widget _buildAttachmentMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            child: Icon(
              icon,
              color: AppColors.dark().background, // Ícone preto
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.lexend(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// NOVO: Widget para exibir um balão de mensagem de documento
class _DocumentMessageBubble extends StatelessWidget {
  final String fileName;
  final String filePath;

  const _DocumentMessageBubble({
    required this.fileName,
    required this.filePath,
  });

  IconData _getIconForFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: () async {
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Não foi possível abrir o arquivo: ${result.message}',
              ),
            ),
          );
        }
      },
      child: SizedBox(
        width: 250,
        child: Row(
          children: [
            Icon(_getIconForFile(fileName), color: colors.text, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName,
                style: GoogleFonts.lexend(color: colors.text, fontSize: 16),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageMessageBubble extends StatelessWidget {
  final String mediaUrl;
  const _ImageMessageBubble({required this.mediaUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            // Passa o parâmetro correto dependendo se é uma URL ou um arquivo local
            builder: (_) => mediaUrl.startsWith('http')
                ? FullScreenMediaViewer(imageUrl: mediaUrl)
                : FullScreenMediaViewer(mediaFile: File(mediaUrl)),
          ),
        );
      },
      // O ClipRRect foi movido para o _buildMessageBubble.
      // O tamanho agora é definido por um AspectRatio para manter a proporção.
      // Adicionando um AspectRatio para garantir que a imagem não cause overflow.
      child: AspectRatio(
        aspectRatio: 16 / 9, // Uma proporção padrão para a pré-visualização
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

class _VideoMessageBubble extends StatefulWidget {
  final String mediaUrl;
  const _VideoMessageBubble({required this.mediaUrl});

  @override
  State<_VideoMessageBubble> createState() => _VideoMessageBubbleState();
}

class _VideoMessageBubbleState extends State<_VideoMessageBubble> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    // Verifica se a URL é de rede ou um caminho de arquivo local
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
        // NOVO: Adiciona a opção de download ao menu do player
        additionalOptions: (context) {
          return <OptionItem>[
            OptionItem(
              onTap: (context) async {
                Navigator.pop(context); // Fecha o menu de opções
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
        // NOVO: Traduz os textos do player de vídeo
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
    // O ClipRRect foi movido para o _buildMessageBubble.
    // O tamanho agora é definido por um AspectRatio para manter a proporção do vídeo.
    return _chewieController != null &&
            _chewieController!.videoPlayerController.value.isInitialized
        ? AspectRatio(
            aspectRatio:
                _chewieController!.videoPlayerController.value.aspectRatio,
            child: Theme(
              data: Theme.of(context).copyWith(
                iconTheme: const IconThemeData(color: AppColors.primary),
              ),
              child: Chewie(controller: _chewieController!),
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}

class _AudioMessageBubble extends StatefulWidget {
  final String mediaUrl;
  final Duration duration;
  final bool isMyMessage;

  const _AudioMessageBubble({
    required this.mediaUrl,
    required this.duration,
    required this.isMyMessage,
  });

  @override
  State<_AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<_AudioMessageBubble> {
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
                  inactiveColor: iconColor.withOpacity(0.3),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: GoogleFonts.lexend(
                        color: iconColor.withOpacity(0.8),
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
                          border: Border.all(color: iconColor.withOpacity(0.5)),
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
