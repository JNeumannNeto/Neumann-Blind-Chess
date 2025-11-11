import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'dart:async';  // ✅ NOVO: Para Timer
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/game.dart';
import '../models/user.dart';
import '../l10n/app_localizations.dart';

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
  Timer? _pollingTimer;  // ✅ NOVO: Timer para polling

  @override
  void initState() {
    super.initState();
    _loadData();
_reloadUserStats();
    _startPolling();  // ✅ NOVO: Iniciar polling
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();  // ✅ NOVO: Cancelar timer ao sair
    super.dispose();
  }

  // ✅ NOVO: Polling a cada 3 segundos (como o React)
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _checkForAcceptedChallenges();
      }
    });
  }

  // ✅ NOVO: Verifica se algum desafio meu foi aceito
  Future<void> _checkForAcceptedChallenges() async {
    try {
    final response = await _apiService.getPendingGames();
      final previousMyChallenges = _myChallenges;
   final currentMyChallenges = (response['myChallenges'] as List?)
       ?.map((g) => Game.fromJson(g))
.toList() ?? [];

      // Se tinha desafios e agora não tem mais, foi aceito!
      if (previousMyChallenges.isNotEmpty && currentMyChallenges.isEmpty) {
        print('DEBUG: Desafio foi aceito! Procurando jogo ativo...');
        
 // Buscar o jogo que acabou de ser aceito
        final user = Provider.of<AuthProvider>(context, listen: false).user;
   if (user != null) {
 final gamesResponse = await _apiService.getUserGames(user.id, limit: 1);
       if (gamesResponse.isNotEmpty && mounted) {
            final game = gamesResponse.first;
            print('DEBUG: Redirecionando para jogo ${game.id}');
            
  // Cancelar polling temporariamente
      _pollingTimer?.cancel();
   
            // Redirecionar para o jogo
      await Navigator.of(context).pushNamed('/game/${game.id}');
            
            // Recarregar e reiniciar polling quando voltar
          if (mounted) {
  _loadData();
  _reloadUserStats();
           _startPolling();
  }
 }
   }
      }
    } catch (e) {
      print('DEBUG: Erro ao verificar desafios aceitos: $e');
    }
  }

  // ✅ MODIFICADO: Método para recarregar estatísticas do usuário
  Future<void> _reloadUserStats() async {
    try {
      print('DEBUG: Recarregando estatísticas do usuário...');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
  await authProvider.loadUser();
      
   // ✅ NOVO: Logs detalhados
      final user = authProvider.user;
      print('DEBUG: ===== ESTATÍSTICAS DO BACKEND =====');
      print('DEBUG: user.id = ${user?.id}');
   print('DEBUG: user.username = ${user?.username}');
      print('DEBUG: user.stats.gamesPlayed = ${user?.stats.gamesPlayed}');
      print('DEBUG: user.stats.gamesWon = ${user?.stats.gamesWon}');
      print('DEBUG: user.stats.gamesLost = ${user?.stats.gamesLost}');
      print('DEBUG: user.stats.gamesDraw = ${user?.stats.gamesDraw}');
      print('DEBUG: =====================================');
      
      // ✅ NOVO: Força rebuild após carregar
   if (mounted) {
        setState(() {
          print('DEBUG: setState() chamado após recarregar estatísticas');
        });
 }
    } catch (e) {
      print('DEBUG: Erro ao recarregar estatísticas: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.getPendingGames();
final user = Provider.of<AuthProvider>(context, listen: false).user;
      
      if (user != null) {
        final gamesResponse = await _apiService.getUserGames(user.id, limit: 5);
        
        // ✅ MODIFICADO: Verificar status local de cada jogo e criar nova lista
   final updatedGames = <Game>[];
        for (var game in gamesResponse) {
          if (game.status == 'em_andamento' && game.currentFen.isNotEmpty) {
            // Verificar se o jogo realmente terminou localmente
        try {
     final chess = chess_lib.Chess();
      chess.load(game.currentFen);
    
  if (chess.in_checkmate) {
 print('DEBUG Lobby: Jogo ${game.id} está em xeque-mate (backend não atualizou)');
      // ✅ Criar nova cópia com status atualizado
             updatedGames.add(game.copyWith(status: 'checkmate'));
              } else if (chess.in_stalemate) {
     print('DEBUG Lobby: Jogo ${game.id} está em afogamento (backend não atualizou)');
              updatedGames.add(game.copyWith(status: 'stalemate'));
          } else if (chess.in_draw) {
       print('DEBUG Lobby: Jogo ${game.id} está em empate (backend não atualizou)');
             updatedGames.add(game.copyWith(status: 'draw'));
  } else {
                // Jogo ainda em andamento normalmente
      updatedGames.add(game);
        }
   } catch (e) {
    print('DEBUG Lobby: Erro ao verificar status do jogo ${game.id}: $e');
     updatedGames.add(game);
       }
          } else {
        // Jogo já finalizado ou sem FEN
       updatedGames.add(game);
          }
        }
    
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
          _recentGames = updatedGames;  // ✅ Usar lista atualizada
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
final l10n = AppLocalizations.of(context)!;
    // ✅ MODIFICADO: Consumer ao invés de Provider.of para não disparar rebuild
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
     final user = authProvider.user;

        if (_isLoading) {
  return const Scaffold(
     body: Center(child: CircularProgressIndicator()),
  );
    }

    return Scaffold(
   appBar: AppBar(
        title: Text(l10n.appTitle),
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
      ),  // ✅ CORRIGIDO: Fecha AppBar corretamente
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
  _showCreateGameDialog();  // ✅ MODIFICADO: Chamar diálogo
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
    );  // Fecha Scaffold
  },  // ✅ Fecha Consumer builder
);  // ✅ Fecha Consumer
  }  // Fecha build

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
    // ✅ NOVO: Detectar se é seção "Meus Desafios"
    final bool isMyChallenge = title.contains('Meus Desafios');
    
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
            trailing: isMyChallenge
    ? ElevatedButton(  // ✅ MODIFICADO: Apenas botão "Cancelar"
      onPressed: () async {
         await _apiService.declineGame(game.id);
_loadData();
 },
       child: const Text('Cancelar'),
      style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
        ),
  )
   : Row(
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
   // ✅ MODIFICADO: Recarregar ao voltar
     await Navigator.of(context).pushNamed('/game/${game.id}');
        if (mounted) {
   _loadData();
      _reloadUserStats();
      }
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
    // ✅ NOVO: Determinar texto do status
    String statusText = game.status;
    if (game.status == 'checkmate') {
      // Determinar vencedor
    final winner = game.currentTurn == 'white' ? 'Pretas' : 'Brancas';
      final score = game.currentTurn == 'white' ? '0-1' : '1-0';
      statusText = 'Xeque-mate - $winner vencem ($score)';
    } else if (game.status == 'stalemate') {
   statusText = 'Afogamento - Empate (½-½)';
    } else if (game.status == 'draw') {
      statusText = 'Empate acordado (½-½)';
    } else if (game.status == 'resigned') {
      statusText = 'Desistência';
    } else if (game.status == 'em_andamento') {
      statusText = 'Em andamento';
    }

    return Card(
      child: ListTile(
        title: Text('${game.whitePlayer.username} vs ${game.blackPlayer.username}'),
    subtitle: Text(statusText),
        trailing: game.status == 'em_andamento'
   ? Row(
      mainAxisSize: MainAxisSize.min,
              children: [
    TextButton(
        onPressed: () async {
   final confirm = await showDialog<bool>(
     context: context,
           builder: (context) => AlertDialog(
         title: const Text('Desistir da Partida?'),
      content: const Text('Tem certeza que deseja desistir? Esta ação não pode ser desfeita.'),
        actions: [
       TextButton(
         onPressed: () => Navigator.of(context).pop(false),
  child: const Text('Cancelar'),
        ),
      TextButton(
               onPressed: () => Navigator.of(context).pop(true),
           child: const Text('Desistir'),
           style: TextButton.styleFrom(foregroundColor: Colors.red),
      ),
     ],
      ),
           );
    
      if (confirm == true && mounted) {
  try {
         await _apiService.resignGame(game.id);
    _loadData();
    _reloadUserStats();
        } catch (e) {
               print('Erro ao desistir: $e');
          }
           }
        },
child: const Text('Desistir'),
       ),
 const SizedBox(width: 8),
     ElevatedButton(
  onPressed: () async {
           // ✅ MODIFICADO: Forçar reload ao voltar
         await Navigator.of(context).pushNamed('/game/${game.id}');
          if (mounted) {
               await _loadData();
       await _reloadUserStats();  // ✅ Aguardar reload completo
   }
     },
         child: const Text('Continuar'),
         ),
           ],
              )
      : ElevatedButton.icon(  // ✅ Botão "Ver Partida" para finalizadas
  onPressed: () async {
   // ✅ Redirecionar para replay
    await Navigator.of(context).pushNamed('/replay/${game.id}');
     if (mounted) {
       await _loadData();
  await _reloadUserStats();
    }
       },
    icon: const Icon(Icons.visibility, size: 18),
        label: const Text('Ver Partida', style: TextStyle(fontSize: 12)),
     style: ElevatedButton.styleFrom(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
    ),
      ),
    );
  }

  // ✅ NOVO: Diálogo para criar nova partida
  void _showCreateGameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Partida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Escolha o tipo de desafio:'),
       const SizedBox(height: 16),
        ListTile(
         leading: const Icon(Icons.public, color: Colors.blue),
    title: const Text('Desafio Livre'),
    subtitle: const Text('Qualquer pessoa pode aceitar'),
   onTap: () {
      Navigator.of(context).pop();
     _showColorSelectionDialog(isOpenChallenge: true);  // ✅ MODIFICADO: Escolher cor primeiro
     },
          ),
     ListTile(
         leading: const Icon(Icons.person, color: Colors.orange),
           title: const Text('Desafiar Jogador'),
          subtitle: const Text('Escolher um adversário específico'),
         onTap: () {
      Navigator.of(context).pop();
     _showPlayerSearchDialog();
     },
 ),
          ],
     ),
     actions: [
          TextButton(
       onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
  ),
        ],
      ),
    );
  }

  // ✅ NOVO: Diálogo para escolher cor
  void _showColorSelectionDialog({bool isOpenChallenge = false, String? opponentId}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolha sua Cor'),
        content: Column(
 mainAxisSize: MainAxisSize.min,
  children: [
          ListTile(
              leading: Container(
      width: 40,
         height: 40,
  decoration: BoxDecoration(
               color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
       borderRadius: BorderRadius.circular(8),
 ),
     child: const Icon(Icons.circle, color: Colors.white),
     ),
         title: const Text('Brancas'),
subtitle: const Text('Você joga primeiro'),
 onTap: () {
      Navigator.of(context).pop();
        if (isOpenChallenge) {
  _createOpenChallenge('white');  // ✅ CORRIGIDO: Minúscula
      } else if (opponentId != null) {
                  _createDirectChallenge(opponentId, 'white');  // ✅ CORRIGIDO: Minúscula
          }
        },
     ),
            ListTile(
       leading: Container(
     width: 40,
      height: 40,
         decoration: BoxDecoration(
   color: Colors.black,
         border: Border.all(color: Colors.grey, width: 2),
            borderRadius: BorderRadius.circular(8),
      ),
    child: const Icon(Icons.circle, color: Colors.black),
         ),
          title: const Text('Pretas'),
       subtitle: const Text('Oponente joga primeiro'),
onTap: () {
           Navigator.of(context).pop();
       if (isOpenChallenge) {
      _createOpenChallenge('black');  // ✅ CORRIGIDO: Minúscula
  } else if (opponentId != null) {
          _createDirectChallenge(opponentId, 'black');  // ✅ CORRIGIDO: Minúscula
      }
            },
  ),
            ListTile(
  leading: const Icon(Icons.shuffle, color: Colors.purple),
         title: const Text('Aleatória'),
        subtitle: const Text('Sortear cor automaticamente'),
            onTap: () {
     Navigator.of(context).pop();
      final randomColor = DateTime.now().millisecondsSinceEpoch % 2 == 0 ? 'white' : 'black';  // ✅ CORRIGIDO: Minúsculas
                if (isOpenChallenge) {
 _createOpenChallenge(randomColor);
          } else if (opponentId != null) {
           _createDirectChallenge(opponentId, randomColor);
           }
     },
),
          ],
   ),
     actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // ✅ MODIFICADO: Criar desafio livre com cor
  Future<void> _createOpenChallenge(String color) async {
    try {
    setState(() => _isLoading = true);
      
      print('DEBUG: Criando desafio livre - color: $color');
      print('DEBUG: Chamando _apiService.createGame(null, "$color")');
  final game = await _apiService.createGame(null, color);
      print('DEBUG: Desafio livre criado: ${game.id} (cor: $color)');
  
      setState(() {
        _error = 'Desafio livre criado com sucesso!';
        _isLoading = false;
      });
      
      await _loadData();
    } catch (e) {
      print('DEBUG: Erro ao criar desafio livre: $e');
 print('DEBUG: Tipo do erro: ${e.runtimeType}');
      setState(() {
        _error = 'Erro ao criar desafio: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ✅ MODIFICADO: Diálogo para buscar jogador
  void _showPlayerSearchDialog() {
    final searchController = TextEditingController();
    List<User> searchResults = [];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
    title: const Text('Buscar Jogador'),
  content: Column(
   mainAxisSize: MainAxisSize.min,
   children: [
    TextField(
      controller: searchController,
    decoration: const InputDecoration(
           hintText: 'Digite o nome do jogador...',
        prefixIcon: Icon(Icons.search),
  ),
   onChanged: (query) async {
     if (query.length >= 2) {
     try {
      final results = await _apiService.searchUsers(query);
            setDialogState(() {
     searchResults = results;
    });
       } catch (e) {
     print('Erro ao buscar jogadores: $e');
       }
         }
  },
      ),
              const SizedBox(height: 16),
     if (searchResults.isNotEmpty)
    SizedBox(
           height: 200,
         child: ListView.builder(
              itemCount: searchResults.length,
      itemBuilder: (context, index) {
       final player = searchResults[index];
        return ListTile(
  title: Text(player.username),
       subtitle: Text('${player.stats.gamesPlayed} partidas'),
      onTap: () {
           Navigator.of(context).pop();
          _showColorSelectionDialog(opponentId: player.id);  // ✅ MODIFICADO: Escolher cor primeiro
          },
       );
       },
 ),
      ),
  ],
          ),
          actions: [
  TextButton(
       onPressed: () => Navigator.of(context).pop(),
         child: const Text('Cancelar'),
  ),
     ],
        ),
  ),
    );
  }

  // ✅ MODIFICADO: Criar desafio direto com cor
  Future<void> _createDirectChallenge(String opponentId, String color) async {
    try {
      setState(() => _isLoading = true);
      
   print('DEBUG: Criando desafio - opponentId: $opponentId, color: $color');
      final game = await _apiService.createGame(opponentId, color);
      print('DEBUG: Desafio direto criado: ${game.id} (cor: $color)');
      
      setState(() {
      _error = 'Desafio enviado com sucesso!';
   _isLoading = false;
    });
      
      await _loadData();
    } catch (e) {
      print('DEBUG: Erro ao criar desafio: $e');
      setState(() {
      _error = 'Erro ao criar desafio: ${e.toString()}';
        _isLoading = false;
      });
  }
  }
}  // ✅ Fecha _LobbyScreenState
