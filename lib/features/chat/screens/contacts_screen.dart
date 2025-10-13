import 'package:flutter/material.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/chat/screens/chats_screen.dart';
import 'package:hibrido/features/chat/screens/conversation_screen.dart';
import 'package:hibrido/features/chat/screens/message_search_screen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        title: const Text("Nova Conversa"),
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
        itemCount: demoContactsImage.length,
        itemBuilder: (context, index) => ContactCard(
          name: "Jenny Wilson",
          number: "(239) 555-0108",
          image: demoContactsImage[index],
          isActive: index.isEven,
          press: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ConversationScreen(
                  chat: Chat(
                    name: "Jenny Wilson",
                    image: demoContactsImage[index],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.name,
    required this.number,
    required this.image,
    required this.isActive,
    required this.press,
  });

  final String name, number, image;
  final bool isActive;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 16.0 / 2,
      ),
      onTap: press,
      leading: CircleAvatarWithActiveIndicator(
        image: image,
        isActive: isActive, // for demo
        radius: 28,
      ),
      title: Text(name, style: TextStyle(color: colors.text)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 16.0 / 2),
        child: Text(number, style: TextStyle(color: colors.textSecondary)),
      ),
    );
  }
}

class CircleAvatarWithActiveIndicator extends StatelessWidget {
  const CircleAvatarWithActiveIndicator({
    super.key,
    this.image,
    this.radius = 24,
    this.isActive,
  });

  final String? image;
  final double? radius;
  final bool? isActive;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(radius: radius, backgroundImage: NetworkImage(image!)),
        if (isActive!)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              height: 16,
              width: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final List<String> demoContactsImage = [
  'https://i.postimg.cc/g25VYN7X/user-1.png',
  'https://i.postimg.cc/cCsYDjvj/user-2.png',
  'https://i.postimg.cc/sXC5W1s3/user-3.png',
  'https://i.postimg.cc/4dvVQZxV/user-4.png',
  'https://i.postimg.cc/FzDSwZcK/user-5.png',
];
