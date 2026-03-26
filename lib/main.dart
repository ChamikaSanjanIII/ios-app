import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  runApp(const CMoviezAdminApp());
}

class CMoviezAdminApp extends StatelessWidget {
  const CMoviezAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(brightness: Brightness.dark),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashPage();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const TabBarDemoPage();
        }
        return const LoginPage();
      },
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // Splash simply shows for slightly longer to give an app experience,
  // before the StreamBuilder takes over.
  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.film, size: 90, color: CupertinoColors.activeBlue),
            SizedBox(height: 20),
            Text(
              'CMoviez Admin',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            CupertinoActivityIndicator(radius: 15),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;

  void _login() async {
    if (_emailCtrl.text.isEmpty || _pwdCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Login Failed'),
          content: Text(e.toString()),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            )
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Login')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(CupertinoIcons.lock_circle_fill, size: 80, color: CupertinoColors.activeBlue),
              const SizedBox(height: 30),
              CupertinoTextField(
                controller: _emailCtrl,
                placeholder: 'Email',
                padding: const EdgeInsets.all(16),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: CupertinoColors.white),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _pwdCtrl,
                placeholder: 'Password',
                padding: const EdgeInsets.all(16),
                obscureText: true,
                style: const TextStyle(color: CupertinoColors.white),
              ),
              const SizedBox(height: 30),
              _loading 
                ? const Center(child: CupertinoActivityIndicator())
                : CupertinoButton.filled(
                    onPressed: _login,
                    child: const Text('Sign In'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// === Dashboard Base 
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
    TabData(pageLabel: 'Movies', iconName: 'homepod.and.appletv.fill', collection: 'movies'),
    TabData(pageLabel: 'TV Shows', iconName: 'video.badge.waveform.fill', collection: 'tvshows'),
    TabData(pageLabel: 'Anime', iconName: 'message.badge.waveform.fill', collection: 'anime'),
    TabData(pageLabel: 'Upcoming', iconName: 'apple.terminal.on.rectangle.fill', collection: 'upcoming'),
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
    if(mounted) setState(() => selectedTabIndex = index);
    tabController.animateTo(index);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = tabs[selectedTabIndex];

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(activeTab.pageLabel),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Logout', style: TextStyle(fontSize: 14)),
          onPressed: () => FirebaseAuth.instance.signOut(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => TMDBAddScreen(collection: activeTab.collection),
              ),
            );
          },
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: TabBarView(
              controller: tabController,
              children: tabs
                  .map((tab) => CollectionList(collection: tab.collection))
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

// === List of Existing Collection Documents
class CollectionList extends StatelessWidget {
  final String collection;
  const CollectionList({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100, bottom: 90),
      child: StreamBuilder<QuerySnapshot>(
        // Limiting to 50 for performance on mobile
        stream: FirebaseFirestore.instance.collection(collection).orderBy('title').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: CupertinoColors.white)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }
          
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text("No items found. Click '+' above to start adding.", style: TextStyle(color: CupertinoColors.systemGrey)),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.systemGrey.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 75,
                      decoration: BoxDecoration(
                        color: CupertinoColors.darkBackgroundGray,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: data['poster'] != null && data['poster'].toString().isNotEmpty
                          ? Image.network(data['poster'], fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(CupertinoIcons.film))
                          : const Icon(CupertinoIcons.film, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? 'Untitled', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CupertinoColors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${data['type']?.toString().toUpperCase() ?? ''} • ${data['year'] ?? ''}",
                            style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed, size: 22),
                      onPressed: () {
                         showCupertinoDialog(
                          context: context, 
                          builder: (ctx) => CupertinoAlertDialog(
                            title: const Text('Confirm Delete'),
                            content: Text("Are you sure you want to delete '${data['title']}'?"),
                            actions: [
                              CupertinoDialogAction(
                                isDestructiveAction: true, 
                                onPressed: () {
                                  doc.reference.delete();
                                  Navigator.pop(ctx);
                                }, 
                                child: const Text('Delete')
                              ),
                              CupertinoDialogAction(
                                isDefaultAction: true, 
                                onPressed: () => Navigator.pop(ctx), 
                                child: const Text('Cancel')
                              ),
                            ],
                          )
                        );
                      },
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// === TMDB Add Screen Modal
class TMDBAddScreen extends StatefulWidget {
  final String collection;
  const TMDBAddScreen({super.key, required this.collection});

  @override
  State<TMDBAddScreen> createState() => _TMDBAddScreenState();
}

class _TMDBAddScreenState extends State<TMDBAddScreen> {
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
      final res = await http.get(Uri.parse('https://api.themoviedb.org/3/search/multi?api_key=$tmdbKey&query=$q&page=1'));
      final data = jsonDecode(res.body);
      setState(() {
        searchResults = (data['results'] as List).where((item) => item['media_type'] != 'person').toList();
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
      final res = await http.get(Uri.parse('https://api.themoviedb.org/3/$type/${film['id']}?api_key=$tmdbKey'));
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
    final isMovie = widget.collection == 'movies' || widget.collection == 'anime';
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
      if (selectedFilm!['poster_path'] != null) 'poster': 'https://image.tmdb.org/t/p/original${selectedFilm!['poster_path']}',
      if (selectedFilm!['backdrop_path'] != null) 'backdrop': 'https://image.tmdb.org/t/p/original${selectedFilm!['backdrop_path']}',
      if (selectedFilm!['vote_average'] != null) 'rating': selectedFilm!['vote_average'].toString(),
      'type': type,
      'genres': genresStr,
      'year': year,
      'tmdbId': selectedFilm!['id'],
      if (downloadUrlCtrl.text.trim().isNotEmpty) 'downloadUrl': downloadUrlCtrl.text.trim(),
    };
    
    try {
      await FirebaseFirestore.instance.collection(widget.collection).add(data);
      if (mounted) Navigator.pop(context); // Go back on success
    } catch (e) {
       if (!mounted) return;
       showCupertinoDialog(
        context: context, 
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Could not save: $e'),
          actions: [
            CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(ctx))
          ],
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('New in ${widget.collection}'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero, 
          child: const Row(children: [Icon(CupertinoIcons.back), Text('Back')]), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CupertinoSearchTextField(
                controller: searchCtrl,
                placeholder: 'Search TMDB...',
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
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f['title'] ?? f['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.white)),
                              const SizedBox(height: 4),
                              Text("${f['media_type']?.toUpperCase() ?? ''} - ${f['release_date'] ?? f['first_air_date'] ?? ''}", style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 12)),
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
                        Text('Ready to Add:\n${selectedFilm!['title'] ?? selectedFilm!['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
                        const SizedBox(height: 16),
                        CupertinoTextField(controller: titleCtrl, placeholder: 'Override Title', style: const TextStyle(color: CupertinoColors.white), padding: const EdgeInsets.all(12)),
                        const SizedBox(height: 16),
                        CupertinoTextField(controller: downloadUrlCtrl, placeholder: 'Download / Embed URL', style: const TextStyle(color: CupertinoColors.white), padding: const EdgeInsets.all(12)),
                        const SizedBox(height: 24),
                        CupertinoButton.filled(onPressed: saveFilm, child: const Text('Save to Firebase')),
                        const SizedBox(height: 12),
                        CupertinoButton(onPressed: () => setState(() => selectedFilm = null), child: const Text('Cancel')),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}