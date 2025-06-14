// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final List<Widget> _conversation = [];
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _remainingQuestions = [];
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startConversation());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
      });
    }
  }

  void _addMessage(Widget message) {
    setState(() {
      _conversation.add(message);
    });
    // Anima o scroll para o final da lista
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startConversation() {
    final l10n = AppLocalizations.of(context)!;
    _remainingQuestions = [
      {'id': 'creator', 'text': l10n.whoCreatedYou},
      {'id': 'version', 'text': l10n.whatIsYourVersion},
      {'id': 'privacy', 'text': l10n.privacy},
      {'id': 'source', 'text': l10n.sourceCode},
      {'id': 'licenses', 'text': l10n.openSource},
    ];

    _addMessage(_buildBotBubble(l10n.wallyWelcomeAbout));
    _addMessage(_buildQuestionChips());
  }

  void _handleQuestion(String id, String questionText) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _conversation.removeLast(); // Remove os chips
    });
    _addMessage(_buildUserBubble(questionText));
    _remainingQuestions.removeWhere((q) => q['id'] == id);

    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(_buildBotBubble('...', isLoading: true));
      Future.delayed(const Duration(seconds: 1), () {
        String botResponse = '';
        VoidCallback? action;
        String? actionLabel;

        switch (id) {
          case 'creator':
            botResponse = l10n.creatorResponse;
            action = () =>
                launchUrl(Uri.parse('https://github.com/hendrilmendes'));
            actionLabel = l10n.seeGitHub;
            break;
          case 'version':
           botResponse = l10n.versionResponse(_appVersion);
            action = () => launchUrl(
              Uri.parse(
                'https://github.com/hendrilmendes/Wally/releases/tag/$_appVersion',
              ),
            );
            actionLabel = l10n.seeChangelog;
            break;
          case 'source':
            botResponse = l10n.sourceCodeSub;
            action = () =>
                launchUrl(Uri.parse('https://github.com/hendrilmendes/Wally'));
            actionLabel = l10n.openRepository;
            break;
          case 'licenses':
            botResponse = l10n.openSourceSub;
            action = () => showLicensePage(
              context: context,
              applicationName: l10n.appName,
            );
            actionLabel = l10n.seeLicenses;
            break;
          case 'privacy':
            botResponse = l10n.privacyPolicyResponse;
            action = () => launchUrl(
              Uri.parse(
                'https://br-newsdroid.blogspot.com/p/politica-de-privacidade-wally.html',
              ),
            );
            actionLabel = l10n.seePolicy;
            break;
        }

        setState(() {
          _conversation.removeLast();
        });
        _addMessage(
          _buildBotBubble(
            botResponse,
            action: action,
            actionLabel: actionLabel,
          ),
        );
        if (_remainingQuestions.isNotEmpty) {
          _addMessage(_buildQuestionChips());
        } else {
          _addMessage(_buildBotBubble(l10n.hopeIHelped));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // Permite que o body fique atrás da AppBar
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.about),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        // Fundo em gradiente para dar base ao efeito de vidro
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
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _conversation.length,
                  itemBuilder: (context, index) => _conversation[index],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotBubble(
    String text, {
    bool isLoading = false,
    VoidCallback? action,
    String? actionLabel,
  }) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: isLoading
                  ? SpinKitThreeBounce(
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 18,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        if (action != null && actionLabel != null) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: action,
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: Text(actionLabel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary
                                  .withOpacity(0.8),
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserBubble(String text) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: theme.colorScheme.onPrimary, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildQuestionChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.end,
        children: _remainingQuestions.map((q) {
          return InkWell(
            onTap: () => _handleQuestion(q['id'], q['text']),
            borderRadius: BorderRadius.circular(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                  child: Text(q['text']),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
