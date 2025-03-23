import 'package:flutter/material.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:shimmer/shimmer.dart';

class PostDetailsScreen extends StatefulWidget {
  final String title;
  final String content;
  final String imageUrl;
  final String url;
  final String formattedDate;
  final String blogId;
  final String postId;

  const PostDetailsScreen({
    super.key,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.url,
    required this.formattedDate,
    required this.blogId,
    required this.postId,
  });

  @override
  // ignore: library_private_types_in_public_api
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  double _fontSize = 18.0;

  // Metodo para compartilhar os posts
  void sharePost(String shared) {
    Share.share(widget.url);
  }

  // Metodo para aumentar e diminuir tamanho do texto nos posts
  void _decrementFontSize() {
    setState(() {
      _fontSize -= 2.0;
    });
  }

  void _incrementFontSize() {
    setState(() {
      _fontSize += 2.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  FutureBuilder(
                    future: precacheImage(
                      NetworkImage(widget.imageUrl),
                      context,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                          child: Image.network(
                            widget.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        );
                      } else {
                        return Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                            child: Container(color: Colors.white),
                          ),
                        );
                      }
                    },
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 3.0,
                            color: Color.fromARGB(150, 0, 0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.formattedDate,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                HtmlWidget(
                  widget.content,
                  textStyle: TextStyle(fontSize: _fontSize),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),

      // Menu de ações na parte inferior
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: AppLocalizations.of(context)!.decrementText,
                icon: const Icon(Icons.text_decrease_outlined),
                onPressed: _decrementFontSize,
              ),
              IconButton(
                tooltip: AppLocalizations.of(context)!.incrementText,
                icon: const Icon(Icons.text_increase_outlined),
                onPressed: _incrementFontSize,
              ),
              IconButton(
                tooltip: AppLocalizations.of(context)!.shared,
                icon: const Icon(Icons.share),
                onPressed: () => sharePost(widget.url),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
