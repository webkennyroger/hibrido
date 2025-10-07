import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hibrido/features/app/screens/app_screen.dart';
import 'package:provider/provider.dart';
import 'package:hibrido/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  // Garante que os bindings do Flutter foram inicializados antes de rodar o app.
  WidgetsFlutterBinding.ensureInitialized();
  // Carrega a instância do SharedPreferences.
  final prefs = await SharedPreferences.getInstance();
  runApp(
    // MultiProvider permite registrar vários providers.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => UserProvider(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

/// Gerencia o estado do tema do aplicativo (claro/escuro).
class ThemeProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  static const String _themeKey = 'isDarkMode';

  // O tema padrão agora é o claro.
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider(this.prefs) {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Carrega o tema salvo na inicialização.
  void _loadTheme() {
    final isDark =
        prefs.getBool(_themeKey) ?? false; // Padrão é `false` (light)
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Alterna o tema e notifica os ouvintes (widgets) para se reconstruírem.
  Future<void> toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await prefs.setBool(_themeKey, isOn);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // O Consumer reconstrói o MaterialApp quando o tema muda.
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Fitness App',
          // Define o tema claro padrão do aplicativo.
          theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
          // Define o tema escuro do aplicativo.
          darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
          // `themeMode: ThemeMode.system` faz o app seguir o tema do sistema operacional.
          // Agora ele vai seguir o nosso ThemeProvider.
          themeMode: themeProvider.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
          home:
              const AppScreen(), // A tela de boas-vindas pode ser usada aqui se necessário
        );
      },
    );
  }
}
