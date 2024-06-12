import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeech {
  late FlutterTts flutterTts;

  TextToSpeech() {
    flutterTts = FlutterTts();
  }

  Future<void> speak(String text, String languageAccent) async {
    await flutterTts.setLanguage(languageAccent);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }
}
