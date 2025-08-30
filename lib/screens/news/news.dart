// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:projectx/screens/news/posts/posts_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NewsApp extends StatefulWidget {
  const NewsApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NewsAppState createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
  List<dynamic> posts = [];
  bool isOnline = true;
  bool isLoading = false;
  late PageController _pageController;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _initialize();
  }

  Future<void> _initialize() async {
    await checkConnectivity();
    await fetchPosts();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoCarousel() {
    _carouselTimer?.cancel();
    if (posts.length > 1) {
      _carouselTimer = Timer.periodic(const Duration(seconds: 5), (
        Timer timer,
      ) {
        if (!mounted || !_pageController.hasClients || posts.isEmpty) {
          timer.cancel();
          return;
        }
        int nextPage = _pageController.page!.round() + 1;
        final int carouselItemCount = posts.length > 3 ? 3 : posts.length;
        if (nextPage >= carouselItemCount) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  Future<void> fetchPosts() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cachedPosts');
    if (cachedData != null) {
      final Map<String, dynamic> cachedPosts = jsonDecode(cachedData);
      final DateTime lastCachedTime = DateTime.parse(
        prefs.getString('cachedTime') ?? DateTime(1970).toString(),
      );
      if (DateTime.now().difference(lastCachedTime).inMinutes < 10 &&
          isOnline) {
        if (mounted) {
          setState(() {
            posts = cachedPosts['items'] ?? [];
            isLoading = false;
          });
          _startAutoCarousel();
          return;
        }
      }
    }
    if (!isOnline && cachedData == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
    try {
      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/blogger/v3/blogs/3386768038934102311/posts?key=AIzaSyDnllJ2_CVl0wqYH-ZhgYnWw1BT42g5wZk&maxResults=50&fetchImages=true',
        ),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        prefs.setString('cachedPosts', jsonEncode(data));
        prefs.setString('cachedTime', DateTime.now().toString());
        if (mounted) {
          setState(() {
            posts = data['items'] ?? [];
            isLoading = false;
          });
          _startAutoCarousel();
        }
      } else {
        throw Exception("Falha ao buscar postagens: ${response.statusCode}");
      }
    } catch (e) {
      if (kDebugMode) print("Erro ao buscar posts: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  String formatDate(String originalDate) {
    try {
      final parsedDate = DateTime.parse(originalDate).toLocal();
      return DateFormat('dd/MM/yyyy – HH:mm').format(parsedDate);
    } catch (e) {
      return "Data inválida";
    }
  }

  String? _getImageUrlFromPost(dynamic post) {
    if (post['images'] != null && (post['images'] as List).isNotEmpty) {
      String originalUrl = post['images'][0]['url'];

      originalUrl = originalUrl.replaceAll(RegExp(r'/s\d+(-c)?/'), '/s1600/');

      return originalUrl;
    }
    return null;
  }

  Future<void> checkConnectivity() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (mounted) {
      setState(
        () => isOnline = !connectivityResult.contains(ConnectivityResult.none),
      );
    }
  }

  Future<void> _refreshPosts() async {
    await checkConnectivity();
    await fetchPosts();
  }

  void _navigateToDetails(dynamic post) {
    final imageUrl = _getImageUrlFromPost(post);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailsScreen(
          title: post['title'] ?? 'Sem Título',
          content: post['content'] ?? '',
          imageUrl: imageUrl ?? '',
          url: post['url'] ?? '',
          formattedDate: formatDate(post['published']),
          blogId: post['blog']?['id'] ?? '',
          postId: post['id'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final featuredPosts = posts.take(3).toList();
    final remainingPosts = posts.length > 3 ? posts.sublist(3) : [];

    return Scaffold(
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
        child: RefreshIndicator(
          onRefresh: _refreshPosts,
          color: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surface,
          child: isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : posts.isEmpty
              ? _buildEmptyState(l10n)
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverAppBar(
                      title: Text(l10n.newsdroidApp),
                      elevation: 0,
                      pinned: true,
                      floating: true,
                      snap: true,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.7),
                      flexibleSpace: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      actions: [
                        _buildDownloadButton(l10n, theme),
                        const SizedBox(width: 8),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (featuredPosts.isNotEmpty)
                            _buildFeaturedCarousel(featuredPosts, theme),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildPostListItem(remainingPosts[index], theme),
                          childCount: remainingPosts.length,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton(AppLocalizations l10n, ThemeData theme) {
    return InkWell(
      onTap: () => launchUrl(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.github.hendrilmendes.news',
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.download_for_offline_outlined, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.downloadApp,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCarousel(List<dynamic> featuredPosts, ThemeData theme) {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _pageController,
        itemCount: featuredPosts.length,
        itemBuilder: (context, index) {
          final post = featuredPosts[index];
          final imageUrl = _getImageUrlFromPost(post);
          return _buildFeaturedPostCard(post, imageUrl, index, theme);
        },
      ),
    );
  }

  Widget _buildFeaturedPostCard(
    dynamic post,
    String? imageUrl,
    int index,
    ThemeData theme,
  ) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double scale = 1.0;
        if (_pageController.position.haveDimensions) {
          final double page = _pageController.page ?? 0.0;
          scale = (1 - (page - index).abs() * 0.15).clamp(0.85, 1.0);
        }
        return Transform.scale(scale: scale, child: child);
      },
      child: InkWell(
        onTap: () => _navigateToDetails(post),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                if (imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    progressIndicatorBuilder:
                        (context, url, downloadProgress) => Center(
                          child: CircularProgressIndicator(
                            value: downloadProgress.progress,
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white70,
                        size: 40,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          color: Colors.black.withOpacity(0.25),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['title'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  const Shadow(
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatDate(post['published']),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostListItem(dynamic post, ThemeData theme) {
    final imageUrl = _getImageUrlFromPost(post);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _navigateToDetails(post),
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.4,
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                children: [
                  if (imageUrl != null)
                    AspectRatio(
                      aspectRatio: 1,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) => Center(
                              child: CircularProgressIndicator.adaptive(
                                value: downloadProgress.progress,
                                strokeWidth: 2,
                              ),
                            ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['title'],
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatDate(post['published']),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOnline
                        ? Icons.newspaper_outlined
                        : Icons.wifi_off_outlined,
                    size: 80,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
