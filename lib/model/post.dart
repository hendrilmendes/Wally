import 'package:html/parser.dart' show parse;

class Post {
  final String id;
  final String title;
  final String content;
  final DateTime publishedDate;
  final String authorName;
  final String postUrl;
  final String? originalImageUrl;
  final String? proxyImageUrl;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.publishedDate,
    required this.authorName,
    required this.postUrl,
    this.originalImageUrl,
    this.proxyImageUrl,
  });

  // Factory constructor para criar um Post a partir do JSON do Blogger
  factory Post.fromBloggerJson(Map<String, dynamic> json) {
    String rawContent = json['content'] ?? '';
    
    // 1. Extrai a URL da imagem do conteúdo HTML
    String? imageUrl;
    try {
      var document = parse(rawContent);
      // Tenta encontrar a primeira tag de imagem
      var imageElement = document.querySelector('img');
      if (imageElement != null) {
        imageUrl = imageElement.attributes['src'];
      }
    } catch (e) {
      // Se houver erro no parsing, continua sem imagem
      imageUrl = null;
    }

    // 2. Cria a URL do proxy se uma imagem foi encontrada
    String? proxyUrl;
    if (imageUrl != null) {
      proxyUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(imageUrl)}';
    }

    return Post(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Sem Título',
      content: rawContent,
      publishedDate: DateTime.tryParse(json['published'] ?? '')?.toLocal() ?? DateTime.now(),
      authorName: json['author']?['displayName'] ?? 'Autor Desconhecido',
      postUrl: json['url'] ?? '',
      originalImageUrl: imageUrl,
      proxyImageUrl: proxyUrl, // A mágica acontece aqui!
    );
  }
}