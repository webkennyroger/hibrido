import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hibrido/features/profile/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  late UserModel _user;

  UserModel get user => _user;

  UserProvider(this.prefs) {
    _loadUser();
  }

  // Carrega os dados do usuário salvos no dispositivo.
  void _loadUser() {
    _user = UserModel(
      id:
          prefs.getString('userID') ??
          'default_user_id_123', // Adiciona um ID padrão
      name: prefs.getString('userName') ?? 'Kenny Roger',
      email: prefs.getString('userEmail') ?? 'webkennyroger@gmail.com',
      location: prefs.getString('userLocation') ?? 'Cuiabá, MT',
      height: prefs.getString('userHeight') ?? '183',
      weight: prefs.getString('userWeight') ?? '85',
      imagePath: 'assets/images/running.png', // Asset padrão
      avatarUrl:
          prefs.getString('userAvatarUrl') ??
          'https://i.ibb.co/L8Gj18j/avatar.png', // Adiciona a URL do avatar
      selectedImageFile: _loadImageFile(prefs.getString('userImagePath')),
    );
    notifyListeners();
  }

  // Converte o caminho salvo em um objeto File.
  File? _loadImageFile(String? path) {
    if (path != null && path.isNotEmpty) {
      return File(path);
    }
    return null;
  }

  // Atualiza e salva os dados do usuário.
  Future<void> updateUser(UserModel newUser) async {
    _user = newUser;

    // Salva os dados no SharedPreferences
    await prefs.setString('userID', newUser.id);
    await prefs.setString('userName', newUser.name);
    await prefs.setString('userEmail', newUser.email);
    await prefs.setString('userLocation', newUser.location);
    await prefs.setString('userHeight', newUser.height);
    await prefs.setString('userWeight', newUser.weight);
    await prefs.setString(
      'userAvatarUrl',
      newUser.avatarUrl,
    ); // Salva a URL do avatar
    if (newUser.selectedImageFile != null) {
      await prefs.setString('userImagePath', newUser.selectedImageFile!.path);
    } else {
      // Se a imagem for removida, limpa a preferência
      await prefs.remove('userImagePath');
    }

    notifyListeners(); // Notifica os widgets para se atualizarem
  }
}
