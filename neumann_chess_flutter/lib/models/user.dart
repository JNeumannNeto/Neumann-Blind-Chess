class User {
  final String id;
  final String username;
  final String email;
  final UserStats stats;

  User({
    required this.id,
    required this.username,
  required this.email,
    required this.stats,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      stats: UserStats.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'stats': stats.toJson(),
    };
  }
}

class UserStats {
  final int gamesPlayed;
  final int gamesWon;
  final int gamesLost;
  final int gamesDraw;

  UserStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.gamesDraw = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      gamesPlayed: json['gamesPlayed'] ?? 0,
      gamesWon: json['gamesWon'] ?? 0,
      gamesLost: json['gamesLost'] ?? 0,
      gamesDraw: json['gamesDraw'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'gamesLost': gamesLost,
      'gamesDraw': gamesDraw,
    };
  }
}
