// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Neumann Xadrez às Cegas';

  @override
  String youPlayAs(String color) {
    return 'Você joga com: $color';
  }

  @override
  String get whitePieces => 'Brancas';

  @override
  String get blackPieces => 'Pretas';

  @override
  String get yourTurn => 'SUA VEZ';

  @override
  String get waiting => 'AGUARDANDO';

  @override
  String turn(String color) {
    return 'Turno: $color';
  }

  @override
  String get blindChessHint =>
      '💡 Xadrez às Cegas: As peças do adversário estão ocultas!';

  @override
  String opponentPieces(String username) {
    return 'Peças de $username:';
  }

  @override
  String get refresh => 'Atualizar';

  @override
  String get resign => 'Desistir';

  @override
  String get resignTitle => 'Desistir?';

  @override
  String get resignConfirm =>
      'Você tem certeza que deseja desistir desta partida?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get gameFinished => 'Jogo Finalizado';

  @override
  String checkmate(String winner) {
    return 'Xeque-mate! $winner venceram!';
  }

  @override
  String get stalemate => 'Empate por afogamento!';

  @override
  String get draw => 'Empate!';

  @override
  String get resigned => 'Jogo encerrado por desistência';

  @override
  String get gameEnded => 'Jogo encerrado';

  @override
  String get backToLobby => 'Voltar ao Lobby';

  @override
  String get notYourTurn => 'Não é sua vez!';

  @override
  String get invalidMove => 'Movimento inválido';

  @override
  String errorMakingMove(String error) {
    return 'Erro ao fazer movimento: $error';
  }

  @override
  String get errorTitle => 'Erro';

  @override
  String get gameNotFound => 'Jogo não encontrado';

  @override
  String get back => 'Voltar';

  @override
  String welcome(String username) {
    return 'Bem-vindo, $username!';
  }

  @override
  String get games => 'Jogos';

  @override
  String get victories => 'Vitórias';

  @override
  String get defeats => 'Derrotas';

  @override
  String get draws => 'Empates';

  @override
  String pieceCaptured(String piece, String color) {
    return 'Desaparece $piece $color!';
  }

  @override
  String get kingInCheck => 'Rei em xeque!';

  @override
  String get pawnPromoted => 'Peão promovido a Dama!';

  @override
  String get piecePawn => 'peão';

  @override
  String get pieceKnight => 'cavalo';

  @override
  String get pieceBishop => 'bispo';

  @override
  String get pieceRook => 'torre';

  @override
  String get pieceQueen => 'dama';

  @override
  String get pieceKing => 'rei';

  @override
  String get colorWhite => 'branco';

  @override
  String get colorBlack => 'preto';
}
