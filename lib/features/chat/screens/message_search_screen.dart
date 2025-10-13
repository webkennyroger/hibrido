import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/chat/models/conversation.dart';
import 'package:hibrido/features/chat/screens/chats_screen.dart';
import 'package:hibrido/features/chat/screens/conversation_screen.dart';

class MessageSearchScreen extends StatefulWidget {
  const MessageSearchScreen({super.key});

  @override
  State<MessageSearchScreen> createState() => _MessageSearchScreenState();
}

class _MessageSearchScreenState extends State<MessageSearchScreen> {
  // Use the same mock data as ChatScreen for consistency
  final List<Conversation> _allConversations = [
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
  List<Conversation> _filteredConversations = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Start with an empty list, results will show as user types.
    _filteredConversations = [];
  }

  void _filterConversations(String query) {
    setState(() {
      _query = query;
      _filteredConversations = _allConversations
          .where(
            (convo) => convo.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        title: const Text("Buscar Conversa"),
      ),
      body: Column(
        children: [
          // Appbar search
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            color: colors.surface,
            child: Form(
              child: TextFormField(
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _filterConversations,
                style: TextStyle(color: colors.text),
                decoration: InputDecoration(
                  fillColor: colors.background,
                  prefixIcon: Icon(Icons.search, color: colors.textSecondary),
                  hintText: "Buscar...",
                  hintStyle: TextStyle(color: colors.textSecondary),
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.0 * 1.5,
                    vertical: 16.0,
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? _buildInitialState(colors)
                : _buildSearchResults(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(AppColors colors) {
    return Center(
      child: Text(
        "Busque por nome do contato ou grupo.",
        style: TextStyle(color: colors.textSecondary, fontSize: 16),
      ),
    );
  }

  Widget _buildSearchResults(AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _filteredConversations.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    "Nenhum resultado encontrado para '$_query'",
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              ),
            ]
          : _filteredConversations.map((conversation) {
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
            }).toList(),
    );
  }
}
