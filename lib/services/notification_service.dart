import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Serviço para gerenciar notificações locais no aplicativo.
///
/// Esta classe segue o padrão Singleton para garantir uma única instância
/// em todo o app.
class NotificationService {
  // Instância Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Plugin principal para notificações locais.
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Stream para notificar a UI quando o usuário toca em uma notificação.
  final StreamController<String?> _onNotificationTap =
      StreamController.broadcast();
  Stream<String?> get onNotificationTap => _onNotificationTap.stream;

  // --- Constantes para Canais de Notificação (Android) ---
  static const String activityChannelId = 'activity_channel';
  static const String activityChannelName = 'Atividades';
  static const String activityChannelDescription =
      'Notificações sobre o andamento das atividades físicas.';

  /// Inicializa o serviço de notificações.
  ///
  /// Deve ser chamado na inicialização do app (ex: no `initState` do widget principal).
  Future<void> init() async {
    // Configurações para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher'); // Ícone do app

    // Configurações para iOS/macOS
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Configurações gerais
    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
            // Quando o usuário toca na notificação, adiciona o payload ao stream.
            // A UI pode ouvir este stream para decidir para qual tela navegar.
            if (notificationResponse.payload != null) {
              _onNotificationTap.add(notificationResponse.payload);
            }
          },
    );
  }

  /// Solicita permissão para enviar notificações no Android 13+.
  ///
  /// Deve ser chamado em um momento apropriado na UI, pois exibe um diálogo ao usuário.
  Future<void> requestAndroidPermission() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Mostra uma notificação de atividade.
  ///
  /// [id] é um identificador único para a notificação.
  /// [title] é o título da notificação.
  /// [body] é o corpo da mensagem.
  /// [payload] são dados opcionais que podem ser usados para navegação.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Detalhes específicos para notificações Android, usando o canal de atividades.
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          activityChannelId,
          activityChannelName,
          channelDescription: activityChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker', // Texto que aparece brevemente na barra de status
        );

    // Detalhes para iOS (pode ser mais customizado se necessário).
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails();

    // Agrupa os detalhes de cada plataforma.
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    // Exibe a notificação.
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Fecha o StreamController quando o serviço não for mais necessário.
  void dispose() {
    _onNotificationTap.close();
  }
}
