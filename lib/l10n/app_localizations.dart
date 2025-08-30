import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// No description provided for @appName.
  ///
  /// In pt, this message translates to:
  /// **'Wally'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get about;

  /// No description provided for @ok.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @copyright.
  ///
  /// In pt, this message translates to:
  /// **'Todos os direitos reservados'**
  String get copyright;

  /// No description provided for @version.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get version;

  /// No description provided for @privacy.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade'**
  String get privacy;

  /// No description provided for @sourceCode.
  ///
  /// In pt, this message translates to:
  /// **'Código Fonte'**
  String get sourceCode;

  /// No description provided for @sourceCodeSub.
  ///
  /// In pt, this message translates to:
  /// **'Todo o meu cerebro, ou melhor, meu código fonte está disponível no GitHub'**
  String get sourceCodeSub;

  /// No description provided for @openSource.
  ///
  /// In pt, this message translates to:
  /// **'Licenças de Código Aberto'**
  String get openSource;

  /// No description provided for @openSourceSub.
  ///
  /// In pt, this message translates to:
  /// **'Eu fui construído com base nestas fantásticas ferramentas de código aberto.'**
  String get openSourceSub;

  /// No description provided for @theme.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeSub.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o tema que mais combina com você'**
  String get themeSub;

  /// No description provided for @themeSelect.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o Tema'**
  String get themeSelect;

  /// No description provided for @darkMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo Escuro'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo Claro'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In pt, this message translates to:
  /// **'Padrão do Sistema'**
  String get systemMode;

  /// No description provided for @dynamicColors.
  ///
  /// In pt, this message translates to:
  /// **'Dynamic Colors'**
  String get dynamicColors;

  /// No description provided for @dynamicColorsSub.
  ///
  /// In pt, this message translates to:
  /// **'O Dynamic Colors proporciona uma interface agradável de acordo com o seu papel de parede'**
  String get dynamicColorsSub;

  /// No description provided for @support.
  ///
  /// In pt, this message translates to:
  /// **'Suporte'**
  String get support;

  /// No description provided for @supportSub.
  ///
  /// In pt, this message translates to:
  /// **'Encontrou um bug ou deseja sugerir algo?'**
  String get supportSub;

  /// No description provided for @aboutSub.
  ///
  /// In pt, this message translates to:
  /// **'Um pouco mais sobre o app'**
  String get aboutSub;

  /// No description provided for @newUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Nova versão disponível'**
  String get newUpdate;

  /// No description provided for @news.
  ///
  /// In pt, this message translates to:
  /// **'Novidades:'**
  String get news;

  /// No description provided for @after.
  ///
  /// In pt, this message translates to:
  /// **'DEPOIS'**
  String get after;

  /// No description provided for @download.
  ///
  /// In pt, this message translates to:
  /// **'BAIXAR'**
  String get download;

  /// No description provided for @noUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma atualização disponível'**
  String get noUpdate;

  /// No description provided for @noUpdateSub.
  ///
  /// In pt, this message translates to:
  /// **'Tudo em dias parceiro'**
  String get noUpdateSub;

  /// No description provided for @alreadyReviewed.
  ///
  /// In pt, this message translates to:
  /// **'Você já avaliou o app'**
  String get alreadyReviewed;

  /// No description provided for @toType.
  ///
  /// In pt, this message translates to:
  /// **'Digite algo...'**
  String get toType;

  /// No description provided for @wallyWelcome.
  ///
  /// In pt, this message translates to:
  /// **'Wally na área! O que vamos resolver hoje?'**
  String get wallyWelcome;

  /// No description provided for @weather.
  ///
  /// In pt, this message translates to:
  /// **'Clima'**
  String get weather;

  /// No description provided for @weatherTo.
  ///
  /// In pt, this message translates to:
  /// **'Tempo em'**
  String get weatherTo;

  /// No description provided for @newsdroidApp.
  ///
  /// In pt, this message translates to:
  /// **'News-Droid'**
  String get newsdroidApp;

  /// No description provided for @tarefasApp.
  ///
  /// In pt, this message translates to:
  /// **'Tá na Lista'**
  String get tarefasApp;

  /// No description provided for @incrementText.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar Texto'**
  String get incrementText;

  /// No description provided for @decrementText.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir Texto'**
  String get decrementText;

  /// No description provided for @shared.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get shared;

  /// No description provided for @downloadApp.
  ///
  /// In pt, this message translates to:
  /// **'Veja no app'**
  String get downloadApp;

  /// No description provided for @connectingServer.
  ///
  /// In pt, this message translates to:
  /// **'Conectando ao servidor...'**
  String get connectingServer;

  /// No description provided for @error.
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get error;

  /// No description provided for @errorUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível verificar atualizações.'**
  String get errorUpdate;

  /// No description provided for @homeLogin.
  ///
  /// In pt, this message translates to:
  /// **'Que bom ver por aqui!\nVocê pode fazer login para acessar mais recursos.'**
  String get homeLogin;

  /// No description provided for @googleLogin.
  ///
  /// In pt, this message translates to:
  /// **'Login com Google'**
  String get googleLogin;

  /// No description provided for @desconect.
  ///
  /// In pt, this message translates to:
  /// **'Desconectar'**
  String get desconect;

  /// No description provided for @acceptTerms.
  ///
  /// In pt, this message translates to:
  /// **'Ao continuar, você concorda com a nossa '**
  String get acceptTerms;

  /// No description provided for @wallyWelcomeAbout.
  ///
  /// In pt, this message translates to:
  /// **'Olá! Sou Wally. Fico feliz que queira saber mais sobre mim. O que você gostaria de descobrir?'**
  String get wallyWelcomeAbout;

  /// No description provided for @supportAndFeedback.
  ///
  /// In pt, this message translates to:
  /// **'Suporte e Feedback'**
  String get supportAndFeedback;

  /// No description provided for @appearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get appearance;

  /// No description provided for @temporaryAccess.
  ///
  /// In pt, this message translates to:
  /// **'Modo de Acesso Temporário'**
  String get temporaryAccess;

  /// No description provided for @chat.
  ///
  /// In pt, this message translates to:
  /// **'Conversar'**
  String get chat;

  /// No description provided for @typeSomething.
  ///
  /// In pt, this message translates to:
  /// **'Digite algo...'**
  String get typeSomething;

  /// No description provided for @guestMode.
  ///
  /// In pt, this message translates to:
  /// **'Modo Convidado'**
  String get guestMode;

  /// No description provided for @login.
  ///
  /// In pt, this message translates to:
  /// **'Fazer Login'**
  String get login;

  /// No description provided for @whoCreatedYou.
  ///
  /// In pt, this message translates to:
  /// **'Quem te criou?'**
  String get whoCreatedYou;

  /// No description provided for @whatIsYourVersion.
  ///
  /// In pt, this message translates to:
  /// **'Qual é a sua versão?'**
  String get whatIsYourVersion;

  /// No description provided for @creatorResponse.
  ///
  /// In pt, this message translates to:
  /// **'Eu fui criado por um cara chamado Hendril Mendes,\nele e apaixonado por tecnologia e inovação'**
  String get creatorResponse;

  /// No description provided for @seeGitHub.
  ///
  /// In pt, this message translates to:
  /// **'Veja no GitHub'**
  String get seeGitHub;

  /// No description provided for @openRepository.
  ///
  /// In pt, this message translates to:
  /// **'Abrir Repositório'**
  String get openRepository;

  /// No description provided for @seeLicenses.
  ///
  /// In pt, this message translates to:
  /// **'Veja Licenças'**
  String get seeLicenses;

  /// No description provided for @privacyPolicyResponse.
  ///
  /// In pt, this message translates to:
  /// **'Nossa política de privacidade garante que suas informações pessoais não serão compartilhadas com terceiros sem o seu consentimento explícito.'**
  String get privacyPolicyResponse;

  /// No description provided for @seePolicy.
  ///
  /// In pt, this message translates to:
  /// **'Veja a Política de Privacidade'**
  String get seePolicy;

  /// No description provided for @seeChangelog.
  ///
  /// In pt, this message translates to:
  /// **'Veja o Changelog'**
  String get seeChangelog;

  /// No description provided for @versionResponse.
  ///
  /// In pt, this message translates to:
  /// **'Atualmente estou na versão {version} e continuo recebendo melhorias para te ajudar cada vez mais.'**
  String versionResponse(String version);

  /// No description provided for @hopeIHelped.
  ///
  /// In pt, this message translates to:
  /// **'Fico feliz em ajudar, até a próxima :)'**
  String get hopeIHelped;

  /// No description provided for @pendants.
  ///
  /// In pt, this message translates to:
  /// **'Pendentes'**
  String get pendants;

  /// No description provided for @completed.
  ///
  /// In pt, this message translates to:
  /// **'Concluídas'**
  String get completed;

  /// No description provided for @tasks.
  ///
  /// In pt, this message translates to:
  /// **'Tarefas'**
  String get tasks;

  /// No description provided for @notes.
  ///
  /// In pt, this message translates to:
  /// **'Anotações'**
  String get notes;

  /// No description provided for @noTask.
  ///
  /// In pt, this message translates to:
  /// **'Não há Tarefas'**
  String get noTask;

  /// No description provided for @noNotes.
  ///
  /// In pt, this message translates to:
  /// **'Não há Anotações'**
  String get noNotes;

  /// No description provided for @logout.
  ///
  /// In pt, this message translates to:
  /// **'Desconectar'**
  String get logout;

  /// No description provided for @account.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get account;

  /// No description provided for @add.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get add;
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
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
