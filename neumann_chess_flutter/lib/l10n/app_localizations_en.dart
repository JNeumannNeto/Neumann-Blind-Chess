// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Neumann Blind Chess';

  @override
  String youPlayAs(String color) {
    return 'You play as: $color';
  }

  @override
  String get whitePieces => 'White';

  @override
  String get blackPieces => 'Black';

  @override
  String get yourTurn => 'YOUR TURN';

  @override
  String get waiting => 'WAITING';

  @override
  String turn(String color) {
    return 'Turn: $color';
  }

  @override
  String get blindChessHint => '💡 Blind Chess: Opponent pieces are hidden!';

  @override
  String opponentPieces(String username) {
    return '$username\'s pieces:';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get resign => 'Resign';

  @override
  String get resignTitle => 'Resign?';

  @override
  String get resignConfirm => 'Are you sure you want to resign?';

  @override
  String get cancel => 'Cancel';

  @override
  String get gameFinished => 'Game Finished';

  @override
  String checkmate(String winner) {
    return 'Checkmate! $winner won!';
  }

  @override
  String get stalemate => 'Stalemate!';

  @override
  String get draw => 'Draw!';

  @override
  String get resigned => 'Game ended by resignation';

  @override
  String get gameEnded => 'Game ended';

  @override
  String get backToLobby => 'Back to Lobby';

  @override
  String get notYourTurn => 'Not your turn!';

  @override
  String get invalidMove => 'Invalid move';

  @override
  String errorMakingMove(String error) {
    return 'Error making move: $error';
  }

  @override
  String get errorTitle => 'Error';

  @override
  String get gameNotFound => 'Game not found';

  @override
  String get back => 'Back';

  @override
  String welcome(String username) {
    return 'Welcome, $username!';
  }

  @override
  String get games => 'Games';

  @override
  String get victories => 'Victories';

  @override
  String get defeats => 'Defeats';

  @override
  String get draws => 'Draws';
}
