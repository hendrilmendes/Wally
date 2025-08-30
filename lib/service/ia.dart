import 'dart:convert';
import 'package:http/http.dart' as http;

enum AiModelType { fast, smart }

class AIService {
  final String apiKey;

  AIService({required this.apiKey});

  Future<String> getAiResponse(
    String prompt, {
    required AiModelType modelType,
  }) async {
    String modelName;
    switch (modelType) {
      case AiModelType.fast:
        modelName = "google/gemini-2.0-flash-exp:free";
        break;
      case AiModelType.smart:
        modelName = "deepseek/deepseek-r1:free";
        break;
    }

    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'https://hendrilmendes.github.io/Wally/',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": modelName,
        "messages": [
          {"role": "user", "content": prompt},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'];
    } else {
      throw Exception(
        "Erro na API do modelo '$modelName' (${response.statusCode}): ${response.body}",
      );
    }
  }
}
