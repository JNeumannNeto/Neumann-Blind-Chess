# Neumann Chess Flutter

## ?? Aplicativo Flutter do Neumann Blind Chess

Versão mobile do jogo de Xadrez às Cegas construída com Flutter.

---

## ?? Estrutura do Projeto

```
neumann_chess_flutter/
??? lib/
?   ??? main.dart          ? Criado
?   ??? models/
?   ?   ??? user.dart    ? Criado
?   ?   ??? game.dart           ? Criado
?   ??? services/
?   ?   ??? api_service.dart     ? Criado
?   ??? providers/
?   ?   ??? auth_provider.dart       ? Criado
?   ??? screens/
?   ?   ??? login_screen.dart        ? Criado
? ?   ??? lobby_screen.dart     ?? Criar
?   ?   ??? game_screen.dart ?? Criar
?   ??? widgets/
?       ??? challenge_card.dart      ?? Criar
?    ??? game_stats.dart          ?? Criar
?       ??? chess_board.dart  ?? Criar
??? pubspec.yaml     ? Criado
??? README.md          ? Este arquivo
```

---

## ?? Como Executar

### **1. Instalar Flutter**

```bash
# Verificar se Flutter está instalado
flutter doctor

# Se não estiver, baixe em: https://flutter.dev/
```

### **2. Instalar Dependências**

```bash
cd neumann_chess_flutter
flutter pub get
```

### **3. Executar**

```bash
# Android/iOS
flutter run

# Web
flutter run -d chrome

# Windows
flutter run -d windows
```

---

## ?? Dependências Principais

| Pacote | Versão | Uso |
|--------|--------|-----|
| `provider` | 6.1.1 | Gerenciamento de estado |
| `http` | 1.1.0 | Requisições HTTP |
| `shared_preferences` | 2.2.2 | Armazenamento local |
| `chess` | 0.8.3 | Lógica do xadrez |
| `flutter_chess_board` | 1.0.1 | Tabuleiro visual |

---

## ?? Configuração da API

Edite `lib/services/api_service.dart`:

```dart
// Durante desenvolvimento (HTTP)
static const String baseUrl = 'http://18.116.70.90/api';

// Produção (HTTPS - depois que DNS propagar)
static const String baseUrl = 'https://blindchess.jneumann.com.br/api';
```

---

## ?? Telas Criadas

### ? **1. Login Screen** (`login_screen.dart`)
- Login com email/senha
- Registro de novos usuários
- Validação de formulários
- Design gradiente moderno

### ?? **2. Lobby Screen** (a criar)

Funcionalidades necessárias:
- Listar desafios diretos
- Listar desafios livres
- Criar novo desafio
- Buscar oponentes
- Estatísticas do usuário
- Partidas recentes

### ?? **3. Game Screen** (a criar)

Funcionalidades necessárias:
- Tabuleiro de xadrez interativo
- Ocultar peças do adversário
- Lista de peças capturadas
- Notificações de movimento
- Indicador de turno
- Botão de desistir

---

## ?? Cores do Tema

```dart
Primary: #667EEA (Azul)
Secondary: #764BA2 (Roxo)
Success: #4CAF50 (Verde)
Error: #F44336 (Vermelho)
Warning: #FF9800 (Laranja)
Background: #F5F7FA (Cinza claro)
```

---

## ?? Próximos Passos

### **Arquivos a Criar:**

1. **`lib/screens/lobby_screen.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/game.dart';
import '../models/user.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final ApiService _apiService = ApiService();
  List<Game> _directChallenges = [];
  List<Game> _openChallenges = [];
  List<Game> _myChallenges = [];
  List<Game> _recentGames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  _startPolling();
  }

  Future<void> _loadData() async {
    // Implementar carregamento de dados
  }

  void _startPolling() {
    // Implementar polling a cada 3 segundos
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neumann Chess'),
        actions: [
        IconButton(
            icon: const Icon(Icons.logout),
         onPressed: () async {
     await Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
         },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
     onRefresh: _loadData,
      child: ListView(
  padding: const EdgeInsets.all(16),
          children: [
          // Estatísticas
            _buildStatsCard(),
     
  // Desafios Diretos
       if (_directChallenges.isNotEmpty)
          _buildChallengesSection(
'Desafios Diretos',
      _directChallenges,
                Colors.orange,
   ),
           
// Desafios Livres
     if (_openChallenges.isNotEmpty)
     _buildChallengesSection(
      'Desafios Livres',
        _openChallenges,
     Colors.blue,
     ),
   
           // Criar Nova Partida
   _buildNewGameCard(),
        
                  // Partidas Recentes
         if (_recentGames.isNotEmpty)
           _buildRecentGamesSection(),
 ],
           ),
 ),
  );
  }

  Widget _buildStatsCard() {
    final user = Provider.of<AuthProvider>(context).user!;
    return Card(
   child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
       'Bem-vindo, ${user.username}!',
              style: Theme.of(context).textTheme.headlineSmall,
     ),
   const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [
                _buildStatItem('Jogos', user.stats.gamesPlayed, Colors.blue),
        _buildStatItem('Vitórias', user.stats.gamesWon, Colors.green),
        _buildStatItem('Derrotas', user.stats.gamesLost, Colors.red),
    _buildStatItem('Empates', user.stats.gamesDraw, Colors.orange),
 ],
       ),
    ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
      Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
 fontWeight: FontWeight.bold,
    color: color,
  ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Implementar outros widgets...
}
```

