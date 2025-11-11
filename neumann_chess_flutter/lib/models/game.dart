import 'user.dart';

class Game {
  final String id;
  final User whitePlayer;
  final User blackPlayer;
  final User createdBy;
  final String status;
  final String? result;
  final String? winnerId;
  final String currentFen;
  final String currentTurn;
  final List<Move> moves;
  final bool isOpenChallenge;
  final bool accepted;
  final DateTime? startedAt;
  final DateTime? endedAt;

  Game({
    required this.id,
    required this.whitePlayer,
    required this.blackPlayer,
    required this.createdBy,
    required this.status,
    this.result,
    this.winnerId,
    required this.currentFen,
    required this.currentTurn,
    required this.moves,
    required this.isOpenChallenge,
    required this.accepted,
    this.startedAt,
    this.endedAt,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    // Helper para converter whitePlayer/blackPlayer/createdBy que podem ser String (ID) ou Map (objeto completo)
    User _parseUser(dynamic userData) {
      if (userData is String) {
        // Se for apenas o ID, criar User com dados mínimos
        return User(
          id: userData,
          username: 'Carregando...',
          email: '',
          stats: UserStats(gamesPlayed: 0, gamesWon: 0, gamesLost: 0, gamesDraw: 0),
        );
      } else if (userData is Map<String, dynamic>) {
        // Se for objeto completo, fazer parse normal
        return User.fromJson(userData);
      } else {
        // Fallback para dados vazios
        return User(
          id: '',
          username: 'Desconhecido',
          email: '',
          stats: UserStats(gamesPlayed: 0, gamesWon: 0, gamesLost: 0, gamesDraw: 0),
        );
      }
    }

    return Game(
      id: json['_id'] ?? json['id'] ?? '',
      whitePlayer: _parseUser(json['whitePlayer']),
      blackPlayer: _parseUser(json['blackPlayer']),
      createdBy: _parseUser(json['createdBy']),
      status: json['status'] ?? 'pendente',
      result: json['result'],
      winnerId: json['winnerId'],
      currentFen: json['currentFen'] ?? 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      currentTurn: json['currentTurn'] ?? 'white',
      moves: (json['moves'] as List?)?.map((m) => Move.fromJson(m)).toList() ?? [],
      isOpenChallenge: json['isOpenChallenge'] ?? false,
      accepted: json['accepted'] ?? false,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
    );
  }

  // ✅ NOVO: Método copyWith para criar cópias com campos modificados
  Game copyWith({
    String? id,
    User? whitePlayer,
    User? blackPlayer,
    User? createdBy,
    String? status,
    String? result,
    String? winnerId,
    String? currentFen,
    String? currentTurn,
    List<Move>? moves,
    bool? isOpenChallenge,
    bool? accepted,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return Game(
      id: id ?? this.id,
      whitePlayer: whitePlayer ?? this.whitePlayer,
      blackPlayer: blackPlayer ?? this.blackPlayer,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      result: result ?? this.result,
      winnerId: winnerId ?? this.winnerId,
      currentFen: currentFen ?? this.currentFen,
      currentTurn: currentTurn ?? this.currentTurn,
      moves: moves ?? this.moves,
      isOpenChallenge: isOpenChallenge ?? this.isOpenChallenge,
      accepted: accepted ?? this.accepted,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}

class Move {
  final String from;
  final String to;
  final String piece;
  final String? captured;
  final String? promotion;
  final String san;
  final DateTime timestamp;

  Move({
    required this.from,
    required this.to,
    required this.piece,
    this.captured,
    this.promotion,
    required this.san,
    required this.timestamp,
  });

  factory Move.fromJson(Map<String, dynamic> json) {
    return Move(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      piece: json['piece'] ?? '',
      captured: json['captured'],
      promotion: json['promotion'],
      san: json['san'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'piece': piece,
      'captured': captured,
      'promotion': promotion,
      'san': san,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
