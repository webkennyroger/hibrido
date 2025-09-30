import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import 'package:hibrido/features/activity/widgets/activity_card.dart';

class ActivityDetailScreen extends StatelessWidget {
  final ActivityData activityData;
  // Callback para notificar a tela anterior (ex: para resetar o estado).
  final VoidCallback onDelete;

  const ActivityDetailScreen({
    super.key,
    required this.activityData,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detalhes da Atividade',
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: ActivityCard(activityData: activityData, onDelete: onDelete),
      ),
    );
  }
}
