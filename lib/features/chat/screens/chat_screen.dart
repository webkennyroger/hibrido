import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/chat/models/conversation.dart';
import 'package:hibrido/features/chat/screens/chats_screen.dart';
import 'package:hibrido/features/chat/screens/conversation_screen.dart';
import 'package:hibrido/features/chat/screens/message_search_screen.dart';
import 'package:hibrido/features/chat/screens/contacts_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Conversation> _conversations = [
    Conversation(
      name: 'Rodrigo',
      lastMessage: 'Bora treinar hoje?',
      time: '10:41',
      avatarUrl: 'https://i.pravatar.cc/150?img=1',
      unreadCount: 2,
    ),
    Conversation(
      name: 'Fernanda',
      lastMessage: 'O treino de ontem foi ótimo!',
      time: '09:23',
      avatarUrl: 'https://i.pravatar.cc/150?img=2',
      unreadCount: 0,
    ),
    Conversation(
      name: 'Grupo da Corrida',
      lastMessage: 'Fernanda: Vamos marcar uma corrida no parque?',
      time: 'Ontem',
      avatarUrl: 'https://i.pravatar.cc/150?img=3',
      unreadCount: 5,
    ),
    Conversation(
      name: 'Lucas',
      lastMessage: 'Valeu!',
      time: 'Sexta-feira',
      avatarUrl: 'https://i.pravatar.cc/150?img=4',
      unreadCount: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Chat',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: colors.text),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessageSearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _ConversationTile(conversation: conversation, colors: colors);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ContactsScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.colors});

  final Conversation conversation;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(conversation.avatarUrl),
      ),
      title: Text(
        conversation.name,
        style: GoogleFonts.lexend(color: colors.text),
      ),
      subtitle: Text(
        conversation.lastMessage,
        style: GoogleFonts.lexend(color: colors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            conversation.time,
            style: GoogleFonts.lexend(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: GoogleFonts.lexend(color: Colors.white, fontSize: 12),
              ),
            )
          else
            const SizedBox(height: 22), // Placeholder for alignment
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              chat: Chat(
                name: conversation.name,
                image: conversation.avatarUrl,
              ),
            ),
          ),
        );
      },
    );
  }
}
