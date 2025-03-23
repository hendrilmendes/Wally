import 'package:dynamic_color/dynamic_color.dart';
import 'package:feedback/feedback.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectx/auth/auth.dart';
import 'package:projectx/firebase_options.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:projectx/screens/home/home.dart';
import 'package:projectx/screens/login/login.dart';
import 'package:projectx/theme/theme.dart';
import 'package:projectx/updater/updater.dart';
import 'package:provider/provider.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização do Firebase e Crashlytics
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  runApp(
    BetterFeedback(
      theme: FeedbackThemeData.light(),
      darkTheme: FeedbackThemeData.dark(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalFeedbackLocalizationsDelegate(),
      ],
      localeOverride: const Locale('pt'),
      child: const MyApp(),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return ChangeNotifierProvider(
      create: (_) => ThemeModel(),
      child: Consumer<ThemeModel>(
        builder: (_, themeModel, __) {
          return DynamicColorBuilder(
            builder: (lightColorScheme, darkColorScheme) {
              if (!themeModel.isDynamicColorsEnabled) {
                lightColorScheme = null;
                darkColorScheme = null;
              }

              return MaterialApp(
                theme: ThemeData(
                  brightness: Brightness.light,
                  colorScheme: lightColorScheme?.copyWith(
                    primary:
                        themeModel.isDarkMode ? Colors.black : Colors.black,
                  ),
                  useMaterial3: true,
                  textTheme: Typography()
                      .black
                      .apply(fontFamily: GoogleFonts.openSans().fontFamily),
                  pageTransitionsTheme: PageTransitionsTheme(
                    builders: Map<TargetPlatform,
                        PageTransitionsBuilder>.fromIterable(
                      TargetPlatform.values,
                      value: (_) => const FadeForwardsPageTransitionsBuilder(),
                    ),
                  ),
                ),
                darkTheme: ThemeData(
                  brightness: Brightness.dark,
                  colorScheme: darkColorScheme?.copyWith(
                    primary:
                        themeModel.isDarkMode ? Colors.white : Colors.black,
                  ),
                  useMaterial3: true,
                  textTheme: Typography()
                      .white
                      .apply(fontFamily: GoogleFonts.openSans().fontFamily),
                  pageTransitionsTheme: PageTransitionsTheme(
                    builders: Map<TargetPlatform,
                        PageTransitionsBuilder>.fromIterable(
                      TargetPlatform.values,
                      value: (_) => const FadeForwardsPageTransitionsBuilder(),
                    ),
                  ),
                ),
                themeMode: _getThemeMode(themeModel.themeMode),
                debugShowCheckedModeBanner: false,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: _buildHome(authService),
                routes: {
                  '/login': (context) => LoginScreen(authService: authService),
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHome(AuthService authService) {
    return FutureBuilder<User?>(
      future: authService.currentUser(),
      builder: (context, snapshot) {
        Updater.checkUpdateApp(context);
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            return const HomeScreen();
          } else {
            return LoginScreen(authService: authService);
          }
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator.adaptive(),
            ),
          );
        }
      },
    );
  }
}