import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/video_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/profile_screen.dart';
import 'models/user.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ラーメンマップ',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  UserSession? _userSession;
  bool _isSigningUp = false;

  void _handleLoginSuccess(UserSession session) {
    setState(() {
      _userSession = session;
      _isSigningUp = false;
    });
  }

  void _handleSignupTap() {
    setState(() {
      _isSigningUp = true;
    });
  }

  void _handleSignupCancel() {
    setState(() {
      _isSigningUp = false;
    });
  }

  void _handleLogout() {
    setState(() {
      _userSession = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userSession == null) {
      if (_isSigningUp) {
        return SignupScreen(
          onSignupCancel: _handleSignupCancel,
          onSignupSuccess: _handleLoginSuccess,
        );
      }
      return LoginScreen(
        onLoginSuccess: _handleLoginSuccess,
        onSignupTap: _handleSignupTap,
      );
    }

    return MainTabScreen(
      userSession: _userSession!,
      onLogout: _handleLogout,
    );
  }
}

class MainTabScreen extends StatefulWidget {
  final UserSession userSession;
  final VoidCallback onLogout;

  const MainTabScreen({
    Key? key,
    required this.userSession,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;
  late List<VideoItem> _myUploadedVideos;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _myUploadedVideos = [];
    
    _screens = [
      const HomeScreen(),
      const MapScreen(),
      VideoScreen(userSession: widget.userSession),
      const ShopScreen(),
      ProfileScreen(
        userSession: widget.userSession,
        myUploadedVideos: _myUploadedVideos,
        onLogout: widget.onLogout,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'フィード'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'マップ'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: '動画'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: '通販'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'プロフィール'),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
