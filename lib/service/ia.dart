import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projectx/commands/commands.dart';

class AIService {
  final String apiKey;

  AIService({required this.apiKey});

  Future<String> handleComplexQuestion(String message) async {
    final response = await http.post(
      Uri.parse('https://api.deepseek.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "deepseek-chat",
        "messages": [{"role": "user", "content": message}],
        "temperature": 0.7,
        "max_tokens": 200,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'];
    }
    throw Exception("Erro na API: ${response.statusCode}");
  }

  static String? handleSimpleQuery(String message) {
    return CommandHandler.handleSimpleResponse(message);
  }
}