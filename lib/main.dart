import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB9861C7yYzMxiWNgKOE_QATGjpQNQC-Yg",
        authDomain: "cmovies-site.firebaseapp.com",
        projectId: "cmovies-site",
        storageBucket: "cmovies-site.firebasestorage.app",
        messagingSenderId: "282382719174",
        appId: "1:282382719174:web:62a127125db697e963dfc7",
        measurementId: "G-254DBFHY4J",
      ),
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(
    CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(brightness: Brightness.dark),
      home: TabBarDemoPage(),
    ),
  );
}

class TabBarDemoPage extends StatefulWidget {
  const TabBarDemoPage({super.key});

  @override
  State<TabBarDemoPage> createState() => _TabBarDemoPageState();
}

class TabData {
  final String pageLabel;
  final String iconName;
  final String collection;

  TabData({required this.pageLabel, required this.iconName, required this.collection});
}

class _TabBarDemoPageState extends State<TabBarDemoPage> with SingleTickerProviderStateMixin {
  late TabController tabController;
  int selectedTabIndex = 0;

  final List<TabData> tabs = [
    TabData(pageLabel: 'Movies', iconName: 'film.fill', collection: 'movies'),
    TabData(pageLabel: 'TV Shows', iconName: 'tv.fill', collection: 'tvshows'),
    TabData(pageLabel: 'Anime', iconName: 'star.fill', collection: 'anime'),
    TabData(pageLabel: 'Upcoming', iconName: 'calendar.circle.fill', collection: 'upcoming'),
  ];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: tabs.length, vsync: this);
    tabController.addListener(updateTabIndex);
  }

  void updateTabIndex() {
    if (tabController.index != selectedTabIndex) {
      if(mounted) {
        setState(() {
          selectedTabIndex = tabController.index;
        });
      }
    }
  }

  void onTabTap(int index) {
    if(mounted) {
      setState(() {
        selectedTabIndex = index;
      });
    }
    tabController.animateTo(index);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('CMoviez Dashboard'),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: TabBarView(
              controller: tabController,
              children: tabs
                  .map((tab) => FilmDashboardTab(collection: tab.collection))
                  .toList(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: CNTabBar(
              items: tabs
                  .map(
                    (tab) => CNTabBarItem(
                      label: tab.pageLabel,
                      icon: CNSymbol(tab.iconName),
                    ),
                  )
                  .toList(),
              currentIndex: selectedTabIndex,
              tint: CupertinoColors.destructiveRed,
              height: 85,
              onTap: onTabTap,
            ),
          ),
        ],
      ),
    );
  }
}

class FilmDashboardTab extends StatefulWidget {
  final String collection;
  const FilmDashboardTab({super.key, required this.collection});

  @override
  State<FilmDashboardTab> createState() => _FilmDashboardTabState();
}

class _FilmDashboardTabState extends State<FilmDashboardTab> {
  final TextEditingController searchCtrl = TextEditingController();
  List<dynamic> searchResults = [];
  bool searching = false;
  Map<String, dynamic>? selectedFilm;

  final TextEditingController downloadUrlCtrl = TextEditingController();
  final TextEditingController titleCtrl = TextEditingController();

  final tmdbKey = '40b557990477e6f677364ac110f530e7';

