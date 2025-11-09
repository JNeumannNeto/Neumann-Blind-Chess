import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const NeumannChessApp());
}

class NeumannChessApp extends StatelessWidget {
  const NeumannChessApp({super.key});

  @override
  Widget build(BuildContext context) {
return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
      title: 'Neumann Chess',
    debugShowCheckedModeBanner: false,
  theme: ThemeData(
          primarySwatch: Colors.indigo,
        useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF667EEA),
            brightness: Brightness.light,
    ),
     ),
        home: const AuthWrapper(),
  navigatorKey: GlobalKey<NavigatorState>(),
        onGenerateRoute: (settings) {
   if (settings.name == '/login') {
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          }
    if (settings.name == '/lobby') {
    return MaterialPageRoute(builder: (_) => const LobbyScreen());
          }
if (settings.name?.startsWith('/game/') == true) {
    final gameId = settings.name!.split('/').last;
        return MaterialPageRoute(
        builder: (_) => GameScreen(gameId: gameId),
   );
   }
          return null;
      },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuth();
    setState(() => _isCheckingAuth = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
      body: Center(
    child: CircularProgressIndicator(),
  ),
      );
    }

    return Consumer<AuthProvider>(
  builder: (context, auth, _) {
        print('AuthWrapper - isAuthenticated: ${auth.isAuthenticated}');
        print('AuthWrapper - user: ${auth.user?.username}');
        
  if (auth.isAuthenticated && auth.user != null) {
return const LobbyScreen();
 }
        
        return const LoginScreen();
      },
    );
  }
}
