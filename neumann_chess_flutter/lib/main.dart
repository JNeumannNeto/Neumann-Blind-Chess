import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/game_screen.dart';
import 'screens/replay_screen.dart';  // ✅ NOVO: Importar replay screen
import 'l10n/app_localizations.dart';

void main() {
  runApp(const NeumannChessApp());
}

class NeumannChessApp extends StatelessWidget {
  const NeumannChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
  create: (_) => AuthProvider(),
  child: MaterialApp(
        title: 'Neumann Chess',
      theme: ThemeData(
          primarySwatch: Colors.blue,
useMaterial3: true,
     ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
       GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
     Locale('en'),
          Locale('pt'),
        ],
        initialRoute: '/login',
        onGenerateRoute: (settings) {
  if (settings.name == '/login') {
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          } else if (settings.name == '/lobby') {
            return MaterialPageRoute(builder: (_) => const LobbyScreen());
      } else if (settings.name?.startsWith('/game/') ?? false) {
      final gameId = settings.name!.substring(6);
   return MaterialPageRoute(
              builder: (_) => GameScreen(gameId: gameId),
  );
      } else if (settings.name?.startsWith('/replay/') ?? false) {  // ✅ NOVO: Rota para replay
     final gameId = settings.name!.substring(8);
         return MaterialPageRoute(
        builder: (_) => ReplayScreen(gameId: gameId),
            );
          }
          return null;
        },
      ),
    );
}
}
