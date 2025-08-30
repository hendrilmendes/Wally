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

  factory Post.fromBloggerJson(Map<String, dynamic> json) {
    String rawContent = json['content'] ?? '';

    String? imageUrl;
    try {
      var document = parse(rawContent);
      var imageElement = document.querySelector('img');
      if (imageElement != null) {
        imageUrl = imageElement.attributes['src'];
      }
    } catch (e) {
      imageUrl = null;
    }

    String? proxyUrl;
    if (imageUrl != null) {
      proxyUrl =
          'https://api.allorigins.win/raw?url=${Uri.encodeComponent(imageUrl)}';
    }

    return Post(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Sem Título',
      content: rawContent,
      publishedDate:
          DateTime.tryParse(json['published'] ?? '')?.toLocal() ??
          DateTime.now(),
      authorName: json['author']?['displayName'] ?? 'Autor Desconhecido',
      postUrl: json['url'] ?? '',
      originalImageUrl: imageUrl,
      proxyImageUrl: proxyUrl,
    );
  }
}
