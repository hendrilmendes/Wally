import 'package:dynamic_color/dynamic_color.dart';
import 'package:feedback/feedback.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart'; // Necessário para kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectx/auth/auth.dart';
import 'package:projectx/firebase_options.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:projectx/screens/home/home.dart';
import 'package:projectx/screens/login/login.dart';
import 'package:projectx/service/updater.dart';
import 'package:projectx/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await ShorebirdUpdater().checkForUpdate();
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeModel()),
        ChangeNotifierProvider(create: (_) => UpdateService()),
      ],
      child: BetterFeedback(
        theme: FeedbackThemeData.light(),
        darkTheme: FeedbackThemeData.dark(),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalFeedbackLocalizationsDelegate(),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

ThemeMode _getThemeMode(ThemeModeType mode) {
  switch (mode) {
    case ThemeModeType.light:
      return ThemeMode.light;
    case ThemeModeType.dark:
      return ThemeMode.dark;
    case ThemeModeType.system:
      return ThemeMode.system;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UpdateService>(
        context,
        listen: false,
      ).silentCheckForUpdates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModel>(
      builder: (_, themeModel, _) {
        return DynamicColorBuilder(
          builder: (lightColorScheme, darkColorScheme) {
            if (!themeModel.isDynamicColorsEnabled) {
              lightColorScheme = null;
              darkColorScheme = null;
            }
            return MaterialApp(
              theme: ThemeData(
                brightness: Brightness.light,
                colorScheme: lightColorScheme,
                useMaterial3: true,
                textTheme: Typography().black.apply(
                  fontFamily: GoogleFonts.openSans().fontFamily,
                ),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                colorScheme: darkColorScheme,
                useMaterial3: true,
                textTheme: Typography().white.apply(
                  fontFamily: GoogleFonts.openSans().fontFamily,
                ),
              ),
              themeMode: _getThemeMode(themeModel.themeMode),
              debugShowCheckedModeBanner: false,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: _buildHome(context),
              routes: {
                '/login': (context) => LoginScreen(authService: authService),
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHome(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          if (user == null) {
            return LoginScreen(authService: authService);
          }
          return const HomeScreen();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator.adaptive()),
        );
      },
    );
  }
}
