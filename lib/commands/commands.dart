import 'package:intl/intl.dart';

enum CommandType {
  time,
  date,
  greeting,
  identity,
  function,
  addTask,
  listTasks,
  unknown,
}

class CommandHandler {
  static final Map<RegExp, CommandType> _commandPatterns = {
    RegExp(
      r'adicionar tarefa:?\s*(.+)|criar tarefa:?\s*(.+)',
      caseSensitive: false,
    ): CommandType.addTask,
    RegExp(
      r'minhas tarefas|quais são minhas tarefas|listar tarefas',
      caseSensitive: false,
    ): CommandType.listTasks,

    RegExp(r'\b(horas?|que horas são)\b', caseSensitive: false):
        CommandType.time,
    RegExp(r'\b(data|que dia é hoje)\b', caseSensitive: false):
        CommandType.date,
    RegExp(r'\b(olá|oi|ola)\b', caseSensitive: false): CommandType.greeting,
    RegExp(r'\b(como você está|tudo bem)\b', caseSensitive: false):
        CommandType.greeting,
    RegExp(r'\b(quem é você|seu nome)\b', caseSensitive: false):
        CommandType.identity,
    RegExp(r'\b(função|o que você faz)\b', caseSensitive: false):
        CommandType.function,
  };

  static String _getCurrentTime() {
    return DateFormat('HH:mm').format(DateTime.now());
  }

  static String _getCurrentDate() {
    return DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(DateTime.now());
  }

  static String? handleSimpleResponse(String message) {
    final commandType = getCommandType(message);

    switch (commandType) {
      case CommandType.time:
        return _getCurrentTime();
      case CommandType.date:
        return _getCurrentDate();
      case CommandType.greeting:
        if (message.toLowerCase().contains('como você está') ||
            message.toLowerCase().contains('tudo bem')) {
          return 'Estou ótimo, obrigado por perguntar! E você, como posso ajudar?';
        }
        return 'Olá! Em que posso ser útil hoje?';
      case CommandType.identity:
        return 'Meu nome é Wally, seu assistente pessoal. Prazer em conhecer!';
      case CommandType.function:
        return 'Minha função é te ajudar com informações e tarefas. Desde a previsão do tempo até as últimas notícias, estou aqui para facilitar o seu dia.';
      default:
        return null;
    }
  }

  static CommandType getCommandType(String message) {
    final text = message.toLowerCase();
    for (final entry in _commandPatterns.entries) {
      if (entry.key.hasMatch(text)) {
        return entry.value;
      }
    }
    return CommandType.unknown;
  }

  static Map<String, dynamic> extractTaskDetails(String message) {
    String details = message
        .replaceAll(
          RegExp(
            r'adicionar tarefa:?\s*|criar tarefa:?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    String title = details;
    DateTime? dueDate;
    String? note;

    final noteRegex = RegExp(r'com nota:?\s*(.+)', caseSensitive: false);
    if (noteRegex.hasMatch(details)) {
      final noteMatch = noteRegex.firstMatch(details);
      if (noteMatch != null) {
        note = noteMatch.group(1)?.trim();
        details = details.replaceAll(noteRegex, '').trim();
        title = details;
      }
    }

    if (details.contains('para amanhã')) {
      title = title.replaceAll('para amanhã', '').trim();
      dueDate = DateTime.now().add(const Duration(days: 1));
    } else if (details.contains('para hoje')) {
      title = title.replaceAll('para hoje', '').trim();
      dueDate = DateTime.now();
    }

    return {'title': title, 'dueDate': dueDate, 'note': note};
  }

  static bool isAddTaskCommand(String message) =>
      getCommandType(message) == CommandType.addTask;
  static bool isListTasksCommand(String message) =>
      getCommandType(message) == CommandType.listTasks;

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