2. **`lib/screens/game_screen.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import '../services/api_service.dart';
import '../models/game.dart';

class GameScreen extends StatefulWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final ApiService _apiService = ApiService();
  late ChessBoardController _chessBoardController;
  Game? _game;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chessBoardController = ChessBoardController();
    _loadGame();
  }

  Future<void> _loadGame() async {
    try {
   final game = await _apiService.getGame(widget.gameId);
      setState(() {
        _game = game;
        _chessBoardController.loadFen(game.currentFen);
   _isLoading = false;
      });
    } catch (e) {
      // Tratar erro
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_game!.whitePlayer.username} vs ${_game!.blackPlayer.username}'),
      ),
      body: Column(
      children: [
     // Indicador de turno
          _buildTurnIndicator(),
        
          // Tabuleiro
          ChessBoard(
   controller: _chessBoardController,
 boardColor: BoardColor.brown,
    onMove: _onMove,
    ),
  
      // Peças capturadas
       _buildCapturedPieces(),
  ],
      ),
    );
  }

  void _onMove() {
    // Implementar lógica de movimento
  }

  Widget _buildTurnIndicator() {
    // Implementar indicador de turno
    return Container();
  }

  Widget _buildCapturedPieces() {
    // Implementar lista de peças capturadas
    return Container();
  }
}
```

---

## ?? Autenticação

O app usa JWT tokens armazenados localmente com `shared_preferences`.

**Fluxo:**
1. Login/Registro ? Recebe token
2. Token salvo localmente
3. Requisições incluem token no header `Authorization: Bearer <token>`
4. Logout ? Remove token

---

## ?? Funcionalidades Implementadas

### ? **Completo:**
- [x] Estrutura do projeto
- [x] Modelos de dados (User, Game, Move)
- [x] Serviço de API completo
- [x] Provider de autenticação
- [x] Tela de login/registro
- [x] Main app com rotas

### ?? **A Implementar:**
- [ ] Tela do Lobby completa
- [ ] Tela do Jogo com tabuleiro
- [ ] Widgets reutilizáveis
- [ ] Notificações de movimento
- [ ] Sons e vibrações
- [ ] Modo offline (cache)
- [ ] Testes unitários

---

## ?? Plataformas Suportadas

- ? **Android** (API 21+)
- ? **iOS** (12.0+)
- ? **Web**
- ? **Windows**
- ? **macOS**
- ? **Linux**

---

## ?? Troubleshooting

### **Erro de CORS (Web)**

No desenvolvimento web, adicione ao backend:

```javascript
// server/server.js
app.use(cors({
  origin: ['http://localhost:*', 'http://127.0.0.1:*'],
  credentials: true
}));
```

### **SSL Certificate Error**

Se usar HTTPS e der erro de certificado:

```dart
// Apenas para desenvolvimento! Nunca em produção
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// No main.dart
void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const NeumannChessApp());
}
```

---

## ?? Recursos Úteis

- [Flutter Documentation](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)
- [Chess Package](https://pub.dev/packages/chess)
- [Flutter Chess Board](https://pub.dev/packages/flutter_chess_board)

---

## ?? Deploy

### **Android:**
```bash
flutter build apk --release
# APK em: build/app/outputs/flutter-apk/app-release.apk
```

### **iOS:**
```bash
flutter build ios --release
# Usar Xcode para assinar e publicar
```

### **Web:**
```bash
flutter build web --release
# Arquivos em: build/web/
```

---

## ? Próximas Melhorias

1. **Push Notifications** - Notificar quando for sua vez
2. **Chat** - Conversar com oponente durante partida
3. **Replay** - Assistir partidas antigas
4. **Análise** - Analisar jogadas com engine
5. **Ranking** - Sistema de ELO/Rating
6. **Torneios** - Criar e participar de torneios
7. **Modo Offline** - Jogar contra IA localmente
8. **Temas** - Múltiplos temas de tabuleiro
9. **Idiomas** - Suporte multilíngue
10. **Acessibilidade** - Narração de jogadas (TalkBack/VoiceOver)

---

## ?? Licença

MIT License - Você pode usar, modificar e distribuir livremente.

---

## ????? Autor

Desenvolvido para o projeto Neumann Blind Chess.

**Backend:** Node.js + Express + MongoDB
**Frontend Web:** React
**Frontend Mobile:** Flutter

---

## ?? Suporte

Para problemas ou dúvidas:
1. Verifique a documentação acima
2. Consulte os logs: `flutter logs`
3. Teste a API diretamente: `curl http://18.116.70.90/api/auth/me`

---

**Bom desenvolvimento! ????**
