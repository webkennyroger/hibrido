import 'package:flutter/material.dart';
import 'package:hibrido/core/theme/custom_colors.dart';

enum SportOption { corrida, pedalada, caminhada }

IconData getSportIcon(SportOption option) {
  switch (option) {
    case SportOption.corrida:
      return Icons.directions_run;
    case SportOption.pedalada:
      return Icons.directions_bike;
    case SportOption.caminhada:
      return Icons.directions_walk;
  }
}

Color getSportColor(SportOption option) {
  switch (option) {
    case SportOption.corrida:
      return const Color(0xFF00A676); // Strong Green
    case SportOption.pedalada:
      return AppColors.warning; // Orange
    case SportOption.caminhada:
      return AppColors.info; // Blue
  }
}

String getSportLabel(SportOption option) {
  switch (option) {
    case SportOption.corrida:
      return 'Corrida';
    case SportOption.pedalada:
      return 'Pedalada';
    case SportOption.caminhada:
      return 'Caminhada';
  }
}

SportOption sportFromString(String sport) {
  switch (sport.toLowerCase()) {
    case 'pedalada':
      return SportOption.pedalada;
    case 'caminhada':
      return SportOption.caminhada;
    case 'corrida':
    default:
      return SportOption.corrida;
  }
}

Color getSportColorFromString(String sport) {
  return getSportColor(sportFromString(sport));
}

IconData getSportIconFromString(String sport) {
  return getSportIcon(sportFromString(sport));
}
