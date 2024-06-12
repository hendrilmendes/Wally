import 'package:libre_translate/libre_translate.dart';

Future<String> translateText(String text, String targetLang) async {
  try {
    final client = LibreTranslateClient(base: Uri.https('translate.terraprint.co'));
    final translation = await client.translate(text, source: 'auto', target: targetLang);
    return translation;
  } catch (e) {
    throw Exception('Failed to load translation: $e');
  }
}
