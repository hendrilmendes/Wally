// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:intl/intl.dart';
import 'package:projectx/commands/commands.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/chat/chat.dart' as chat;
import 'package:projectx/screens/newsdroid/news.dart';
import 'package:projectx/screens/settings/settings.dart';
import 'package:projectx/screens/tasks/tasks.dart';
import 'package:projectx/screens/weather/weather.dart';
import 'package:projectx/service/ia.dart';
import 'package:projectx/service/tasks.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<chat.ChatMessage> _messages = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final String _iaPhoto = 'assets/img/robot_photo.png';
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _audioInput = '';
  late Future<void> _iaInitialized;
  String aiApiKey = '';
  late AIService _aiService;
  late final User? user;
  int _desktopNavIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String? _speakingMessageId;
  final TasksService _tasksService = TasksService();

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _iaInitialized = _initializeServices();
    _sendWelcomeMessage();
    _controller.addListener(_onTextChanged);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initializeTts();
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeServices() async {
    await _fetchApi();
    _aiService = AIService(apiKey: aiApiKey);
  }

  Future<void> _fetchApi() async {
    try {
      final response = await http.get(
        Uri.https('wally-server.hendrilmendes2015.workers.dev', '/api'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (mounted) setState(() => aiApiKey = jsonData['apiKey']);
      } else {
        throw Exception('Failed to load API key');
      }
    } catch (e) {
      if (kDebugMode) print('Error getting API key: $e');
      throw Exception('Failed to get API key');
    }
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _initializeTts() {
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingMessageId = null);
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _speakingMessageId = null);
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    _controller.dispose();
    _pulseController.dispose();
    _controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _addMessage(chat.ChatMessage message) {
    if (mounted) {
      _messages.insert(0, message);
      _listKey.currentState?.insertItem(
        0,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  Future<void> _sendWelcomeMessage() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _messages.add(
            chat.ChatMessage(
              role: chat.Role.iA,
              content: AppLocalizations.of(context)!.wallyWelcome,
              name: 'Wally',
            ),
          );
        });
      }
    });
  }

  Future<void> _sendMessage(
    String messageContent, {
    bool fromAudio = false,
    String? detectedLocale,
  }) async {
    final contentToSend = messageContent.trim();
    if (contentToSend.isEmpty) return;

    if (!fromAudio) {
      _controller.clear();
    }
    _addMessage(
      chat.ChatMessage(
        role: chat.Role.user,
        content: contentToSend,
        name: "User",
      ),
    );
    _addMessage(
      chat.ChatMessage(
        role: chat.Role.iA,
        content: '...',
        name: 'Wally',
        isLoading: true,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 50));

    try {
      await _iaInitialized;

      if (user?.isAnonymous ?? true) {
        if (CommandHandler.isAddTaskCommand(contentToSend) ||
            CommandHandler.isListTasksCommand(contentToSend)) {
          _removeLoadingIndicator();
          _addMessage(
            chat.ChatMessage(
              role: chat.Role.iA,
              content:
                  "Para usar a função de tarefas, você precisa fazer login com uma conta Google.",
              name: 'Wally',
            ),
          );
          return;
        }
      }

      if (CommandHandler.isAddTaskCommand(contentToSend)) {
        final taskDetails = CommandHandler.extractTaskDetails(contentToSend);
        final taskTitle = taskDetails['title'];

        if (taskTitle != null && taskTitle.isNotEmpty && user != null) {
          final newTask = Task(
            title: taskTitle,
            userId: user!.uid,
            note: taskDetails['note'],
            dateTime: taskDetails['dateTime'],
            isCompleted: false
          );
          await _tasksService.addItem(newTask);
          _removeLoadingIndicator();

          String confirmation = '✅ Tarefa "$taskTitle" adicionada!';
          if (taskDetails['dateTime'] != null) {
            confirmation +=
                ' para ${DateFormat.yMd('pt_BR').format(taskDetails['dateTime']!)}';
          }
          _addMessage(
            chat.ChatMessage(
              role: chat.Role.iA,
              content: confirmation,
              name: 'Wally',
            ),
          );
        } else {
          _showError("Não consegui entender o nome da tarefa para adicionar.");
        }
      } else if (CommandHandler.isListTasksCommand(contentToSend)) {
        if (user != null) {
          final tasks = await _tasksService.getTasksStream(user!.uid).first;
          _removeLoadingIndicator();
          if (tasks.isEmpty) {
            _addMessage(
              chat.ChatMessage(
                role: chat.Role.iA,
                content:
                    "Você não tem nenhuma tarefa pendente. Que tal adicionar uma?",
                name: 'Wally',
              ),
            );
          } else {
            _addMessage(
              chat.ChatMessage(role: chat.Role.iA, name: 'Wally', tasks: tasks),
            );
          }
        }
      } else if (CommandHandler.shouldCheckWeather(contentToSend)) {
        _navigateToWeather();
        _removeLoadingIndicator();
      } else if (CommandHandler.shouldCheckNews(contentToSend)) {
        _navigateToNews();
        _removeLoadingIndicator();
      } else {
        await _generateAndDisplayResponse(
          contentToSend,
          fromAudio: fromAudio,
          locale: detectedLocale ?? 'pt-BR',
        );
      }
    } catch (error) {
      _showError(error.toString());
    }
  }

  void _removeLoadingIndicator() {
    final loadingMessageIndex = _messages.indexWhere((m) => m.isLoading);
    if (loadingMessageIndex != -1) {
      final chat.ChatMessage item = _messages.removeAt(loadingMessageIndex);
      _listKey.currentState?.removeItem(
        loadingMessageIndex,
        (context, animation) => const SizedBox.shrink(),
      );
    }
  }

  Future<void> _generateAndDisplayResponse(
    String message, {
    bool fromAudio = false,
    required String locale,
  }) async {
    final systemPrompt =
        'Assuma a persona de Wally, um assistente de IA. Sua personalidade é: prestativa, otimista e com um toque de inteligência espirituosa. '
        'Sua principal missão é ajudar o usuário de forma rápida e eficiente. '
        'Todas as respostas devem ser concisas, manter um tom amigável e encorajador. '
        'IMPORTANTE: Responda estritamente no idioma correspondente ao seguinte código de localidade: $locale.';

    final localResponse = CommandHandler.handleSimpleResponse(message);
    String finalPrompt;
    AiModelType modelToUse;

    if (localResponse != null) {
      modelToUse = AiModelType.fast;
      finalPrompt =
          '$systemPrompt O usuário fez uma pergunta simples cuja resposta direta é "$localResponse". Reformule essa resposta de forma criativa e amigável.';
    } else {
      modelToUse = AiModelType.smart;
      finalPrompt = '$systemPrompt O usuário perguntou: "$message".';
    }

    try {
      final aiResponse = await _aiService.getAiResponse(
        finalPrompt,
        modelType: modelToUse,
      );

      if (mounted) {
        _removeLoadingIndicator();
        final aiMessage = chat.ChatMessage(
          role: chat.Role.iA,
          content: aiResponse,
          name: 'Wally',
        );
        _addMessage(aiMessage);

        if (fromAudio) {
          await _speak(aiResponse, locale, aiMessage.id);
        }
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (kDebugMode) print('[SpeechToText] onStatus: $val');
          if (mounted) setState(() => _isListening = _speech.isListening);
        },
        onError: (val) {
          if (kDebugMode) print('[SpeechToText] onError: $val');
          if (mounted) setState(() => _isListening = false);
        },
        debugLogging: kDebugMode,
      );

      if (available) {
        if (mounted) setState(() => _isListening = true);

        _speech.listen(
          onResult: (val) async {
            if (mounted) {
              setState(() => _audioInput = val.recognizedWords);

              if (val.finalResult && _audioInput.isNotEmpty) {
                String locale;

                if (kIsWeb) {
                  var systemLocale = await _speech.systemLocale();
                  locale = systemLocale?.localeId ?? 'pt-BR';
                  if (kDebugMode) {
                    print('[Web] Usando o idioma do sistema: $locale');
                  }
                } else {
                  final languageIdentifier = LanguageIdentifier(
                    confidenceThreshold: 0.5,
                  );
                  locale = await languageIdentifier.identifyLanguage(
                    _audioInput,
                  );
                  languageIdentifier.close();
                  if (kDebugMode) print('[Mobile] Idioma Detectado: $locale');
                }

                String processedInput = _preprocessSpeechInput(_audioInput);
                if (processedInput.isNotEmpty) {
                  _sendMessage(
                    processedInput,
                    fromAudio: true,
                    detectedLocale: locale,
                  );
                }
                _audioInput = '';
              }
            }
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
          onDevice: false,
        );
      } else {
        if (kDebugMode) {
          print(
            "[SpeechToText] O serviço de reconhecimento de voz não está disponível.",
          );
        }
        if (mounted) setState(() => _isListening = false);
      }
    } else {
      if (mounted) setState(() => _isListening = false);
      _speech.stop();
    }
  }

  String _preprocessSpeechInput(String input) {
    final fillers = ['hum', 'ah', 'eh', 'tipo', 'assim'];
    for (var filler in fillers) {
      input = input.replaceAll(
        RegExp('\\b$filler\\b', caseSensitive: false),
        '',
      );
    }
    final corrections = {
      'notícias': ['noticia', 'noticias', 'novidades'],
      'clima': ['tempo', 'previsão'],
      'tarefas': ['tarefa', 'afazer', 'a fazer'],
    };
    corrections.forEach((correct, alternatives) {
      for (var alt in alternatives) {
        if (input.contains(alt)) {
          input = input.replaceAll(alt, correct);
        }
      }
    });
    return input.trim();
  }

  Future<void> _speak(String text, String locale, String messageId) async {
    if (mounted) {
      setState(() => _speakingMessageId = messageId);
    }

    await _flutterTts.setLanguage(locale);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

    final emojiRegex = RegExp(
      r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
    );
    final cleanedText = text.replaceAll(emojiRegex, '');

    if (cleanedText.trim().isNotEmpty) {
      await _flutterTts.setSpeechRate(0.6);
      await _flutterTts.speak(cleanedText);
    } else {
      if (mounted) setState(() => _speakingMessageId = null);
    }
  }

  void _navigateToWeather() => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const WeatherScreen()),
  );

  void _navigateToNews() => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const NewsApp()),
  );

  void _navigateToTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TasksScreen()),
    );
  }

  void _showError(String error) {
    if (mounted) {
      _removeLoadingIndicator();
      setState(
        () => _addMessage(
          chat.ChatMessage(
            role: chat.Role.iA,
            content: 'Erro: $error',
            name: "Wally",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _iaInitialized,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return LayoutBuilder(
            builder: (context, constraints) {
              const double desktopBreakpoint = 800;
              if (constraints.maxWidth >= desktopBreakpoint) {
                return _buildDesktopLayout();
              } else {
                return _buildMobileLayout();
              }
            },
          );
        }
        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error.toString());
        }
        return _buildLoadingScreen();
      },
    );
  }

  // --- LAYOUT DE DESKTOP ---
  Widget _buildDesktopLayout() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
        child: Row(
          children: [
            Container(
              width: 90,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.3),
                border: Border(
                  right: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                ),
              ),
              child: NavigationRail(
                selectedIndex: _desktopNavIndex,
                onDestinationSelected: (int index) {
                  setState(() => _desktopNavIndex = index);
                  switch (index) {
                    case 1:
                      _navigateToWeather();
                      break;
                    case 2:
                      _navigateToNews();
                      break;
                    case 3:
                      _navigateToTask();
                      break;
                    case 4:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                      break;
                  }
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) setState(() => _desktopNavIndex = 0);
                  });
                },
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Image.asset(_iaPhoto, width: 80, height: 80),
                ),
                backgroundColor: Colors.transparent,
                indicatorColor: theme.colorScheme.primary.withOpacity(0.2),
                labelType: NavigationRailLabelType.selected,
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: Icon(
                      Icons.chat_bubble_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(l10n.chat),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.wb_sunny_outlined),
                    label: Text(l10n.weather),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.article_outlined),
                    label: Text(l10n.news),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.task_alt_outlined),
                    label: Text(l10n.tarefasApp),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.settings_outlined),
                    label: Text(l10n.settings),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text(l10n.appName, style: theme.textTheme.titleLarge),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: _buildMessageList(),
                      ),
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: _buildDesktopInputField(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopInputField() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bool canSend = _controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(28.0),
        shadowColor: Colors.black.withOpacity(0.2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: l10n.typeSomething,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: "Falar",
                        onPressed: _listen,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: _isListening
                              ? SpinKitPulse(
                                  key: const ValueKey('listening'),
                                  color: theme.colorScheme.primary,
                                  size: 24.0,
                                )
                              : Icon(
                                  key: const ValueKey('idle'),
                                  Icons.mic_none,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_rounded),
                        onPressed: canSend
                            ? () => _sendMessage(_controller.text)
                            : null,
                        tooltip: "Enviar",
                        color: canSend
                            ? theme.colorScheme.primary
                            : theme.disabledColor,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                onSubmitted: (value) {
                  if (canSend) _sendMessage(value);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- LAYOUT DE MOBILE ---
  Widget _buildMobileLayout() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(_iaPhoto, width: 80, height: 80),
            const SizedBox(width: 12),
            Text(
              l10n.appName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            const Divider(height: 1),
            _buildBottomActionArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionArea() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_alt_outlined,
              color: theme.colorScheme.primary,
            ),
            onPressed: _showTextInputSheet,
          ),
          GestureDetector(
            onTap: _listen,
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isListening
                        ? SpinKitPulse(
                            key: const ValueKey('listening'),
                            color: theme.colorScheme.onPrimary,
                            size: 40.0,
                          )
                        : Icon(
                            Icons.mic_none,
                            key: ValueKey('mic'),
                            color: theme.colorScheme.onPrimary,
                            size: 40,
                          ),
                  ),
                ),
              ),
            ),
          ),
          // Botão de sugestões
          IconButton(
            icon: Icon(
              Icons.explore_outlined,
              color: theme.colorScheme.primary,
            ),
            onPressed: _showSuggestionSheet,
          ),
        ],
      ),
    );
  }

  void _showSuggestionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
              ),
              child: Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                alignment: WrapAlignment.center,
                children: [
                  _buildGlassmorphicChip(
                    icon: Icons.wb_sunny_outlined,
                    label: AppLocalizations.of(context)!.weather,
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToWeather();
                    },
                  ),
                  _buildGlassmorphicChip(
                    icon: Icons.article_outlined,
                    label: AppLocalizations.of(context)!.newsdroidApp,
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToNews();
                    },
                  ),
                  _buildGlassmorphicChip(
                    icon: Icons.task_outlined,
                    label: AppLocalizations.of(context)!.tarefasApp,
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToTask();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassmorphicChip({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return AnimatedList(
      key: _listKey,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      initialItemCount: _messages.length,
      itemBuilder: (context, index, animation) {
        final message = _messages[index];
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(
            opacity: animation,
            child: _buildMessageBubble(message),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(chat.ChatMessage message) {
    final isUser = message.role == chat.Role.user;
    final theme = Theme.of(context);
    final bool isSpeaking = message.id == _speakingMessageId;

    final alignment = isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final color = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surface.withOpacity(0.5);
    final textColor = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final borderRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              enabled: !isUser,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: borderRadius,
                  border: !isUser
                      ? Border.all(color: Colors.white.withOpacity(0.2))
                      : null,
                ),
                child: message.isLoading
                    ? SpinKitThreeBounce(color: textColor, size: 18)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              message.content ?? '',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (isSpeaking)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: SpinKitWave(
                                color: textColor,
                                size: 18.0,
                                type: SpinKitWaveType.start,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTextInputSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.toType,
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            _sendMessage(value);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        if (_controller.text.isNotEmpty) {
                          _sendMessage(_controller.text);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Erro ao inicializar: $error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Image.asset(
                  'assets/img/robot_photo.png',
                  height: 120,
                  width: 120,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                l10n.appName,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  l10n.connectingServer,
                  key: ValueKey(l10n.connectingServer),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
