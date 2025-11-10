import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Neumann Xadrez às Cegas'**
  String get appTitle;

  /// No description provided for @youPlayAs.
  ///
  /// In pt, this message translates to:
  /// **'Você joga com: {color}'**
  String youPlayAs(String color);

  /// No description provided for @whitePieces.
  ///
  /// In pt, this message translates to:
  /// **'Brancas'**
  String get whitePieces;

  /// No description provided for @blackPieces.
  ///
  /// In pt, this message translates to:
  /// **'Pretas'**
  String get blackPieces;

  /// No description provided for @yourTurn.
  ///
  /// In pt, this message translates to:
  /// **'SUA VEZ'**
  String get yourTurn;

  /// No description provided for @waiting.
  ///
  /// In pt, this message translates to:
  /// **'AGUARDANDO'**
  String get waiting;

  /// No description provided for @turn.
  ///
  /// In pt, this message translates to:
  /// **'Turno: {color}'**
  String turn(String color);

  /// No description provided for @blindChessHint.
  ///
  /// In pt, this message translates to:
  /// **'💡 Xadrez às Cegas: As peças do adversário estão ocultas!'**
  String get blindChessHint;

  /// No description provided for @opponentPieces.
  ///
  /// In pt, this message translates to:
  /// **'Peças de {username}:'**
  String opponentPieces(String username);

  /// No description provided for @refresh.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get refresh;

  /// No description provided for @resign.
  ///
  /// In pt, this message translates to:
  /// **'Desistir'**
  String get resign;

  /// No description provided for @resignTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desistir?'**
  String get resignTitle;

  /// No description provided for @resignConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Você tem certeza que deseja desistir desta partida?'**
  String get resignConfirm;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @gameFinished.
  ///
  /// In pt, this message translates to:
  /// **'Jogo Finalizado'**
  String get gameFinished;

  /// No description provided for @checkmate.
  ///
  /// In pt, this message translates to:
  /// **'Xeque-mate! {winner} venceram!'**
  String checkmate(String winner);

  /// No description provided for @stalemate.
  ///
  /// In pt, this message translates to:
  /// **'Empate por afogamento!'**
  String get stalemate;

  /// No description provided for @draw.
  ///
  /// In pt, this message translates to:
  /// **'Empate!'**
  String get draw;

  /// No description provided for @resigned.
  ///
  /// In pt, this message translates to:
  /// **'Jogo encerrado por desistência'**
  String get resigned;

  /// No description provided for @gameEnded.
  ///
  /// In pt, this message translates to:
  /// **'Jogo encerrado'**
  String get gameEnded;

  /// No description provided for @backToLobby.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao Lobby'**
  String get backToLobby;

  /// No description provided for @notYourTurn.
  ///
  /// In pt, this message translates to:
  /// **'Não é sua vez!'**
  String get notYourTurn;

  /// No description provided for @invalidMove.
  ///
  /// In pt, this message translates to:
  /// **'Movimento inválido'**
  String get invalidMove;

  /// No description provided for @errorMakingMove.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao fazer movimento: {error}'**
  String errorMakingMove(String error);

  /// No description provided for @errorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get errorTitle;

  /// No description provided for @gameNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Jogo não encontrado'**
  String get gameNotFound;

  /// No description provided for @back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get back;

  /// No description provided for @welcome.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo, {username}!'**
  String welcome(String username);

  /// No description provided for @games.
  ///
  /// In pt, this message translates to:
  /// **'Jogos'**
  String get games;

  /// No description provided for @victories.
  ///
  /// In pt, this message translates to:
  /// **'Vitórias'**
  String get victories;

  /// No description provided for @defeats.
  ///
  /// In pt, this message translates to:
  /// **'Derrotas'**
  String get defeats;

  /// No description provided for @draws.
  ///
  /// In pt, this message translates to:
  /// **'Empates'**
  String get draws;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
