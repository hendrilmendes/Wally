// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

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
  double _fontSize = 16.0;

  void _sharePost() {
    Share.share(widget.url, subject: widget.title);
  }

  void _decrementFontSize() {
    setState(() => _fontSize = (_fontSize - 1.0).clamp(12.0, 24.0));
  }

  void _incrementFontSize() {
    setState(() => _fontSize = (_fontSize + 1.0).clamp(12.0, 24.0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withOpacity(0.2),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // AppBar com a lógica de título restaurada e estilizada
            SliverAppBar(
              backgroundColor: theme.colorScheme.surface.withOpacity(0.8),
              expandedHeight: size.height * 0.4,
              pinned: true,
              stretch: true,
              elevation: 0,
              leading: const BackButton(),
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final double top = constraints.biggest.height;
                  // Lógica para saber quando a AppBar está recolhida
                  final bool isCollapsed =
                      top <=
                      kToolbarHeight + MediaQuery.of(context).padding.top;

                  return FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Imagem de fundo
                        Hero(
                          tag: widget.imageUrl.isNotEmpty
                              ? widget.imageUrl
                              : widget.postId,
                          child: widget.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.imageUrl,
                                  fit: BoxFit.cover,
                                  progressIndicatorBuilder:
                                      (context, url, downloadProgress) =>
                                          Center(
                                            child: CircularProgressIndicator(
                                              value: downloadProgress.progress,
                                              color: Colors.white70,
                                            ),
                                          ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.black26,
                                        child: const Icon(
                                          Icons.broken_image_rounded,
                                          color: Colors.white54,
                                          size: 56,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: theme.colorScheme.surfaceVariant,
                                ),
                        ),
                        // Gradiente para legibilidade
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.6],
                            ),
                          ),
                        ),
                        // LÓGICA DE TÍTULO RESTAURADA
                        // Título flutuante de vidro (só aparece quando a AppBar está expandida)
                        if (!isCollapsed)
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16.0),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface
                                          .withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(16.0),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(
                                      widget.title,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Título da AppBar (só aparece quando está recolhida)
                        if (isCollapsed)
                          Container(
                            alignment: Alignment.bottomLeft,
                            padding: const EdgeInsets.only(
                              left: 56,
                              right: 16,
                              bottom: 16,
                            ),
                            child: Text(
                              widget.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Corpo do artigo (sem alterações)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              sliver: SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(
                          0.4,
                        ),
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.formattedDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          HtmlWidget(
                            widget.content,
                            textStyle: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: _fontSize,
                              height: 1.7,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.5),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    tooltip: l10n.decrementText,
                    icon: const Icon(Icons.text_decrease_outlined),
                    onPressed: _decrementFontSize,
                    color: theme.colorScheme.onSurface,
                  ),
                  IconButton(
                    tooltip: l10n.incrementText,
                    icon: const Icon(Icons.text_increase_outlined),
                    onPressed: _incrementFontSize,
                    color: theme.colorScheme.onSurface,
                  ),
                  IconButton(
                    tooltip: l10n.shared,
                    icon: const Icon(Icons.share_outlined),
                    onPressed: _sharePost,
                    color: theme.colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
