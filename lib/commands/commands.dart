class CommandHandler {
  static const Map<String, String> simpleResponses = {
    'nome': 'Meu nome é Wally. Como posso ajudá-lo hoje?',
    'quem é você': 'Sou um assistente virtual criado para ajudar com tarefas simples e informações!',
    'função': 'Minha função é ajudar com respostas simples e diretas, e para questões mais complexas uso o DeepSeek!',
    'ola': 'Olá! Como posso ajudá-lo hoje?',
    'oi': 'Oi! Estou aqui para ajudar. O que você precisa?',
  };

  static bool isSimpleQuestion(String message) {
    final lowerMessage = message.toLowerCase();
    return simpleResponses.keys.any((key) => lowerMessage.contains(key)) ||
        RegExp(r'(como (você está|está)|tudo bem)').hasMatch(lowerMessage);
  }

  static String? handleSimpleResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (simpleResponses.containsKey(lowerMessage)) {
      return simpleResponses[lowerMessage];
    }
    
    final key = simpleResponses.keys.firstWhere(
      (key) => lowerMessage.contains(key),
      orElse: () => '',
    );
    
    return simpleResponses[key];
  }

  static bool shouldCheckWeather(String message) {
    final lowerMessage = message.toLowerCase();
    return lowerMessage.contains("tempo") ||
        lowerMessage.contains("previsão do tempo") ||
        lowerMessage.contains("clima");
  }

  static bool shouldCheckNews(String message) {
    final lowerMessage = message.toLowerCase();
    return lowerMessage.contains("notícias") ||
        lowerMessage.contains("noticia") ||
        lowerMessage.contains("news");
  }
}