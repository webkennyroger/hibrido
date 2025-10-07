import 'dart:io';
import 'package:flutter/widgets.dart';

class UserModel {
  String name;
  String email;
  String location;
  String height;
  String weight;
  String? imagePath; // Caminho para a imagem local (asset)
  File? selectedImageFile; // Arquivo da nova imagem selecionada (da galeria)

  UserModel({
    required this.name,
    required this.email,
    required this.location,
    required this.height,
    required this.weight,
    this.imagePath,
    this.selectedImageFile,
  });

  // Helper para obter a imagem correta a ser exibida
  ImageProvider get profileImage {
    if (selectedImageFile != null) return FileImage(selectedImageFile!);
    if (imagePath != null) return AssetImage(imagePath!);
    return const NetworkImage(
      'https://via.placeholder.com/150',
    ); // A placeholder image
  }
}
