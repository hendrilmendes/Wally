import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:projectx/screens/apps/apps.dart';
import 'package:projectx/screens/settings/settings.dart';
import 'package:projectx/screens/weather/weather.dart';
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
  final List<ChatMessage> _messages = [];
  final String _userPhoto = 'assets/img/user_photo.png';
  final String _chatGptPhoto = 'assets/img/robot_photo.png';
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _audioInput = '';

  OpenAI? openAI;
  late Future<void> _openAIInitialized;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateButtonState);
    _openAIInitialized = _initializeOpenAI();
    _sendWelcomeMessage();
  }

  Future<void> _initializeOpenAI() async {
    String? apiKey;

    if (kIsWeb) {
      final env = js.context['env'] as Map<String, dynamic>?;
      apiKey = env?['OPENAI_API_KEY'] as String?;
      if (kDebugMode) {
        print('API Key from JS: $apiKey');
      }
    } else {
      await dotenv.load();
      apiKey = dotenv.env['OPENAI_API_KEY'];
      if (kDebugMode) {
        print('API Key from .env: $apiKey');
      }
    }

    if (apiKey == null) {
      throw Exception("OPENAI_API_KEY não foi configurada corretamente.");
    }

    setState(() {
      openAI = OpenAI.instance.build(
        token: apiKey!,
        baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 6000)),
        enableLog: true,
      );
    });
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
                          name: message.name,
                          photo: message.role == Role.user
                              ? _userPhoto
                              : _chatGptPhoto,
                          isLoading: message.isLoading,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 8.0),
                    child: Card(
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                onSubmitted: (value) => _sendMessage(value),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText:
                                      AppLocalizations.of(context)!.toType,
                                ),
                                onChanged: (text) {
                                  setState(() {});
                                },
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.search,
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return ScaleTransition(
                                    scale: animation, child: child);
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
                                        await _sendMessage(_controller.text);
                                        _controller.clear();
                                      },
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
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
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

  Map<String, String> toMap() {
    return {'role': role.toString(), 'content': content, 'name': name};
  }
}

enum Role {
  user,
  chatGPT,
}

class ChatBubble extends StatelessWidget {
  final Role role;
  final String content;
  final String name;
  final String photo;
  final bool isLoading;

  const ChatBubble({
    super.key,
    required this.role,
    required this.content,
    required this.name,
    required this.photo,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          role == Role.user ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: role == Role.user ? Colors.blue : Colors.grey,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage(photo),
              ),
              const SizedBox(height: 4),
              isLoading
                  ? const SpinKitThreeBounce(
                      color: Colors.white,
                      size: 20.0,
                    )
                  : Text(
                      content,
                      style: const TextStyle(color: Colors.white),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
