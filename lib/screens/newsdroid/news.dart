import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:projectx/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:projectx/widgets/newsdroid/post_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsApp extends StatefulWidget {
  const NewsApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NewsAppState createState() => _NewsAppState();
}

class _NewsAppState extends State<NewsApp> {
  List<dynamic> posts = [];
  List<dynamic> filteredPosts = [];

  bool isOnline = true;
  bool isLoading = false;
  late PageController _pageController;
  int _currentPage = 0;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    fetchPosts();
    _pageController = PageController(initialPage: 0);
    timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    timer.cancel();
    super.dispose();
  }

  // GET API
  Future<void> fetchPosts() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cachedPosts');
    if (cachedData != null) {
      final Map<String, dynamic> cachedPosts = jsonDecode(cachedData);
      final DateTime lastCachedTime = DateTime.parse(
        prefs.getString('cachedTime') ?? '',
      );
      final DateTime currentTime = DateTime.now();
      final difference = currentTime.difference(lastCachedTime).inMinutes;
      if (difference < 5) {
        // reutiliza os dados em cache se forem menos de 5 minutos de idade
        setState(() {
          posts = cachedPosts['items'];
          filteredPosts = posts;
          isLoading = false;
        });
        return;
      }
    }
    try {
      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/blogger/v3/blogs/3386768038934102311/posts?key=AIzaSyDnllJ2_CVl0wqYH-ZhgYnWw1BT42g5wZk&maxResults=100',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        prefs.setString('cachedPosts', response.body);
        prefs.setString('cachedTime', DateTime.now().toString());
        setState(() {
          posts = data['items'];
          filteredPosts = posts;
          isLoading = false;
        });
      } else {
        throw Exception("Falha ao buscar postagens");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String originalDate) {
    try {
      final parsedDate = DateTime.parse(originalDate).toLocal();
      return DateFormat('dd/MM/yyyy - HH:mm').format(parsedDate);
    } catch (e) {
      return "Data inválida";
    }
  }

  Future<void> _refreshPosts() async {
    await fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.newsdroidApp),
        actions: [
          FilledButton.tonal(
            onPressed: () {
              launchUrl(
                Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.github.hendrilmendes.news',
                ),
              );
            },
            child: Text((AppLocalizations.of(context)!.downloadApp)),
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator.adaptive())
              : PostListWidget(
                filteredPosts: filteredPosts,
                currentPage: _currentPage,
                pageController: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                onRefresh: _refreshPosts,
                formatDate: formatDate,
              ),
    );
  }
}
