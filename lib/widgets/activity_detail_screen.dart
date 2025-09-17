import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/models/activity_data.dart';
import 'package:hibrido/screens/activity_card.dart';

class ActivityDetailScreen extends StatelessWidget {
  final ActivityData activityData;

  const ActivityDetailScreen({Key? key, required this.activityData})
    : super(key: key);

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
        child: ActivityCard(activityData: activityData),
      ),
    );
  }
}
