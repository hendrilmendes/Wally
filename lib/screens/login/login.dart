// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:projectx/auth/auth.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:projectx/screens/home/home.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatelessWidget {
  final AuthService authService;

  const LoginScreen({required this.authService, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return _buildLandscapeLayout(context);
              } else {
                return _buildPortraitLayout(context);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top,
        ),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _buildBrandingSection(context, isPortrait: true),
                const Spacer(flex: 3),
                _buildActionsSection(context),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: _buildBrandingSection(context, isPortrait: false),
          ),
          const SizedBox(width: 48),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildActionsSection(context)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingSection(
    BuildContext context, {
    required bool isPortrait,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarRadius = isPortrait ? screenWidth * 0.18 : screenWidth * 0.09;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.transparent,
            backgroundImage: const AssetImage('assets/img/robot_photo.png'),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.appName,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isPortrait ? 36 : 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.homeLogin,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () async {
            final user = await authService.signInAnonymously();
            if (user != null && context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            l10n.temporaryAccess,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 16),
        _buildGlassmorphicButton(context, l10n, theme),
        const SizedBox(height: 24),
        _buildPrivacyPolicyText(context, l10n, theme),
      ],
    );
  }

  Widget _buildGlassmorphicButton(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: InkWell(
          onTap: () async {
            final user = await authService.signInWithGoogle();
            if (user != null && context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else {
              if (kDebugMode) print('Falha na autenticação');
            }
          },
          borderRadius: BorderRadius.circular(100.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(100.0),
              border: Border.all(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/img/google_logo.png',
                  width: 22,
                  height: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.googleLogin,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicyText(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${l10n.acceptTerms} ',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          TextSpan(
            text: l10n.privacy,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: theme.colorScheme.primary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                final url = Uri.parse(
                  'https://br-newsdroid.blogspot.com/p/politica-de-privacidade-wally.html',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                }
              },
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
