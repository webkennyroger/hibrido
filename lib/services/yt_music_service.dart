import 'package:google_sign_in/google_sign_in.dart';

/// Classe para gerenciar a autenticação e interação com a API do YouTube Music.
class YtMusicService {
  // Instância do GoogleSignIn para o processo de autenticação.
  // O `clientId` é para aplicativos web e não é necessário para mobile.
  // As `scopes` definem quais permissões seu app está solicitando.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      // Esta é a scope para acesso de leitura aos dados do YouTube.
      // Essencial para buscar playlists, por exemplo.
      'https://www.googleapis.com/auth/youtube.readonly',
    ],
  );

  GoogleSignInAccount? _currentUser;

  /// Tenta autenticar o usuário com sua conta Google.
  ///
  /// Primeiro, tenta um login silencioso. Se falhar, abre o fluxo de login padrão.
  /// Retorna `true` se a autenticação for bem-sucedida, `false` caso contrário.
  Future<bool> initializeAndAuthenticate() async {
    try {
      // Tenta fazer login silenciosamente (se o usuário já autorizou o app antes).
      _currentUser = await _googleSignIn.signInSilently();

      if (_currentUser == null) {
        // Se o login silencioso falhar, inicia o fluxo de login interativo.
        _currentUser = await _googleSignIn.signIn();
      }

      if (_currentUser != null) {
        print('Usuário autenticado com sucesso: ${_currentUser!.displayName}');
        // TODO: Após autenticar, você pode usar as credenciais para
        // fazer chamadas à API do YouTube e buscar playlists.
        return true;
      } else {
        print('Falha na autenticação com o Google.');
        return false;
      }
    } catch (error) {
      print('Erro durante a autenticação com o Google: $error');
      return false;
    }
  }

  /// Desconecta o usuário.
  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    _currentUser = null;
    print('Usuário desconectado.');
  }

  // TODO: Implementar métodos para interagir com a API do YouTube.
  // Ex: Future<List<Playlist>> getPlaylists() async { ... }
  // Ex: Future<void> play(String videoId) async { ... }
}