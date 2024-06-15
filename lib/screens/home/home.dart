import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:projectx/service/service.dart';
import 'package:projectx/speech/speech.dart';
import 'package:projectx/text/text.dart';
import 'package:projectx/widgets/home/card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextToSpeech _tts = TextToSpeech();
  String _translatedText = '';
  String _recognizedText = '';
  String _selectedLanguage = 'pt'; // Idioma padrão

  final Map<String, String> _languageAccents = {
    'es': 'es-ES',
    'fr': 'fr-FR',
    'de': 'de-DE',
    'it': 'it-IT',
    'en': 'en-US',
    'pt': 'pt-BR',
  };

  final List<String> _languages = ['es', 'fr', 'de', 'it', 'en', 'pt'];

  void _onSpeechResult(String text) {
    setState(() {
      _recognizedText = text;
    });
  }

  void _translateAndSpeak() async {
    if (_recognizedText.isEmpty) return;

    try {
      String translation =
          await translateText(_recognizedText, _selectedLanguage);
      setState(() {
        _translatedText = translation;
      });

      String languageAccent = _languageAccents[_selectedLanguage] ?? 'pt-BR';
      await _tts.speak(translation, languageAccent);
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(child: SpeechScreen(onSpeechResult: _onSpeechResult)),
            const SizedBox(height: 20),
            buildTextCard(
              context,
              AppLocalizations.of(context)!.recText,
              _recognizedText,
              fontSize: 16,
            ),
            const SizedBox(height: 20),
            buildTextCard(
              context,
              AppLocalizations.of(context)!.translatedText,
              _translatedText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLanguage = newValue!;
                });
              },
              items: _languages.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: _translateAndSpeak,
              child: Text(AppLocalizations.of(context)!.translate),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
