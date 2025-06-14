// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projectx/auth/auth.dart'; // Importe seu AuthService
import 'package:projectx/l10n/app_localizations.dart';
import 'package:projectx/screens/login/login.dart'; // Importe sua LoginScreen
import 'package:projectx/theme/theme.dart';
import 'package:projectx/widgets/settings/about.dart';
import 'package:projectx/widgets/settings/dynamic_colors.dart';
import 'package:projectx/widgets/settings/review.dart';
import 'package:projectx/widgets/settings/support.dart';
import 'package:projectx/widgets/settings/theme.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isAndroid12 = false;

  late final ScrollController _scrollController;
  double _headerContentOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _checkAndroidVersion();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    const fadeEndOffset = 100.0;
    final offset = _scrollController.offset;
    final newOpacity = (1.0 - (offset / fadeEndOffset)).clamp(0.0, 1.0);

    if (newOpacity != _headerContentOpacity) {
      setState(() {
        _headerContentOpacity = newOpacity;
      });
    }
  }

  Future<void> _checkAndroidVersion() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (mounted) {
        setState(() {
          _isAndroid12 = androidInfo.version.sdkInt >= 31;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final themeModel = Provider.of<ThemeModel>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 220.0,
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 16.0),
                collapseMode: CollapseMode.pin,
                title: Text(
                  l10n.settings,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    // O título só aparece quando o header está quase recolhido
                    color: theme.colorScheme.onSurface.withOpacity(
                      1.0 - _headerContentOpacity,
                    ),
                  ),
                ),
                background: _buildUserInfoHeader(theme, _headerContentOpacity),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_user?.isAnonymous ?? true)
                    Center(
                      child: FilledButton.tonal(
                        onPressed: () async {
                          await AuthService().signOut();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    LoginScreen(authService: AuthService()),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        child: Text(l10n.login),
                      ),
                    ),
                  _buildSectionTitle(l10n.appearance, theme),
                  _glassMorphicWrapper(
                    child: ThemeSettings(themeModel: themeModel),
                  ),
                  if (_isAndroid12)
                    _glassMorphicWrapper(child: const DynamicColorsSettings()),
                  const SizedBox(height: 24),
                  _buildSectionTitle(l10n.supportAndFeedback, theme),
                  _glassMorphicWrapper(child: buildReviewSettings(context)),
                  _glassMorphicWrapper(child: buildSupportSettings(context)),
                  const SizedBox(height: 24),
                  _buildSectionTitle(l10n.about, theme),
                  _glassMorphicWrapper(child: buildAboutSettings(context)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE CONSTRUÇÃO DA UI ---

  // MÉTODO PRINCIPAL DO CABEÇALHO - AGORA ELE DELEGA O CONTEÚDO
  Widget _buildUserInfoHeader(ThemeData theme, double contentOpacity) {
    final bool isGuest = _user?.isAnonymous ?? true;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          color: Colors.black.withOpacity(0.1),
          child: Opacity(
            opacity: contentOpacity,
            // O conteúdo (logado ou convidado) é inserido aqui
            child: isGuest
                ? _buildGuestContent(theme)
                : _buildLoggedInContent(theme),
          ),
        ),
      ),
    );
  }

  // NOVO: Widget de conteúdo para usuário LOGADO
  Widget _buildLoggedInContent(ThemeData theme) {
    final photoUrl = _user?.photoURL;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
          child: (photoUrl != null && photoUrl.isNotEmpty)
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                  ),
                )
              : Icon(Icons.person, size: 40, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 12),
        Text(
          _user?.displayName ?? "Usuário",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          _user?.email ?? "",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // NOVO: Widget de conteúdo para usuário CONVIDADO
  Widget _buildGuestContent(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
          child: Icon(
            Icons.person_outline,
            size: 45,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.guestMode,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _glassMorphicWrapper({required Widget child}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.8),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
