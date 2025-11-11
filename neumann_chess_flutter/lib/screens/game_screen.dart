import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../services/api_service.dart';
import '../models/game.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
// import 'package:audioplayers/audioplayers.dart';  // ✅ NOVO: Para sons (descomente quando tiver os arquivos de áudio)

class GameScreen extends StatefulWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final ApiService _apiService = ApiService();
  Game? _game;
  bool _isLoading = true;
  String _error = '';
  chess_lib.Chess? _chess;
  bool _isMyTurn = false;
  String? _myColor;
  String? _selectedSquare;
  List<String> _legalMoves = [];
  Timer? _pollingTimer;
  String? _actualTurn;
  String? _lastNotification;  // ✅ NOVO: Notificação persistente

  @override
  void initState() {
    super.initState();
    _loadGame();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isLoading && _game != null) {
        print('DEBUG: Polling - atualizando jogo...');
        _loadGame();
    }
    });
  }

  Future<void> _loadGame() async {
    try {
      var game = await _apiService.getGame(widget.gameId);
   final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id;

    print('═══════════════════════════════════════════════════');
  print('DEBUG _loadGame: INÍCIO DA ANÁLISE');
      print('game.status = ${game.status}');
      print('game.currentFen = ${game.currentFen}');
      print('game.moves.length = ${game.moves.length}');

      // ✅ PRIORIDADE MÁXIMA: Criar chess e verificar estado ANTES de tudo
      final currentChess = chess_lib.Chess();
   if (game.currentFen.isNotEmpty) {
        currentChess.load(game.currentFen);
 print('✅ FEN carregado no tabuleiro');
      } else {
        print('⚠️ FEN está vazio!');
      }

      // ✅ VERIFICAR ESTADO DO TABULEIRO
      print('───────────────────────────────────────────────────');
      print('📊 ESTADO DO TABULEIRO:');
      print('   currentChess.turn = ${currentChess.turn}');
      print('   currentChess.in_check = ${currentChess.in_check}');
      print('   currentChess.in_checkmate = ${currentChess.in_checkmate}');
      print('   currentChess.in_stalemate = ${currentChess.in_stalemate}');
      print('   currentChess.in_draw = ${currentChess.in_draw}');
      print(' currentChess.in_threefold_repetition = ${currentChess.in_threefold_repetition}');
      print('   currentChess.insufficient_material = ${currentChess.insufficient_material}');
      print('   currentChess.game_over = ${currentChess.game_over}');
      
    // Verificar movimentos possíveis
      final allMoves = currentChess.moves();
      print('   Movimentos possíveis = ${allMoves.length}');
      if (allMoves.isEmpty) {
        print('   ⚠️ NENHUM MOVIMENTO POSSÍVEL!');
      }
   print('───────────────────────────────────────────────────');

      // ✅ VERIFICAR XEQUE-MATE/STALEMATE PRIMEIRO (antes de definir turno)
      bool needsToEndGame = false;
      String? endGameStatus;
      
      if (currentChess.in_checkmate) {
        print('🔴 XEQUE-MATE DETECTADO!');
needsToEndGame = true;
        endGameStatus = 'xeque_mate';
      } else if (currentChess.in_stalemate) {
        print('🟡 AFOGAMENTO DETECTADO!');
  needsToEndGame = true;
  endGameStatus = 'stalemate';
   } else if (currentChess.in_draw) {
        print('🟡 EMPATE DETECTADO!');
        needsToEndGame = true;
        endGameStatus = 'empate';
      } else if (currentChess.game_over) {
        print('🟡 JOGO TERMINADO (game_over = true)');
     needsToEndGame = true;
     endGameStatus = 'empate';
    } else {
print('✅ Jogo ainda ativo (sem mate/empate detectado)');
      }

      // ✅ Se detectou fim de jogo e o backend ainda não atualizou, forçar atualização
      final isGameActive = game.status == 'active' || game.status == 'em_andamento';
      print('───────────────────────────────────────────────────');
      print('🎮 COMPARAÇÃO BACKEND vs LOCAL:');
  print('   Backend diz: game.status = "${game.status}" (ativo = $isGameActive)');
      print('   Local detectou: endGameStatus = "$endGameStatus" (precisa finalizar = $needsToEndGame)');
      
      if (needsToEndGame && isGameActive) {
      print('🔥 INCONSISTÊNCIA DETECTADA! Backend não finalizou o jogo.');
      print('   🎬 Tentando finalizar no backend...');
  
        // ✅ CORRIGIDO: Parar polling imediatamente
      _pollingTimer?.cancel();
    
        // ✅ CORRIGIDO: Calcular result correto (1-0, 0-1, 1/2-1/2)
  String? calculatedResult;
        String? calculatedWinnerId;
        
        if (endGameStatus == 'checkmate') {
    // Xeque-mate: o lado que NÃO pode mover perdeu
    final winnerIsWhite = currentChess.turn == chess_lib.Color.BLACK;  // Se é turno das pretas, brancas venceram
          calculatedResult = winnerIsWhite ? '1-0' : '0-1';
          calculatedWinnerId = winnerIsWhite ? game.whitePlayer.id : game.blackPlayer.id;
        } else {
  // Empate (stalemate, draw, etc)
    calculatedResult = '1/2-1/2';
  calculatedWinnerId = null;
   }
        
 print('   📊 Result calculado: $calculatedResult (winnerId: $calculatedWinnerId)');
        
        // ✅ CORRIGIDO: Aguardar a resposta do servidor antes de redirecionar
        try {
  await _apiService.endGame(
            game.id,
       endGameStatus!,
       winnerId: calculatedWinnerId,
       result: calculatedResult,  // ✅ NOVO: Enviar result
          );
          
     print('✅ Backend finalizou o jogo com sucesso!');
          print('   Status atualizado para: $endGameStatus');
 print('   Result: $calculatedResult');
     
        // ✅ Aguardar frame e navegar para replay
          if (mounted) {
          Future.delayed(Duration.zero, () {
   if (mounted) {
          Navigator.of(context).pushReplacementNamed('/replay/${widget.gameId}');
      }
            });
   }
     } catch (e) {
   print('❌ ERRO ao finalizar no backend: $e');
      print('   Tipo do erro: ${e.runtimeType}');
      
          // ✅ MESMO COM ERRO: Tentar recarregar e reiniciar polling
          if (mounted) {
            await _loadGame();
            _startPolling();
          }
}
    
 // Retornar sem continuar o processamento
        return;
      } else {
        print('✅ Backend e local estão sincronizados.');
      }

      // Detectar o turno REAL do FEN
      final actualTurn = currentChess.turn == chess_lib.Color.WHITE ? 'white' : 'black';
      print('───────────────────────────────────────────────────');
    print('🎲 Turno detectado do FEN: $actualTurn');

      String? detectedColor;
      bool detectedIsMyTurn = false;

      // Determinar a cor do jogador atual
      if (currentUserId == game.whitePlayer.id) {
    detectedColor = 'white';
        detectedIsMyTurn = actualTurn == 'white' && isGameActive;
        print('   Eu sou: BRANCAS');
      } else if (currentUserId == game.blackPlayer.id) {
        detectedColor = 'black';
        detectedIsMyTurn = actualTurn == 'black' && isGameActive;
        print('   Eu sou: PRETAS');
      }
    print('   É minha vez? $detectedIsMyTurn');

      // ✅ Verificar se o jogo está ativo AGORA (pode ter sido atualizado)
      final finalIsGameActive = game.status == 'active' || game.status == 'em_andamento';
    print('───────────────────────────────────────────────────');
      print('🏁 Status final do jogo: ${game.status} (ativo = $finalIsGameActive)');

      // ✅ Verificar se há notificação a mostrar NO ESTADO ATUAL
      String? currentNotification;
  
      if (game.moves.isNotEmpty && finalIsGameActive) {
     final l10n = AppLocalizations.of(context)!;

 // ✅ PRIORIDADE 1: Verificar XEQUE (só se não for mate e jogo ativo)
        if (currentChess.in_check) {
          currentNotification = l10n.kingInCheck;
    print('📢 Notificação: Rei em xeque!');
        } else {
          // ✅ PRIORIDADE 2: Verificar se houve CAPTURA no último movimento
          final lastMove = game.moves.last;
   
     // Recriar posição ANTES do último movimento
     final prevChess = chess_lib.Chess();
          if (game.moves.length > 1) {
            for (var i = 0; i < game.moves.length - 1; i++) {
      final move = game.moves[i];
     prevChess.move({'from': move.from, 'to': move.to, 'promotion': move.promotion});
          }
}
          
       // Verificar se havia uma peça na casa de destino
       final capturedPiece = prevChess.get(lastMove.to);
          if (capturedPiece != null) {
            final pieceName = _getPieceName(capturedPiece.type);
       final colorName = capturedPiece.color == chess_lib.Color.WHITE 
              ? l10n.colorWhite 
       : l10n.colorBlack;
     currentNotification = l10n.pieceCaptured(pieceName, colorName);
            print('📢 Notificação: Captura de ${pieceName} ${colorName}');
          }
      
 // ✅ PRIORIDADE 3: Verificar se houve PROMOÇÃO no último movimento
          if (currentNotification == null && lastMove.promotion != null) {
            currentNotification = l10n.pawnPromoted;
     print('📢 Notificação: Promoção de peão');
          }
    }
      }

      print('═══════════════════════════════════════════════════');

      setState(() {
        _game = game;
   _isLoading = false;
      _myColor = detectedColor;
      _isMyTurn = detectedIsMyTurn;
        _actualTurn = actualTurn;
        
        // ✅ Atualizar notificação (pode ser null = limpar)
 _lastNotification = currentNotification;

        // Criar instância do chess
        _chess = currentChess;
      });

      // ✅ MOSTRAR DIÁLOGO DE FIM DE JOGO (se não estiver ativo)
      if (!finalIsGameActive && mounted) {
        print('🎊 Mostrando diálogo de fim de jogo...');
        Future.delayed(Duration.zero, () {
          if (mounted) {
     _showGameEndDialog();
          }
    });
  }
    } catch (e) {
      print('❌ ERRO em _loadGame: $e');
      setState(() {
        _error = e.toString();
   _isLoading = false;
      });
  }
  }

  void _onSquareTapped(String square) {
    print('DEBUG _onSquareTapped: square=$square, _isMyTurn=$_isMyTurn, _selectedSquare=$_selectedSquare');
    
    if (!_isMyTurn || _game == null || _chess == null) {
      print('DEBUG: Movimento bloqueado - _isMyTurn=$_isMyTurn, _game=${_game != null}, _chess=${_chess != null}');
   return;
    }

    final piece = _chess!.get(square);
    final myColorLetter = _myColor == 'white' ? chess_lib.Color.WHITE : chess_lib.Color.BLACK;

    print('DEBUG: piece no quadrado $square = ${piece?.type}, cor=${piece?.color}');
    print('DEBUG: myColorLetter=$myColorLetter');

    // Se não há peça selecionada
    if (_selectedSquare == null) {
      // Selecionar apenas peças da minha cor
      if (piece != null && piece.color == myColorLetter) {
        final moves = _chess!.moves({'square': square});
        print('DEBUG: Selecionando peça em $square, movimentos possíveis: $moves');

        setState(() {
          _selectedSquare = square;
   _legalMoves = moves
              .map((move) => _extractDestination(move))
              .toList();
        });
        print('DEBUG: Peça selecionada! _legalMoves=$_legalMoves');
      } else {
        print('DEBUG: Não é minha peça ou quadrado vazio');
      }
    } else {
      print('DEBUG: Já existe peça selecionada em $_selectedSquare');
      
      // Já existe uma peça selecionada
      if (_selectedSquare == square) {
        print('DEBUG: Desselecionando peça');
        // Desselecionar se clicar na mesma peça
        setState(() {
          _selectedSquare = null;
      _legalMoves = [];
        });
   } else if (piece != null && piece.color == myColorLetter) {
print('DEBUG: Selecionando outra peça da minha cor');
        // Selecionar outra peça da minha cor
        setState(() {
          _selectedSquare = square;
      _legalMoves = _chess!
         .moves({'square': square})
  .map((move) => _extractDestination(move))
          .toList();
        });
  } else {
        print('DEBUG: Tentando mover de $_selectedSquare para $square');
        // Tentar fazer o movimento
        _makeMove(_selectedSquare!, square);
      }
    }
  }

  String _extractDestination(String move) {
  print('DEBUG _extractDestination: move="$move", length=${move.length}');
    
    // Movimentos podem vir em formatos diferentes:
    // "e2e4" (4 chars), "e7e8q" (5 chars com promoção), ou apenas "e4" (2 chars)
    
    // Se já é apenas o destino (formato curto)
    if (move.length == 2) {
      print('DEBUG _extractDestination: formato curto, retornando "$move"');
      return move;
    }
    
    // Formato longo "e2e4" ou "e7e8q"
  if (move.length >= 4) {
      final dest = move.substring(2, 4);
      print('DEBUG _extractDestination: formato longo, extraindo destino "$dest"');
      return dest;
    }
    
    print('DEBUG _extractDestination: formato desconhecido, retornando vazio');
    return '';
  }

  Future<void> _makeMove(String from, String to) async {
    print('DEBUG _makeMove: from=$from, to=$to, _isMyTurn=$_isMyTurn');
    
  final l10n = AppLocalizations.of(context)!;
    
    // ✅ REMOVIDO: Não precisa mais limpar manualmente - o _loadGame faz isso
    
if (!_isMyTurn || _chess == null) {
      print('DEBUG: Movimento bloqueado no _makeMove');
      _showSnackBar(l10n.notYourTurn);
      return;
    }

 try {
  // Verificar se é movimento de promoção
  String? promotion;
final piece = _chess!.get(from);
      print('DEBUG: Peça em $from = ${piece?.type}');

    if (piece != null &&
   piece.type == chess_lib.PieceType.PAWN &&
    ((piece.color == chess_lib.Color.WHITE && to[1] == '8') ||
          (piece.color == chess_lib.Color.BLACK && to[1] == '1'))) {
   promotion = 'q';
        print('DEBUG: Movimento é promoção para dama');
      }

      print('DEBUG: Tentando fazer movimento no tabuleiro local...');
      final moveResult = _chess!.move({'from': from, 'to': to, 'promotion': promotion});

  if (moveResult == null || moveResult == false) {
  print('DEBUG: Movimento INVÁLIDO retornado pela biblioteca chess');
        _showSnackBar(l10n.invalidMove);
   setState(() {
          _selectedSquare = null;
   _legalMoves = [];
        });
        return;
      }

   print('DEBUG: Movimento válido!');
      print('DEBUG: FEN após movimento: ${_chess!.fen}');

    final pieceMoving = _chess!.get(to);
  
      final moveData = {
   'from': from,
   'to': to,
      'piece': pieceMoving != null ? '${pieceMoving.color.name[0]}${pieceMoving.type.name}' : 'unknown',
   'captured': null,
    'san': '$from$to',
     'fen': _chess!.fen,
  if (promotion != null) 'promotion': promotion,
      };

print('DEBUG: moveData que será enviado: $moveData');

      final updatedGame = await _apiService.makeMove(
   widget.gameId,
        from,
        to,
        promotion: promotion,
  moveData: moveData,
      );

      print('DEBUG: Movimento aceito pela API! Novo FEN: ${updatedGame.currentFen}');
      
   // ✅ SIMPLIFICADO: Apenas atualizar o jogo - o _loadGame gerenciará notificações
      setState(() {
   _game = updatedGame;
    _isMyTurn = updatedGame.currentTurn == _myColor;
 _selectedSquare = null;
        _legalMoves = [];

   if (updatedGame.currentFen.isNotEmpty) {
       _chess!.load(updatedGame.currentFen);
   }
      });

      final isGameActive = updatedGame.status == 'active' || updatedGame.status == 'em_andamento';
      if (!isGameActive) {
    _showGameEndDialog();
      }
    } catch (e) {
      print('DEBUG ERRO em _makeMove: $e');
      _showSnackBar(l10n.errorMakingMove(e.toString()));
      await _loadGame();
      setState(() {
        _selectedSquare = null;
      _legalMoves = [];
   });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ✅ NOVO: Mostrar notificação persistente
  void _showGameNotification(String message) {
    setState(() {
      _lastNotification = message;
 });
    
    // ✅ NOVO: Tocar som (descomente quando tiver arquivos de áudio)
    // final player = AudioPlayer();
    // player.play(AssetSource('sounds/capture.mp3'));
  }

  // ✅ NOVO: Obter nome da peça traduzido
  String _getPieceName(chess_lib.PieceType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case chess_lib.PieceType.PAWN:
        return l10n.piecePawn;
      case chess_lib.PieceType.KNIGHT:
        return l10n.pieceKnight;
      case chess_lib.PieceType.BISHOP:
        return l10n.pieceBishop;
      case chess_lib.PieceType.ROOK:
  return l10n.pieceRook;
      case chess_lib.PieceType.QUEEN:
        return l10n.pieceQueen;
  case chess_lib.PieceType.KING:
        return l10n.pieceKing;
      default:  // ✅ NOVO: Caso padrão para satisfazer o compilador
    return l10n.piecePawn;  // Fallback (nunca deve acontecer)
    }
  }

  void _showGameEndDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    String message = '';
    IconData icon = Icons.emoji_events;
    Color iconColor = Colors.amber;
  
    switch (_game!.status) {
      case 'checkmate':
  final winner = _game!.currentTurn == 'white' 
   ? l10n.blackPieces 
   : l10n.whitePieces;
        message = l10n.checkmate(winner);
        icon = Icons.emoji_events;
   iconColor = Colors.amber;
        break;
      case 'stalemate':
        message = l10n.stalemate;
        icon = Icons.handshake;
    iconColor = Colors.grey;
  break;
   case 'draw':
        message = l10n.draw;
        icon = Icons.handshake;
        iconColor = Colors.grey;
   break;
      case 'resigned':
        message = l10n.resigned;
  icon = Icons.flag;
   iconColor = Colors.red;
        break;
      default:
     message = l10n.gameEnded;
        icon = Icons.info;
  iconColor = Colors.blue;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
       Icon(icon, color: iconColor, size: 32),
    const SizedBox(width: 12),
        Expanded(child: Text(l10n.gameFinished)),
   ],
        ),
   content: Column(
       mainAxisSize: MainAxisSize.min,
          children: [
   Text(
         message,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
     textAlign: TextAlign.center,
    ),
       const SizedBox(height: 16),
       Text(
       '${_game!.whitePlayer.username} vs ${_game!.blackPlayer.username}',
    style: const TextStyle(fontSize: 14, color: Colors.grey),
   textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
  // ✅ IMPLEMENTADO: Botão para ver replay
          TextButton.icon(
   onPressed: () {
              Navigator.of(context).pop();
 Navigator.of(context).pushReplacementNamed('/replay/${widget.gameId}');
 },
       icon: const Icon(Icons.replay),
       label: const Text('Ver Lances'),
   ),
      TextButton(
     onPressed: () {
       Navigator.of(context).pop();
       Navigator.of(context).pop();
 },
       child: Text(l10n.backToLobby),
    ),
    ],
      ),
    );
  }

  Widget _buildBoard() {
    if (_chess == null) return const CircularProgressIndicator();

    final isWhitePlayer = _myColor == 'white';
 final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    // Inverter se for jogador preto
    if (!isWhitePlayer) {
      files.reversed.toList();
      ranks.reversed.toList();
    }

    // ✅ NOVO: Verificar se o jogo terminou
 final isGameActive = _game?.status == 'active' || _game?.status == 'em_andamento';

    return AspectRatio(
aspectRatio: 1,
      child: Column(
        children: List.generate(8, (rankIndex) {
       final rank = isWhitePlayer ? ranks[rankIndex] : ranks[7 - rankIndex];
          return Expanded(
      child: Row(
         children: List.generate(8, (fileIndex) {
    final file = isWhitePlayer ? files[fileIndex] : files[7 - fileIndex];
   final square = '$file$rank';
    final isLight = (fileIndex + rankIndex) % 2 == 0;
      final piece = _chess!.get(square);
             final isSelected = square == _selectedSquare;

           // Determinar cor do jogador
        final myColorLetter = _myColor == 'white' ? chess_lib.Color.WHITE : chess_lib.Color.BLACK;

    // ✅ MODIFICADO: Lógica para mostrar ou ocultar peças
  bool shouldShowPiece = false;

             if (piece != null) {
   if (_myColor == null) {
            shouldShowPiece = true;
    } else if (piece.color == myColorLetter) {
           shouldShowPiece = true;  // Sempre mostrar minhas peças
       } else {
          // ✅ MODIFICADO: Mostrar peças do adversário se o jogo terminou
 shouldShowPiece = !isGameActive;
           }
     }

      return Expanded(
     child: GestureDetector(
       onTap: isGameActive ? () => _onSquareTapped(square) : null,  // ✅ Desabilitar toque se jogo terminou
          child: Container(
    decoration: BoxDecoration(
    color: isSelected
   ? Colors.yellow.withOpacity(0.5)
      : isLight
              ? const Color(0xFFEEEED2)
             : const Color(0xFF769656),
     ),
        child: Stack(
       children: [
                    // Peça visível como imagem
   if (shouldShowPiece)
               LayoutBuilder(
         builder: (context, constraints) {
          final size = constraints.maxWidth * 0.8;
      return Center(
              child: Image.asset(
        _getPieceImagePath(piece!.type, piece.color),
         width: size,
           height: size,
 fit: BoxFit.contain,
           errorBuilder: (context, error, stackTrace) {
      return Text(
          _getPieceSymbolFallback(piece.type, piece.color),
            style: TextStyle(fontSize: size * 0.75),
   );
   },
      ),
    );
                 },
                ),
],
         ),
 ),
       ),
      );
  }),
     ),
          );
        }),
      ),
    );
  }

  String _getPieceImagePath(chess_lib.PieceType type, chess_lib.Color color) {
    final colorPrefix = color == chess_lib.Color.WHITE ? 'w' : 'b';
 final typeName = type.name.toLowerCase();
    
    // O pacote chess retorna apenas UMA LETRA para cada tipo!
    // k=King, q=Queen, r=Rook, b=Bishop, n=kNight, p=Pawn
    String pieceChar;
    switch (typeName) {
      case 'p':  // Pawn
        pieceChar = 'P';
        break;
   case 'n':  // kNight
        pieceChar = 'N';
        break;
      case 'b':  // Bishop
        pieceChar = 'B';
        break;
      case 'r':  // Rook
    pieceChar = 'R';
    break;
  case 'q':  // Queen
        pieceChar = 'Q';
        break;
      case 'k':  // King
        pieceChar = 'K';
        break;
      default:
        print('DEBUG _getPieceImagePath: TIPO DESCONHECIDO "$typeName"! Usando P como fallback');
        pieceChar = 'P';
    }
    
    return 'assets/pieces/$colorPrefix$pieceChar.png';
  }

  String _getPieceSymbolFallback(chess_lib.PieceType type, chess_lib.Color color) {
    final typeName = type.name.toLowerCase();
    final isWhite = color == chess_lib.Color.WHITE;

    // Usar String.fromCharCode com códigos Unicode (fallback)
  if (typeName == 'pawn') {
      return isWhite ? String.fromCharCode(0x2659) : String.fromCharCode(0x265F);
    } else if (typeName == 'knight') {
   return isWhite ? String.fromCharCode(0x2658) : String.fromCharCode(0x265E);
 } else if (typeName == 'bishop') {
    return isWhite ? String.fromCharCode(0x2657) : String.fromCharCode(0x265D);
    } else if (typeName == 'rook') {
      return isWhite ? String.fromCharCode(0x2656) : String.fromCharCode(0x265C);
    } else if (typeName == 'queen') {
   return isWhite ? String.fromCharCode(0x2655) : String.fromCharCode(0x265B);
    } else if (typeName == 'king') {
      return isWhite ? String.fromCharCode(0x2654) : String.fromCharCode(0x265A);
    }
    
    return '?';
  }

  List<chess_lib.Piece> _getOpponentPieces() {
    if (_chess == null || _game == null) {
      return [];
    }

    // Verificar se o jogo está ativo
    final isGameActive = _game!.status == 'active' || _game!.status == 'em_andamento';
    if (!isGameActive) {
      return [];
    }

    final myColorLetter = _myColor == 'white' ? chess_lib.Color.WHITE : chess_lib.Color.BLACK;
    final opponentColor = myColorLetter == chess_lib.Color.WHITE ? chess_lib.Color.BLACK : chess_lib.Color.WHITE;

    final pieces = <chess_lib.Piece>[];
    for (var rank = 0; rank < 8; rank++) {
      for (var file = 0; file < 8; file++) {
        final square = String.fromCharCode(97 + file) + (8 - rank).toString();
        final piece = _chess!.get(square);
        if (piece != null && piece.color == opponentColor) {
          pieces.add(piece);
        }
      }
    }

    // Ordenar por tipo
    pieces.sort((a, b) => _getPieceValue(a.type).compareTo(_getPieceValue(b.type)));
    return pieces;
  }

  int _getPieceValue(chess_lib.PieceType type) {
    switch (type) {
      case chess_lib.PieceType.KING:
        return 0;
      case chess_lib.PieceType.QUEEN:
        return 1;
      case chess_lib.PieceType.ROOK:
        return 2;
      case chess_lib.PieceType.BISHOP:
        return 3;
      case chess_lib.PieceType.KNIGHT:
        return 4;
      case chess_lib.PieceType.PAWN:
        return 5;
      default:
        return 6;
    }
  }

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty || _game == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.errorTitle)),
    body: Center(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
 children: [
           const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
              Text(_error.isNotEmpty ? _error : l10n.gameNotFound),
              const SizedBox(height: 16),
            ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
       child: Text(l10n.back),
  ),
        ],
          ),
     ),
      );
    }

    final opponent = _game!.whitePlayer.id == Provider.of<AuthProvider>(context, listen: false).user?.id
        ? _game!.blackPlayer
        : _game!.whitePlayer;

    final myColorText = _myColor == 'white' ? l10n.whitePieces : l10n.blackPieces;
    final turnColorText = _actualTurn == 'white' ? l10n.whitePieces : l10n.blackPieces;

    return Scaffold(
   appBar: AppBar(
        title: Text('${_game!.whitePlayer.username} vs ${_game!.blackPlayer.username}',
        style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
      icon: const Icon(Icons.refresh, size: 20),
    onPressed: _loadGame,
      tooltip: l10n.refresh,
 ),
        ],
   ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
       children: [
     // ✅ INFO COMPACTA no topo
       Card(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  child: Row(
   mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Text(
        l10n.youPlayAs(myColorText),
 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    ),
           Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
           decoration: BoxDecoration(
         color: _isMyTurn ? Colors.green : Colors.grey,
            borderRadius: BorderRadius.circular(12),
        ),
      child: Text(
     _isMyTurn ? l10n.yourTurn : l10n.waiting,
       style: const TextStyle(
      color: Colors.white,
    fontSize: 10,
  fontWeight: FontWeight.bold,
     ),
    ),
         ),
   Text(
        l10n.turn(turnColorText),
      style: TextStyle(
   fontSize: 12,
         color: _isMyTurn ? Colors.green : Colors.orange,
    ),
          ),
  ],
       ),
      ),
),  // ✅ CORRIGIDO: Fecha Card corretamente

     // ✅ HINT compacto (se jogo ativo)
            if (_game!.status == 'active' || _game!.status == 'em_andamento')
   Padding(
   padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(
    l10n.blindChessHint,
       style: const TextStyle(
  fontSize: 10,
       fontStyle: FontStyle.italic,
         color: Colors.blue,
   ),
  textAlign: TextAlign.center,
     ),
  ),

            // ✅ NOVO: Notificação persistente
     if (_lastNotification != null)
   Card(
   color: Colors.orange[100],
child: Padding(
    padding: const EdgeInsets.all(12),
        child: Row(
        children: [
       const Icon(Icons.info, color: Colors.orange, size: 20),
const SizedBox(width: 8),
    Expanded(
    child: Text(
       _lastNotification!,
        style: const TextStyle(
              fontWeight: FontWeight.bold,
     fontSize: 13,
     ),
        ),
    ),
   ],
     ),
),
              ),
 
 const SizedBox(height: 4),
            
          // ✅ LAYOUT HORIZONTAL: Tabuleiro QUADRADO centralizado + Peças
            Expanded(
 child: Row(
 children: [
         // ✅ TABULEIRO QUADRADO E CENTRALIZADO
Expanded(
         flex: 3,
             child: Center(  // ✅ NOVO: Centraliza o tabuleiro
            child: AspectRatio(  // ✅ NOVO: Garante que seja quadrado
     aspectRatio: 1,
    child: Card(
            child: Padding(
           padding: const EdgeInsets.all(4.0),
            child: _buildBoard(),
  ),
            ),
   ),
        ),
           ),
     
       const SizedBox(width: 8),
        
      // PEÇAS DO ADVERSÁRIO (coluna lateral)
     if (_game!.status == 'active' || _game!.status == 'em_andamento')
            Expanded(
          flex: 1,
           child: Card(
     child: Padding(
            padding: const EdgeInsets.all(8),
           child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
   children: [
        Text(
        l10n.opponentPieces(opponent.username),
    style: const TextStyle(
              fontWeight: FontWeight.bold,
   fontSize: 11,
              ),
       maxLines: 2,
         overflow: TextOverflow.ellipsis,
           ),
             const SizedBox(height: 8),
              Expanded(
        child: SingleChildScrollView(
         child: Wrap(
     spacing: 4,
    runSpacing: 4,
              children: _getOpponentPieces().map((piece) {
        return Container(
 width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[400]!),
         ),
        child: Padding(
 padding: const EdgeInsets.all(2.0),
           child: Image.asset(
   _getPieceImagePath(piece.type, piece.color),
           fit: BoxFit.contain,
   errorBuilder: (context, error, stackTrace) {
                 return Text(
      _getPieceSymbolFallback(piece.type, piece.color),
      style: const TextStyle(fontSize: 20),
    );
    },
           ),
   ),
          );
            }).toList(),
 ),
       ),
        ),
            ],
    ),
             ),
               ),
           ),
            ],
         ),
            ),

    const SizedBox(height: 8),
            
       // BOTÕES compactos
            Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
       ElevatedButton.icon(
        onPressed: _loadGame,
        icon: const Icon(Icons.refresh, size: 16),
   label: Text(l10n.refresh, style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
           ),
    ),
     ElevatedButton.icon(
          onPressed: () {
     showDialog(
    context: context,
 builder: (context) => AlertDialog(
 title: Text(l10n.resignTitle),
    content: Text(l10n.resignConfirm),
         actions: [
      TextButton(
                onPressed: () => Navigator.of(context).pop(),
  child: Text(l10n.cancel),
         ),
         TextButton(
       onPressed: () async {
          Navigator.of(context).pop();
          try {
              await _apiService.resignGame(widget.gameId);
     if (mounted) {
         Navigator.of(context).pop();
     }
       } catch (e) {
     _showSnackBar(l10n.errorMakingMove(e.toString()));
       }
                },
    child: Text(l10n.resign, style: const TextStyle(color: Colors.red)),
                ),
 ],
     ),
      );
            },
  icon: const Icon(Icons.flag, size: 16),
    label: Text(l10n.resign, style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
            foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
  ),
              ],
    ),
          ],
        ),
      ),
    );
  }
}
