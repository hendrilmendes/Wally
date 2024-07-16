import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:projectx/apps/apps.dart';
import 'package:projectx/screens/newsdroid/news.dart';
import 'package:projectx/screens/settings/settings.dart';
import 'package:projectx/screens/weather/weather.dart';
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
  final List<ChatMessage> _messages = [];
  final String _userPhoto = 'assets/img/user_photo.png';
  final String _chatGptPhoto = 'assets/img/robot_photo.png';
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _audioInput = '';

  OpenAI? openAI;
  late Future<void> _openAIInitialized;
  String openaiApiKey = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateButtonState);
    _openAIInitialized = _initOpenAI();
    _sendWelcomeMessage();
  }

  Future<void> _initOpenAI() async {
    await _fetchOpenAIKey();
    await _initializeOpenAI();
  }

  Future<void> _fetchOpenAIKey() async {
    try {
      final response =
          await http.get(Uri.https('wally-server.onrender.com', '/api'));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          openaiApiKey = jsonData['apiKey'];
        });
      } else {
        throw Exception('Falha ao carregar OpenAI API key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter OpenAI API key: $e');
      }
      throw Exception('Falha ao obter OpenAI API key');
    }
  }

  Future<void> _initializeOpenAI() async {
    try {
      if (openaiApiKey.isEmpty) {
        throw Exception('OpenAI API key nao obtida');
      }

      setState(() {
        openAI = OpenAI.instance.build(
          token: openaiApiKey,
          baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 6000)),
          enableLog: true,
        );
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao inicializar OpenAI: $e');
      }
      throw Exception('Falha ao inicializar OpenAI');
    }
  }

  void _updateButtonState() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_updateButtonState);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendWelcomeMessage() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final welcomeMessage = ChatMessage(
        role: Role.chatGPT,
        content: AppLocalizations.of(context)!.wallyWelcome,
        name: 'Wally',
      );
      setState(() {
        _messages.add(welcomeMessage);
      });
    });
  }

  Future<void> _sendMessage(String messageContent,
      {bool fromAudio = false}) async {
    try {
      await _openAIInitialized;

      if (openAI == null) {
        throw Exception("OpenAI não foi inicializado corretamente.");
      }

      setState(() {
        _messages.add(ChatMessage(
          role: Role.user,
          content: messageContent,
          name: "Humano",
        ));
      });

      _controller.clear();

      if (_shouldOpenApp(messageContent)) {
        await AppLauncher.handleAppRequest(messageContent, (chatMessage) {
          setState(() {
            _messages.add(chatMessage);
          });
        });
      } else if (_shouldCheckWeather(messageContent)) {
        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => const WeatherScreen(),
          ),
        );
      } else if (_shouldCheckNews(messageContent)) {
        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => const NewsApp(),
          ),
        );
      } else {
        setState(() {
          _messages.add(ChatMessage(
            role: Role.chatGPT,
            content: '...',
            name: 'Wally',
            isLoading: true,
          ));
        });

        final request = ChatCompleteText(
          messages: [
            {'role': 'system', 'content': ''},
            {'role': 'user', 'content': messageContent},
          ],
          model: GptTurboChatModel(),
          maxToken: 200,
        );

        try {
          final response = await openAI!.onChatCompletion(request: request);
          if (response != null && response.choices.isNotEmpty) {
            final gptResponse = response.choices.first.message?.content ?? '';
            setState(() {
              _messages.removeLast();
              _messages.add(ChatMessage(
                role: Role.chatGPT,
                content: gptResponse,
                name: "Wally",
              ));
            });
            if (fromAudio) {
              await _speak(gptResponse);
            }
          } else {
            throw Exception("Resposta vazia da API do OpenAI.");
          }
        } catch (error) {
          setState(() {
            _messages.removeLast();
            _messages.add(ChatMessage(
              role: Role.chatGPT,
              content: 'Erro ao processar resposta: $error',
              name: "Wally",
            ));
          });
        }
      }
    } catch (error) {
      setState(() {
        _messages.add(ChatMessage(
          role: Role.chatGPT,
          content: 'Erro: $error',
          name: "Wally",
        ));
      });
    }
  }

  bool _shouldCheckWeather(String message) {
    final lowerCaseMessage = message.toLowerCase();
    return lowerCaseMessage.contains("tempo") ||
        lowerCaseMessage.contains("previsão do tempo") ||
        lowerCaseMessage.contains("clima");
  }

  bool _shouldOpenApp(String message) {
    final lowerCaseMessage = message.toLowerCase();
    return lowerCaseMessage.contains("abra") ||
        lowerCaseMessage.contains("abre") ||
        lowerCaseMessage.contains("abrir");
  }

  bool _shouldCheckNews(String message) {
    final lowerCaseMessage = message.toLowerCase();
    return lowerCaseMessage.contains("notícias") ||
        lowerCaseMessage.contains("noticia") ||
        lowerCaseMessage.contains("news");
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => setState(() => _isListening = val == 'listening'),
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
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
      future: _openAIInitialized,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Tela grande: exibir menu lateral
                  return Row(
                    children: [
                      // Menu lateral
                      SizedBox(
                        width: 250, // Largura do menu lateral
                        child: Drawer(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: <Widget>[
                              DrawerHeader(
                                child: Text(
                                  AppLocalizations.of(context)!.appName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.wb_sunny_outlined),
                                title:
                                    Text(AppLocalizations.of(context)!.weather),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WeatherScreen(),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.whatshot_outlined),
                                title: Text(
                                    AppLocalizations.of(context)!.newsdroidApp),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NewsApp(),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.task_alt_outlined),
                                title: Text(
                                    AppLocalizations.of(context)!.tarefasApp),
                                onTap: () {
                                  launchUrl(
                                    Uri.parse(
                                        'https://play.google.com/store/apps/details?id=com.github.hendrilmendes.tarefas'),
                                  );
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.settings_outlined),
                                title: Text(
                                    AppLocalizations.of(context)!.settings),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Conteúdo principal
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 50,
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  return ChatBubble(
                                    role: message.role,
                                    content: message.content,
                                    photo: message.role == Role.user
                                        ? _userPhoto
                                        : _chatGptPhoto,
                                    isLoading: message.isLoading,
                                  );
                                },
                              ),
                            ),
                            if (_isListening)
                              const SpinKitThreeBounce(
                                color: Colors.blue,
                                size: 30.0,
                              ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 8.0),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _controller,
                                            onSubmitted: (value) =>
                                                _sendMessage(value),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText:
                                                  AppLocalizations.of(context)!
                                                      .toType,
                                            ),
                                            onChanged: (text) {
                                              setState(() {});
                                            },
                                            keyboardType: TextInputType.text,
                                            textInputAction:
                                                TextInputAction.search,
                                          ),
                                        ),
                                        AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          transitionBuilder: (Widget child,
                                              Animation<double> animation) {
                                            return ScaleTransition(
                                              scale: animation,
                                              child: child,
                                            );
                                          },
                                          child: _controller.text.isEmpty
                                              ? IconButton(
                                                  key: const ValueKey('mic'),
                                                  icon: const Icon(Icons.mic,
                                                      color: Colors.blue),
                                                  onPressed: _listen,
                                                )
                                              : IconButton(
                                                  key: const ValueKey('send'),
                                                  icon: const Icon(Icons.send,
                                                      color: Colors.blue),
                                                  onPressed: () async {
                                                    await _sendMessage(
                                                        _controller.text);
                                                    _controller.clear();
                                                  },
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Tela pequena: exibir Drawer
                  return Scaffold(
                    appBar: AppBar(
                      title: Text(AppLocalizations.of(context)!.appName),
                    ),
                    drawer: Drawer(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: <Widget>[
                          DrawerHeader(
                            child: Text(
                              AppLocalizations.of(context)!.appName,
                              style: const TextStyle(
                                fontSize: 24,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.wb_sunny_outlined),
                            title: Text(AppLocalizations.of(context)!.weather),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WeatherScreen(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.whatshot_outlined),
                            title: Text(
                                AppLocalizations.of(context)!.newsdroidApp),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NewsApp(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.task_alt_outlined),
                            title:
                                Text(AppLocalizations.of(context)!.tarefasApp),
                            onTap: () {
                              launchUrl(
                                Uri.parse(
                                    'https://play.google.com/store/apps/details?id=com.github.hendrilmendes.tarefas'),
                              );
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.settings_outlined),
                            title: Text(AppLocalizations.of(context)!.settings),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    body: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return ChatBubble(
                                role: message.role,
                                content: message.content,
                                photo: message.role == Role.user
                                    ? _userPhoto
                                    : _chatGptPhoto,
                                isLoading: message.isLoading,
                              );
                            },
                          ),
                        ),
                        if (_isListening)
                          const SpinKitThreeBounce(
                            color: Colors.blue,
                            size: 30.0,
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 8.0),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _controller,
                                        onSubmitted: (value) =>
                                            _sendMessage(value),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText:
                                              AppLocalizations.of(context)!
                                                  .toType,
                                        ),
                                        onChanged: (text) {
                                          setState(() {});
                                        },
                                        keyboardType: TextInputType.text,
                                        textInputAction: TextInputAction.search,
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      transitionBuilder: (Widget child,
                                          Animation<double> animation) {
                                        return ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        );
                                      },
                                      child: _controller.text.isEmpty
                                          ? IconButton(
                                              key: const ValueKey('mic'),
                                              icon: const Icon(Icons.mic,
                                                  color: Colors.blue),
                                              onPressed: _listen,
                                            )
                                          : IconButton(
                                              key: const ValueKey('send'),
                                              icon: const Icon(Icons.send,
                                                  color: Colors.blue),
                                              onPressed: () async {
                                                await _sendMessage(
                                                    _controller.text);
                                                _controller.clear();
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Erro: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}

class ChatMessage {
  final Role role;
  final String content;
  final String name;
  final bool isLoading;

  ChatMessage({
    required this.role,
    required this.content,
    required this.name,
    this.isLoading = false,
  });
}

enum Role { user, chatGPT }

class ChatBubble extends StatelessWidget {
  final Role role;
  final String content;
  final String photo;
  final bool isLoading;

  const ChatBubble({
    super.key,
    required this.role,
    required this.content,
    required this.photo,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final alignment =
        role == Role.user ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor = role == Role.user ? Colors.blue[100] : Colors.grey[300];
    final textColor = role == Role.user ? Colors.black : Colors.black;
    const avatarRadius = 20.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: role == Role.user
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (role == Role.chatGPT) ...[
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: AssetImage(photo),
                ),
                const SizedBox(width: 8.0),
              ],
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: isLoading
                      ? const SpinKitThreeBounce(
                          color: Colors.blue,
                          size: 30.0,
                        )
                      : Text(
                          content,
                          style: TextStyle(color: textColor),
                        ),
                ),
              ),
              if (role == Role.user) ...[
                const SizedBox(width: 8.0),
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: AssetImage(photo),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
