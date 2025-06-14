import 'package:intl/intl.dart';

// NOVO: Enum para categorizar os tipos de comando.
// Isso nos ajuda a dar um contexto melhor para a IA.
enum CommandType {
  time,
  date,
  greeting,
  identity,
  function,
  unknown,
}

class CommandHandler {
  // ESTRUTURA MODIFICADA: Agora o mapa associa um padrão a um CommandType.
  static final Map<RegExp, CommandType> _commandPatterns = {
    RegExp(r'\b(horas?|que horas são)\b'): CommandType.time,
    RegExp(r'\b(data|que dia é hoje)\b'): CommandType.date,
    RegExp(r'\b(olá|oi|ola)\b'): CommandType.greeting,
    RegExp(r'\b(como você está|tudo bem)\b'): CommandType.greeting,
    RegExp(r'\b(quem é você|seu nome)\b'): CommandType.identity,
    RegExp(r'\b(função|o que você faz)\b'): CommandType.function,
  };

  // NOVO: Método para obter a hora atual formatada.
  static String _getCurrentTime() {
    return DateFormat('HH:mm').format(DateTime.now());
  }

  // NOVO: Método para obter a data atual formatada.
  static String _getCurrentDate() {
    // Exemplo: "13 de junho de 2025"
    return DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(DateTime.now());
  }
  
  // MÉTODO ATUALIZADO: Agora ele usa o CommandType para gerar a resposta.
  static String? handleSimpleResponse(String message) {
    final text = message.toLowerCase();
    
    for (final entry in _commandPatterns.entries) {
      if (entry.key.hasMatch(text)) {
        // Encontrou um padrão, agora retorna a resposta com base no tipo.
        switch (entry.value) {
          case CommandType.time:
            return _getCurrentTime();
          case CommandType.date:
            return _getCurrentDate();
          case CommandType.greeting:
            if (text.contains('como você está') || text.contains('tudo bem')) {
              return 'Estou ótimo, obrigado por perguntar! E você, como posso ajudar?';
            }
            return 'Olá! Em que posso ser útil hoje?';
          case CommandType.identity:
            return 'Meu nome é Wally, seu assistente pessoal. Prazer em conhecer!';
          case CommandType.function:
            return 'Minha função é te ajudar com informações e tarefas. Desde a previsão do tempo até as últimas notícias, estou aqui para facilitar o seu dia.';
          case CommandType.unknown:
            return null;
        }
      }
    }
    return null;
  }

  // NOVO: Método que a HomeScreen usará para obter o contexto.
  static CommandType getCommandType(String message) {
    final text = message.toLowerCase();
    for (final entry in _commandPatterns.entries) {
      if (entry.key.hasMatch(text)) {
        return entry.value;
      }
    }
    return CommandType.unknown;
  }

  // O método isSimpleQuestion agora pode ser simplificado, ou podemos
  // simplesmente verificar se handleSimpleResponse não é nulo.
  static bool isSimpleQuestion(String message) {
    return handleSimpleResponse(message) != null;
  }

  // MÉTODOS DE NAVEGAÇÃO (mantidos como estavam)
  static bool shouldCheckWeather(String message) {
    final text = message.toLowerCase();
    return text.contains('tempo') ||
        text.contains('clima') ||
        text.contains('previsão do tempo');
  }

  static bool shouldCheckNews(String message) {
    final text = message.toLowerCase();
    return text.contains('notícia') ||
        text.contains('noticias') ||
        text.contains('news');
  }
}