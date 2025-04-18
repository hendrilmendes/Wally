import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:projectx/commands/commands.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/chat/chat.dart' as chat;
import 'package:projectx/screens/newsdroid/news.dart';
import 'package:projectx/screens/settings/settings.dart';
import 'package:projectx/screens/weather/weather.dart';
import 'package:projectx/service/ia.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<chat.ChatMessage> _messages = [];
  final String _iaPhoto = 'assets/img/robot_photo.png';
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _audioInput = '';
  late Future<void> _iaInitialized;
  String deepseekApiKey = '';
  late AIService _aiService;
  late final User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _controller.addListener(_updateButtonState);
    _iaInitialized = _initializeServices();
    _sendWelcomeMessage();
  }

  Future<void> _initializeServices() async {
    await _fetchDeepSeekKey();
    _aiService = AIService(apiKey: deepseekApiKey);
  }

  Future<void> _fetchDeepSeekKey() async {
    try {
      final response = await http.get(
        Uri.https('wally-server.hendrilmendes2015.workers.dev', '/api'),
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() => deepseekApiKey = jsonData['apiKey']);
      } else {
        throw Exception('Failed to load API key');
      }
    } catch (e) {
      if (kDebugMode) print('Error getting API key: $e');
      throw Exception('Failed to get API key');
    }
  }

  void _updateButtonState() => setState(() {});

  @override
  void dispose() {
    // Certifique-se de encerrar o reconhecimento e a síntese de voz
    _speech.stop();
    _flutterTts.stop();
    _controller.removeListener(_updateButtonState);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendWelcomeMessage() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _messages.add(
          chat.ChatMessage(
            role: chat.Role.iA,
            content: AppLocalizations.of(context)!.wallyWelcome,
            name: 'Wally',
          ),
        );
      });
    });
  }

  Future<void> _sendMessage(
    String messageContent, {
    bool fromAudio = false,
  }) async {
    try {
      await _iaInitialized;

      setState(
        () => _messages.add(
          chat.ChatMessage(
            role: chat.Role.user,
            content: messageContent,
            name: "User",
          ),
        ),
      );

      _controller.clear();

      if (CommandHandler.shouldCheckWeather(messageContent)) {
        _navigateToWeather();
      } else if (CommandHandler.shouldCheckNews(messageContent)) {
        _navigateToNews();
      } else if (CommandHandler.isSimpleQuestion(messageContent)) {
        _handleSimpleResponse(messageContent);
      } else {
        await _handleComplexQuestion(messageContent, fromAudio: fromAudio);
      }
    } catch (error) {
      _showError(error.toString());
    }
  }

  void _handleSimpleResponse(String message) {
    final response = CommandHandler.handleSimpleResponse(message);
    if (response == null) {
      _handleComplexQuestion(message);
    } else {
      setState(
        () => _messages.add(
          chat.ChatMessage(
            role: chat.Role.iA,
            content: response,
            name: 'Wally',
          ),
        ),
      );
    }
  }

  Future<void> _handleComplexQuestion(
    String message, {
    bool fromAudio = false,
  }) async {
    setState(
      () => _messages.add(
        chat.ChatMessage(
          role: chat.Role.iA,
          content: '...',
          name: 'Wally',
          isLoading: true,
        ),
      ),
    );

    try {
      final response = await _aiService.handleComplexQuestion(message);
      setState(() {
        _messages.removeLast();
        _messages.add(
          chat.ChatMessage(
            role: chat.Role.iA,
            content: response,
            name: "Wally",
          ),
        );
      });
      if (fromAudio) await _speak(response);
    } catch (error) {
      _showError(error.toString());
    }
  }

  void _navigateToWeather() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeatherScreen()),
    );
  }

  void _navigateToNews() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewsApp()),
    );
  }

  void _showError(String error) {
    setState(() {
      _messages.removeLast();
      _messages.add(
        chat.ChatMessage(
          role: chat.Role.iA,
          content: 'Error: $error',
          name: "Wally",
        ),
      );
    });
  }

  Future<void> _listen() async {
    if (!_isListening) {
      // Inicializa o reconhecimento de voz
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (kDebugMode) print('Status: $val');
          setState(() => _isListening = val == 'listening');
        },
        onError: (val) {
          if (kDebugMode) print('Erro: $val');
          setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult:
              (val) => setState(() {
                _audioInput = val.recognizedWords;
                if (val.finalResult) {
                  _sendMessage(_audioInput, fromAudio: true);
                  _audioInput = '';
                }
              }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_audioInput.isNotEmpty) {
        _sendMessage(_audioInput, fromAudio: true);
        _audioInput = '';
      }
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _iaInitialized,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return _buildMainContent();
        }
        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error.toString());
        }
        return _buildLoadingScreen();
      },
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth > 600
              ? _buildDesktopLayout()
              : _buildMobileLayout();
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildSidebar(),
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 50),
              Expanded(child: _buildMessageList()),
              if (_isListening) _buildListeningIndicator(),
              _buildInputField(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Text(
              AppLocalizations.of(context)!.appName,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          ..._buildDrawerItems(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.appName)),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_isListening) _buildListeningIndicator(),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 250,
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text(
                AppLocalizations.of(context)!.appName,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            ..._buildDrawerItems(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDrawerItems() {
    return [
      _drawerItem(
        icon: Icons.wb_sunny_outlined,
        text: AppLocalizations.of(context)!.weather,
        action: _navigateToWeather,
      ),
      _drawerItem(
        icon: Icons.whatshot_outlined,
        text: AppLocalizations.of(context)!.newsdroidApp,
        action: _navigateToNews,
      ),
      _drawerItem(
        icon: Icons.task_alt_outlined,
        text: AppLocalizations.of(context)!.tarefasApp,
        action:
            () => launchUrl(
              Uri.parse(
                'https://play.google.com/store/apps/details?id=com.github.hendrilmendes.tarefas',
              ),
            ),
      ),
      const Divider(),
      _drawerItem(
        icon: Icons.settings_outlined,
        text: AppLocalizations.of(context)!.settings,
        action:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
      ),
    ];
  }

  ListTile _drawerItem({
    required IconData icon,
    required String text,
    required VoidCallback action,
  }) {
    return ListTile(leading: Icon(icon), title: Text(text), onTap: action);
  }

  Widget _buildMessageList() {
    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return chat.ChatBubble(
          role: message.role,
          content: message.content,
          photo:
              message.role == chat.Role.user
                  ? _buildUserPhoto()
                  : Image.asset(_iaPhoto, width: 40, height: 40),
          isLoading: message.isLoading,
        );
      },
    );
  }

  Widget _buildUserPhoto() {
    final photoUrl = user?.photoURL;
    if (photoUrl == null || photoUrl.isEmpty) {
      return Image.asset('assets/img/user_photo.png', width: 40, height: 40);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        photoUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const CircularProgressIndicator.adaptive();
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/img/user_photo.png',
            width: 40,
            height: 40,
          );
        },
      ),
    );
  }

  Widget _buildListeningIndicator() {
    return const SpinKitThreeBounce(color: Colors.blue, size: 30.0);
  }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _buildTextField()),
              _buildActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      onSubmitted: (value) => _sendMessage(value),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: AppLocalizations.of(context)!.toType,
      ),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
    );
  }

  Widget _buildActionButton() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder:
          (child, animation) => ScaleTransition(scale: animation, child: child),
      child:
          _isListening
              ? IconButton(
                key: const ValueKey('stop'),
                icon: const Icon(Icons.stop, color: Colors.red),
                onPressed: _listen,
              )
              : _controller.text.isEmpty
              ? IconButton(
                key: const ValueKey('mic'),
                icon: const Icon(Icons.mic, color: Colors.blue),
                onPressed: _listen,
              )
              : IconButton(
                key: const ValueKey('send'),
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () async {
                  await _sendMessage(_controller.text);
                  _controller.clear();
                },
              ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator.adaptive(),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.connectingServer,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
