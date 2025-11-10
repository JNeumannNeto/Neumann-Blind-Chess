import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../services/api_service.dart';
import '../models/game.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';  // ✅ MUDOU: Caminho correto onde foi gerado

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
  Timer? _pollingTimer;  // Timer para polling
  String? _actualTurn;  // Turno real detectado do FEN

  @override
  void initState() {
    super.initState();
    _loadGame();
    _startPolling();  // Iniciar polling
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();  // Cancelar timer ao sair
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
      final game = await _apiService.getGame(widget.gameId);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id;

      print('DEBUG _loadGame: game.currentTurn=${game.currentTurn}, currentUserId=$currentUserId');
      print('DEBUG _loadGame: whitePlayer.id=${game.whitePlayer.id}, blackPlayer.id=${game.blackPlayer.id}');

      // Criar instância temporária do chess para ler o turno do FEN
      final tempChess = chess_lib.Chess();
      if (game.currentFen.isNotEmpty) {
        tempChess.load(game.currentFen);
      }
      
      // Detectar o turno REAL do FEN (não do game.currentTurn que está bugado)
      final actualTurn = tempChess.turn == chess_lib.Color.WHITE ? 'white' : 'black';
      print('DEBUG _loadGame: Turno REAL detectado do FEN: $actualTurn');

      String? detectedColor;
      bool detectedIsMyTurn = false;

      // Determinar a cor do jogador atual
      if (currentUserId == game.whitePlayer.id) {
        detectedColor = 'white';
        detectedIsMyTurn = actualTurn == 'white';  // Usar turno do FEN
        print('DEBUG _loadGame: Sou BRANCAS, minha vez? $detectedIsMyTurn');
      } else if (currentUserId == game.blackPlayer.id) {
        detectedColor = 'black';
        detectedIsMyTurn = actualTurn == 'black';  // Usar turno do FEN
        print('DEBUG _loadGame: Sou PRETAS, minha vez? $detectedIsMyTurn');
  }

setState(() {
  _game = game;
        _isLoading = false;
  _myColor = detectedColor;
        _isMyTurn = detectedIsMyTurn;
 _actualTurn = actualTurn;  // Salvar turno real

     // Criar instância do chess com a posição atual
 _chess = chess_lib.Chess();
        if (game.currentFen.isNotEmpty) {
          _chess!.load(game.currentFen);
          print('DEBUG _loadGame: FEN carregado: ${game.currentFen}');
    print('DEBUG _loadGame: Turno do tabuleiro: ${_chess!.turn}');
    }
      });
    } catch (e) {
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
    
    final l10n = AppLocalizations.of(context)!;  // ✅ NOVO: Pegar traduções
    
    if (!_isMyTurn || _chess == null) {
      print('DEBUG: Movimento bloqueado no _makeMove');
      _showSnackBar(l10n.notYourTurn);  // ✅ TRADUZIDO
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
        _showSnackBar(l10n.invalidMove);  // ✅ TRADUZIDO
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
      print('DEBUG: updatedGame.currentTurn = ${updatedGame.currentTurn}');
      print('DEBUG: _myColor = $_myColor');
  print('DEBUG: Calculando _isMyTurn: ${updatedGame.currentTurn} == $_myColor ?');
      
      final newIsMyTurn = updatedGame.currentTurn == _myColor;
      print('DEBUG: Novo _isMyTurn = $newIsMyTurn');
      
   setState(() {
    _game = updatedGame;
        _isMyTurn = newIsMyTurn;
        _selectedSquare = null;
        _legalMoves = [];

        if (updatedGame.currentFen.isNotEmpty) {
          _chess!.load(updatedGame.currentFen);
    }
  
        print('DEBUG: Estado atualizado - _isMyTurn=$_isMyTurn, _game.currentTurn=${_game!.currentTurn}');
      });

      final isGameActive = updatedGame.status == 'active' || updatedGame.status == 'em_andamento';
      if (!isGameActive) {
    _showGameEndDialog();
      }
    } catch (e) {
      print('DEBUG ERRO em _makeMove: $e');
      _showSnackBar(l10n.errorMakingMove(e.toString()));  // ✅ TRADUZIDO
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

  void _showGameEndDialog() {
    final l10n = AppLocalizations.of(context)!;  // ✅ NOVO: Pegar traduções
    
    String message = '';
    switch (_game!.status) {
      case 'checkmate':
      final winner = _game!.currentTurn == 'white' 
       ? l10n.blackPieces  // ✅ TRADUZIDO
       : l10n.whitePieces;  // ✅ TRADUZIDO
   message = l10n.checkmate(winner);  // ✅ TRADUZIDO
     break;
      case 'stalemate':
        message = l10n.stalemate;  // ✅ TRADUZIDO
        break;
      case 'draw':
        message = l10n.draw;  // ✅ TRADUZIDO
        break;
      case 'resigned':
        message = l10n.resigned;  // ✅ TRADUZIDO
  break;
      default:
        message = l10n.gameEnded;  // ✅ TRADUZIDO (usando chave existente)
    }

    showDialog(
 context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
      title: Text(l10n.gameFinished),  // ✅ TRADUZIDO
      content: Text(message),
        actions: [
          TextButton(
   onPressed: () {
    Navigator.of(context).pop();
         Navigator.of(context).pop();
            },
 child: Text(l10n.backToLobby),  // ✅ TRADUZIDO
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
                final isLegalMove = _legalMoves.contains(square);

                // Determinar cor do jogador
                final myColorLetter = _myColor == 'white' ? chess_lib.Color.WHITE : chess_lib.Color.BLACK;

                // Lógica para mostrar ou ocultar peças
                bool shouldShowPiece = false;

                if (piece != null) {
                  if (_myColor == null) {
                    shouldShowPiece = true;
                  } else if (piece.color == myColorLetter) {
                    shouldShowPiece = true;
                  } else {
                    final isGameActive = _game!.status == 'active' || _game!.status == 'em_andamento';
                    shouldShowPiece = !isGameActive;
                  }
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onSquareTapped(square),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.yellow.withOpacity(0.5)
                            : isLegalMove
                                ? Colors.green.withOpacity(0.3)
                                : isLight
                                    ? const Color(0xFFEEEED2)
                                    : const Color(0xFF769656),
                        border: isLegalMove
                            ? Border.all(color: Colors.green, width: 2)
                            : null,
                      ),
                      child: Stack(
                        children: [
                          // Indicador de movimento legal
                          if (isLegalMove && piece == null)
                            Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          // Peça visível como imagem
                          if (shouldShowPiece)
       LayoutBuilder(
builder: (context, constraints) {
    // Usar 80% do menor lado do quadrado para a imagem
    final size = constraints.maxWidth * 0.8;
            return Center(
      child: Image.asset(
               _getPieceImagePath(piece!.type, piece.color),
            width: size,
      height: size,
                 fit: BoxFit.contain,
   errorBuilder: (context, error, stackTrace) {
      // Fallback para símbolo Unicode se imagem não carregar
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
    final l10n = AppLocalizations.of(context)!;  // ✅ NOVO: Pegar traduções
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
 }

  if (_error.isNotEmpty || _game == null) {
      return Scaffold(
   appBar: AppBar(title: Text(l10n.errorTitle)),  // ✅ TRADUZIDO
        body: Center(
   child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
children: [
      const Icon(Icons.error, size: 64, color: Colors.red),
 const SizedBox(height: 16),
    Text(_error.isNotEmpty ? _error : l10n.gameNotFound),  // ✅ TRADUZIDO
          const SizedBox(height: 16),
          ElevatedButton(
    onPressed: () => Navigator.of(context).pop(),
  child: Text(l10n.back),  // ✅ TRADUZIDO
    ),
    ],
    ),
 ),
      );
    }

    final opponent = _game!.whitePlayer.id == Provider.of<AuthProvider>(context, listen: false).user?.id
        ? _game!.blackPlayer
   : _game!.whitePlayer;

 final myColorText = _myColor == 'white' ? l10n.whitePieces : l10n.blackPieces;  // ✅ TRADUZIDO
    final turnColorText = _actualTurn == 'white' ? l10n.whitePieces : l10n.blackPieces;  // ✅ TRADUZIDO

    return Scaffold(
      appBar: AppBar(
   title: Text('${_game!.whitePlayer.username} vs ${_game!.blackPlayer.username}'),
   actions: [
          IconButton(
       icon: const Icon(Icons.refresh),
       onPressed: _loadGame,
      tooltip: l10n.refresh,  // ✅ TRADUZIDO
 ),
      ],
      ),
      body: SingleChildScrollView(
   child: Padding(
padding: const EdgeInsets.all(16.0),
  child: Column(
        children: [
   Card(
         child: Padding(
          padding: const EdgeInsets.all(16),
       child: Column(
        children: [
       Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
  Text(
  l10n.youPlayAs(myColorText),  // ✅ TRADUZIDO
             style: const TextStyle(fontWeight: FontWeight.bold),
   ),
    Container(
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
         decoration: BoxDecoration(
        color: _isMyTurn ? Colors.green : Colors.grey,
       borderRadius: BorderRadius.circular(20),
         ),
      child: Text(
      _isMyTurn ? l10n.yourTurn : l10n.waiting,  // ✅ TRADUZIDO
          style: const TextStyle(
        color: Colors.white,
    fontWeight: FontWeight.bold),
        ),
          ),
      ],
     ),
          const SizedBox(height: 8),
         Text(
       l10n.turn(turnColorText),  // ✅ TRADUZIDO
     style: TextStyle(
            color: _isMyTurn ? Colors.green : Colors.orange,
     ),
       ),
  if (_game!.status == 'active' || _game!.status == 'em_andamento') ...[
       const SizedBox(height: 8),
          Text(
     l10n.blindChessHint,  // ✅ TRADUZIDO
   style: const TextStyle(
              fontSize: 12,
   fontStyle: FontStyle.italic,
 color: Colors.blue,
           ),
    textAlign: TextAlign.center,
        ),
     ],
    ],
              ),
            ),
    ),
     const SizedBox(height: 16),
 Card(
    child: Padding(
     padding: const EdgeInsets.all(8.0),
        child: _buildBoard(),
        ),
          ),
const SizedBox(height: 16),
     if (_game!.status == 'active' || _game!.status == 'em_andamento')
      Card(
      child: Padding(
padding: const EdgeInsets.all(16),
        child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
       children: [
    Text(
      l10n.opponentPieces(opponent.username),  // ✅ TRADUZIDO
              style: const TextStyle(
     fontWeight: FontWeight.bold,
      fontSize: 16,
       ),
     ),
       const SizedBox(height: 12),
      Wrap(
      spacing: 8,
        runSpacing: 8,
        children: _getOpponentPieces().map((piece) {
      return Container(
    width: 45,
           height: 45,
decoration: BoxDecoration(
   color: Colors.grey[200],
       borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
    ),
            child: Padding(
       padding: const EdgeInsets.all(4.0),
  child: Image.asset(
       _getPieceImagePath(piece.type, piece.color),
   fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
       return Text(
_getPieceSymbolFallback(piece.type, piece.color),
       style: const TextStyle(fontSize: 28),
             );
},
    ),
      ),
   );
}).toList(),
   ),
       ],
      ),
       ),
          ),
    const SizedBox(height: 16),
       Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
       ElevatedButton.icon(
       onPressed: _loadGame,
   icon: const Icon(Icons.refresh),
    label: Text(l10n.refresh),  // ✅ TRADUZIDO
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
  icon: const Icon(Icons.flag),
    label: Text(l10n.resign),
 style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
 foregroundColor: Colors.white,
   ),
      ),
            ],  // Fecha children do Row
 ),  // Fecha Row
       const SizedBox(height: 16),
        ],  // Fecha children do Column principal
      ),  // Fecha Column
    ),  // Fecha Padding
    ),  // Fecha SingleChildScrollView (body)
    );  // Fecha Scaffold
  }  // Fecha método build
}  // Fecha classe _GameScreenState
