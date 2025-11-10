import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/game.dart';
import '../l10n/app_localizations.dart';  // ✅ NOVO: Importar localizações

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
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.getPendingGames();
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      
      if (user != null) {
final gamesResponse = await _apiService.getUserGames(user.id, limit: 5);
    
        setState(() {
     _directChallenges = (response['directChallenges'] as List?)
      ?.map((g) => Game.fromJson(g))
    .toList() ?? [];
          _openChallenges = (response['openChallenges'] as List?)
   ?.map((g) => Game.fromJson(g))
         .toList() ?? [];
     _myChallenges = (response['myChallenges'] as List?)
      ?.map((g) => Game.fromJson(g))
              .toList() ?? [];
          _recentGames = gamesResponse;
          _isLoading = false;
    });
}
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar dados';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;  // ✅ NOVO: Pegar traduções
    final user = Provider.of<AuthProvider>(context).user;

    if (_isLoading) {
      return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),  // ✅ TRADUZIDO
        actions: [
      IconButton(
    icon: const Icon(Icons.logout),
  onPressed: () async {
      await Provider.of<AuthProvider>(context, listen: false).logout();
if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
      }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
   child: ListView(
        padding: const EdgeInsets.all(16),
          children: [
     // User Stats
            Card(
         child: Padding(
      padding: const EdgeInsets.all(16),
child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
           children: [
    Text(
           l10n.welcome(user?.username ?? "Jogador"),  // ✅ TRADUZIDO
    style: Theme.of(context).textTheme.headlineSmall,
          ),
     const SizedBox(height: 16),
     Row(
     mainAxisAlignment: MainAxisAlignment.spaceAround,
       children: [
            _buildStatItem(l10n.games, user?.stats.gamesPlayed ?? 0, Colors.blue),  // ✅ TRADUZIDO
   _buildStatItem(l10n.victories, user?.stats.gamesWon ?? 0, Colors.green),  // ✅ TRADUZIDO
     _buildStatItem(l10n.defeats, user?.stats.gamesLost ?? 0, Colors.red),  // ✅ TRADUZIDO
  _buildStatItem(l10n.draws, user?.stats.gamesDraw ?? 0, Colors.orange),  // ✅ TRADUZIDO
            ],
           ),
        ],
          ),
              ),
         ),

 if (_error.isNotEmpty)
  Padding(
   padding: const EdgeInsets.symmetric(vertical: 8),
     child: Card(
 color: _error.contains('criado') ? Colors.green[100] : Colors.red[100],
  child: Padding(
        padding: const EdgeInsets.all(16),
      child: Text(_error),
                  ),
     ),
              ),

    // Direct Challenges
  if (_directChallenges.isNotEmpty)
       _buildChallengesSection(
'Desafios Diretos',
                _directChallenges,
        Colors.orange,
 ),

      // Open Challenges
            if (_openChallenges.isNotEmpty)
     _buildChallengesSection(
   'Desafios Livres',
                _openChallenges,
       Colors.blue,
   ),

            // My Challenges
            if (_myChallenges.isNotEmpty)
   _buildChallengesSection(
        'Meus Desafios',
        _myChallenges,
     Colors.purple,
   ),

        // Create New Game Button
      const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
           // TODO: Implement create game
  },
     icon: const Icon(Icons.add),
        label: const Text('Nova Partida'),
          style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.all(16),
       ),
      ),

     // Recent Games
       if (_recentGames.isNotEmpty) ...[
        const SizedBox(height: 24),
   Text(
    'Partidas Recentes',
             style: Theme.of(context).textTheme.titleLarge,
           ),
              const SizedBox(height: 8),
  ..._recentGames.map((game) => _buildGameCard(game)),
   ],
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

  Widget _buildChallengesSection(String title, List<Game> games, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
    '$title (${games.length})',
          style: TextStyle(
            fontSize: 18,
  fontWeight: FontWeight.bold,
  color: color,
),
      ),
    const SizedBox(height: 8),
        ...games.map((game) => Card(
     child: ListTile(
            title: Text(game.whitePlayer.username),
   subtitle: Text('vs ${game.blackPlayer.username}'),
    trailing: Row(
        mainAxisSize: MainAxisSize.min,
       children: [
       TextButton(
      onPressed: () async {
         await _apiService.declineGame(game.id);
          _loadData();
      },
         child: const Text('Recusar'),
      ),
      ElevatedButton(
    onPressed: () async {
    await _apiService.acceptGame(game.id);
          if (mounted) {
     Navigator.of(context).pushNamed('/game/${game.id}');
  }
       },
     child: const Text('Aceitar'),
       ),
          ],
         ),
        ),
        )),
      ],
    );
  }

  Widget _buildGameCard(Game game) {
    return Card(
      child: ListTile(
        title: Text('${game.whitePlayer.username} vs ${game.blackPlayer.username}'),
        subtitle: Text(game.status),
        trailing: game.status == 'em_andamento'
      ? ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/game/${game.id}');
  },
    child: const Text('Continuar'),
 )
            : const Icon(Icons.check_circle, color: Colors.green),
    ),
    );
  }
}
