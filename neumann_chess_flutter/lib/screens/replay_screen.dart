import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../services/api_service.dart';
import '../models/game.dart';
import '../l10n/app_localizations.dart';

class ReplayScreen extends StatefulWidget {
  final String gameId;

  const ReplayScreen({super.key, required this.gameId});

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  final ApiService _apiService = ApiService();
  Game? _game;
  bool _isLoading = true;
  String _error = '';
  chess_lib.Chess? _chess;
  int _currentMoveIndex = -1;  // -1 = posição inicial

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    try {
   final game = await _apiService.getGame(widget.gameId);
   
   setState(() {
        _game = game;
      _isLoading = false;
        _chess = chess_lib.Chess();
        _currentMoveIndex = game.moves.length - 1;  // Começar no último lance
        _applyMovesUpToIndex(_currentMoveIndex);
      });
    } catch (e) {
      setState(() {
      _error = e.toString();
     _isLoading = false;
      });
    }
  }

  void _applyMovesUpToIndex(int index) {
    _chess = chess_lib.Chess();  // Reset ao início
    
    if (index >= 0 && _game != null) {
      for (var i = 0; i <= index && i < _game!.moves.length; i++) {
        final move = _game!.moves[i];
  _chess!.move({'from': move.from, 'to': move.to, 'promotion': move.promotion});
      }
    }
  }

  void _goToStart() {
    setState(() {
      _currentMoveIndex = -1;
      _chess = chess_lib.Chess();
  });
  }

  void _goToPrevious() {
    if (_currentMoveIndex >= 0) {
      setState(() {
   _currentMoveIndex--;
    _applyMovesUpToIndex(_currentMoveIndex);
      });
}
  }

  void _goToNext() {
    if (_game != null && _currentMoveIndex < _game!.moves.length - 1) {
   setState(() {
        _currentMoveIndex++;
        _applyMovesUpToIndex(_currentMoveIndex);
      });
    }
  }

  void _goToEnd() {
    if (_game != null) {
      setState(() {
        _currentMoveIndex = _game!.moves.length - 1;
        _applyMovesUpToIndex(_currentMoveIndex);
   });
    }
  }

  Widget _buildBoard() {
    if (_chess == null) return const CircularProgressIndicator();

    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    return AspectRatio(
      aspectRatio: 1,
   child: Column(
        children: List.generate(8, (rankIndex) {
          final rank = ranks[rankIndex];
  return Expanded(
          child: Row(
         children: List.generate(8, (fileIndex) {
        final file = files[fileIndex];
    final square = '$file$rank';
    final isLight = (fileIndex + rankIndex) % 2 == 0;
       final piece = _chess!.get(square);

  return Expanded(
        child: Container(
        decoration: BoxDecoration(
             color: isLight
       ? const Color(0xFFEEEED2)
         : const Color(0xFF769656),
              ),
         child: piece != null
     ? LayoutBuilder(
   builder: (context, constraints) {
          final size = constraints.maxWidth * 0.8;
return Center(
       child: Image.asset(
     _getPieceImagePath(piece.type, piece.color),
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
           )
     : null,
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
    
    String pieceChar;
    switch (typeName) {
      case 'p':
        pieceChar = 'P';
        break;
      case 'n':
      pieceChar = 'N';
        break;
case 'b':
        pieceChar = 'B';
   break;
      case 'r':
        pieceChar = 'R';
        break;
      case 'q':
   pieceChar = 'Q';
        break;
      case 'k':
        pieceChar = 'K';
        break;
      default:
        pieceChar = 'P';
    }
    
    return 'assets/pieces/$colorPrefix$pieceChar.png';
  }

  String _getPieceSymbolFallback(chess_lib.PieceType type, chess_lib.Color color) {
    final typeName = type.name.toLowerCase();
    final isWhite = color == chess_lib.Color.WHITE;

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

    return Scaffold(
      appBar: AppBar(
        title: Text('${_game!.whitePlayer.username} vs ${_game!.blackPlayer.username}'),
      ),
  body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Info do jogo
         Card(
          child: Padding(
      padding: const EdgeInsets.all(16),
     child: Column(
           children: [
    Text(
          'Replay - ${_game!.status}',
           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
 ),
              const SizedBox(height: 8),
                 Text(
     'Lance ${_currentMoveIndex + 1} de ${_game!.moves.length}',
           style: const TextStyle(fontSize: 14, color: Colors.grey),
         ),
        ],
     ),
   ),
      ),
       
     const SizedBox(height: 16),
    
      // Tabuleiro centralizado
            Expanded(
child: Center(
   child: AspectRatio(
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
   
            const SizedBox(height: 16),
       
     // Controles de navegação
          Card(
        child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
    IconButton(
 onPressed: _currentMoveIndex > -1 ? _goToStart : null,
      icon: const Icon(Icons.skip_previous),
        tooltip: 'Início',
  iconSize: 32,
),
      IconButton(
   onPressed: _currentMoveIndex >= 0 ? _goToPrevious : null,
       icon: const Icon(Icons.chevron_left),
      tooltip: 'Anterior',
   iconSize: 32,
                 ),
   IconButton(
  onPressed: _game != null && _currentMoveIndex < _game!.moves.length - 1
  ? _goToNext
   : null,
        icon: const Icon(Icons.chevron_right),
       tooltip: 'Próximo',
  iconSize: 32,
         ),
        IconButton(
          onPressed: _game != null && _currentMoveIndex < _game!.moves.length - 1
          ? _goToEnd
           : null,
 icon: const Icon(Icons.skip_next),
            tooltip: 'Fim',
    iconSize: 32,
      ),
        ],
      ),
        ),
       ),
     
            const SizedBox(height: 16),
            
     // Botão voltar ao lobby
       ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
     icon: const Icon(Icons.arrow_back),
       label: Text(l10n.backToLobby),
            style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  ),
         ),
          ],
        ),
      ),
    );
  }
}