  void searchTMDB() async {
    final q = searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      searching = true;
      searchResults = [];
      selectedFilm = null;
    });
    try {
      final res = await http.get(Uri.parse(
          'https://api.themoviedb.org/3/search/multi?api_key=$tmdbKey&query=$q&page=1'));
      final data = jsonDecode(res.body);
      setState(() {
        searchResults = (data['results'] as List)
            .where((item) => item['media_type'] != 'person')
            .toList();
      });
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  void selectFilm(Map<String, dynamic> film) async {
    setState(() => searching = true);
    try {
      final type = film['media_type'] ?? (widget.collection == 'movies' ? 'movie' : 'tv');
      final res = await http.get(Uri.parse(
          'https://api.themoviedb.org/3/$type/${film['id']}?api_key=$tmdbKey'));
      final data = jsonDecode(res.body);
      setState(() {
        selectedFilm = data;
        titleCtrl.text = data['title'] ?? data['name'] ?? '';
      });
    } catch (e) {
      debugPrint("Error details: $e");
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  void saveFilm() async {
    if (selectedFilm == null) return;
    
    // Convert to exactly what CollectionView.jsx did
    final isMovie = widget.collection == 'movies' || widget.collection == 'anime'; // approximate
    final type = isMovie ? 'movie' : 'tv';
    
    String genresStr = '';
    if (selectedFilm!['genres'] != null) {
      genresStr = (selectedFilm!['genres'] as List).map((g) => g['name']).join(', ');
    }
    
    String year = '';
    final rawDate = selectedFilm!['release_date'] ?? selectedFilm!['first_air_date'];
    if (rawDate != null && rawDate.toString().isNotEmpty) {
      year = rawDate.toString().split('-').first;
    }

    final data = {
      'title': titleCtrl.text,
      'description': selectedFilm!['overview'] ?? '',
      if (selectedFilm!['poster_path'] != null)
        'poster': 'https://image.tmdb.org/t/p/original${selectedFilm!['poster_path']}',
      if (selectedFilm!['backdrop_path'] != null)
        'backdrop': 'https://image.tmdb.org/t/p/original${selectedFilm!['backdrop_path']}',
      if (selectedFilm!['vote_average'] != null)
        'rating': selectedFilm!['vote_average'].toString(),
      'type': type,
      'genres': genresStr,
      'year': year,
      'tmdbId': selectedFilm!['id'],
      if (downloadUrlCtrl.text.trim().isNotEmpty)
        'downloadUrl': downloadUrlCtrl.text.trim(),
    };
    
    try {
      await FirebaseFirestore.instance.collection(widget.collection).add(data);
      
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Success'),
          content: Text('${titleCtrl.text} added to ${widget.collection}!'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            )
          ],
        ),
      );
      
      setState(() {
        selectedFilm = null;
        downloadUrlCtrl.clear();
        titleCtrl.clear();
        searchCtrl.clear();
        searchResults = [];
      });
    } catch (e) {
      debugPrint("Error saving: $e");
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Could not save: $e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100, bottom: 90, left: 16, right: 16),
      child: Column(
        children: [
          CupertinoSearchTextField(
            controller: searchCtrl,
            placeholder: 'Search TMDB for ${widget.collection}...',
            onSubmitted: (_) => searchTMDB(),
            style: const TextStyle(color: CupertinoColors.white),
          ),
          const SizedBox(height: 10),
          if (searching) const CupertinoActivityIndicator(),
          if (selectedFilm == null && !searching)
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (ctx, i) {
                  final f = searchResults[i];
                  return GestureDetector(
                    onTap: () => selectFilm(f),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f['title'] ?? f['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (f['media_type']?.toUpperCase() ?? '') + " - " + (f['release_date'] ?? f['first_air_date'] ?? ''),
                            style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (selectedFilm != null)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ready to Add:\n${selectedFilm!['title'] ?? selectedFilm!['name']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                    ),
                    const SizedBox(height: 16),
                    CupertinoTextField(
                      controller: titleCtrl,
                      placeholder: 'Override Title (Optional)',
                      style: const TextStyle(color: CupertinoColors.white),
                    ),
                    const SizedBox(height: 16),
                    CupertinoTextField(
                      controller: downloadUrlCtrl,
                      placeholder: 'Download / Embed URL',
                      style: const TextStyle(color: CupertinoColors.white),
                    ),
                    const SizedBox(height: 24),
                    CupertinoButton.filled(
                      onPressed: saveFilm,
                      child: Text('Save to ${widget.collection}'),
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      onPressed: () => setState(() => selectedFilm = null),
                      child: const Text('Cancel / Go Back'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}