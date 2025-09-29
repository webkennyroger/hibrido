import 'dart:async';
import 'package:flutter/services.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyService {
  // IMPORTANTE: Substitua com suas credenciais do Spotify Developer Dashboard
  final String _clientId = '0c7e5f27e9fe4a2d8e08648fb129c972';
  final String _redirectUri =
      'hibrido://callback'; // Deve ser o mesmo do AndroidManifest

  bool _isInitialized = false;

  // Autentica e inicializa o Spotify SDK.
  Future<bool> initializeAndAuthenticate() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Conecta ao Spotify. Isso abre o app do Spotify para login.
      var result = await SpotifySdk.connectToSpotifyRemote(
        clientId: _clientId,
        redirectUrl: _redirectUri,
        scope:
            'app-remote-control, '
            'user-modify-playback-state, '
            'playlist-read-private, '
            'user-read-currently-playing',
      );

      _isInitialized = result;
      return result;
    } on PlatformException {
      // print('Erro ao conectar ao Spotify SDK: ${e.code}: ${e.message}');
      _isInitialized = false;
      return false;
    }
  }

  // Toca uma música a partir de uma URI do Spotify.
  // Pode ser uma música, um álbum, uma playlist, etc.
  Future<void> playTrack(String spotifyUri) async {
    if (!_isInitialized) {
      await initializeAndAuthenticate();
    }

    if (_isInitialized) {
      try {
        await SpotifySdk.play(spotifyUri: spotifyUri);
      } on PlatformException {
        // print('Erro ao tocar a música: ${e.code}: ${e.message}');
      }
    }
  }

  // Busca o estado atual do player para saber qual música está tocando.
  Future<Map<String, dynamic>?> getCurrentTrack() async {
    if (!_isInitialized) return null;

    try {
      var playerState = await SpotifySdk.getPlayerState();
      if (playerState != null && playerState.track != null) {
        return {
          'name': playerState.track!.name,
          'artist': playerState.track!.artist.name,
          'album': playerState.track!.album.name,
          'image_url': playerState.track!.imageUri.raw,
          'is_playing': !playerState.isPaused,
        };
      }
    } on PlatformException {
      // print('Erro ao obter o estado do player: ${e.code}: ${e.message}');
    }
    return null;
  }

  // Métodos de controle do player
  Future<void> pause() async {
    if (_isInitialized) await SpotifySdk.pause();
  }

  Future<void> resume() async {
    if (_isInitialized) await SpotifySdk.resume();
  }

  Future<void> skipNext() async {
    if (_isInitialized) await SpotifySdk.skipNext();
  }

  Future<void> skipPrevious() async {
    if (_isInitialized) await SpotifySdk.skipPrevious();
  }

  // Este método busca um URI de uma playlist, não uma URL de prévia.
  Future<String?> getPlaylistUri() async {
    if (!_isInitialized) {
      final isConnected = await initializeAndAuthenticate();
      if (!isConnected) return null;
    }

    // Aqui você usaria sua lógica de API para obter o URI da playlist.
    // O código abaixo é apenas um exemplo simplificado.
    const playlistId = '2ppwkqMdiulHWZ2rwcolC2';
    return 'spotify:playlist:$playlistId';
  }
}
