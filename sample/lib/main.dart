import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'models/user.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/video_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/shop_owner_home_screen.dart';
import 'screens/shop_video_management_screen.dart';
import 'screens/shop_commerce_management_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ramen Map',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  UserSession? _session;
  bool _showSignup = false;

  void _onLoginSuccess(UserSession session) {
    setState(() {
      _session = session;
      _showSignup = false;
    });
  }

  void _onLogout() {
    setState(() {
      _session = null;
      _showSignup = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      if (_showSignup) {
        return SignupScreen(
          onSignupCancel: () => setState(() => _showSignup = false),
          onSignupSuccess: _onLoginSuccess,
        );
      }

      return LoginScreen(
        onLoginSuccess: _onLoginSuccess,
        onSignupTap: () => setState(() => _showSignup = true),
      );
    }

    if (_session!.isShopOwner) {
      return ShopOwnerDashboard(
        session: _session!,
        onLogout: _onLogout,
      );
    }

    return RegularUserDashboard(
      session: _session!,
      onLogout: _onLogout,
    );
  }
}

class RegularUserDashboard extends StatelessWidget {
  final UserSession session;
  final VoidCallback onLogout;

  const RegularUserDashboard({
    super.key,
    required this.session,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final user = session.userAccount as RegularUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('ようこそ ${user.username} さん'),
        actions: [
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuCard(
            title: 'ラーメンフィード',
            subtitle: '店舗情報と投稿をチェック',
            icon: Icons.ramen_dining,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
          ),
          _MenuCard(
            title: '地図で探す',
            subtitle: '近くのラーメン屋を表示',
            icon: Icons.map,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            ),
          ),
          _MenuCard(
            title: '動画を見る / アップロード',
            subtitle: '投稿と再生を楽しむ',
            icon: Icons.play_circle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VideoScreen(userSession: session)),
            ),
          ),
          _MenuCard(
            title: '通販',
            subtitle: '公式店舗の商品を購入',
            icon: Icons.shopping_bag,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ShopScreen(userSession: session)),
            ),
          ),
          _MenuCard(
            title: 'プロフィール',
            subtitle: 'アカウント情報を確認',
            icon: Icons.person,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  userSession: session,
                  myUploadedVideos: const [],
                  onLogout: onLogout,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShopOwnerDashboard extends StatelessWidget {
  final UserSession session;
  final VoidCallback onLogout;

  const ShopOwnerDashboard({
    super.key,
    required this.session,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final owner = session.userAccount as ShopOwner;
    return Scaffold(
      appBar: AppBar(
        title: Text('店舗管理: ${owner.shopName}'),
        actions: [
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuCard(
            title: 'ダッシュボード',
            subtitle: '店舗の統計と概要',
            icon: Icons.dashboard,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ShopOwnerHomeScreen(userSession: session)),
            ),
          ),
          _MenuCard(
            title: '動画管理',
            subtitle: '店舗動画を追加・削除',
            icon: Icons.video_library,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ShopVideoManagementScreen(userSession: session)),
            ),
          ),
          _MenuCard(
            title: '通販管理',
            subtitle: '商品登録と編集',
            icon: Icons.storefront,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ShopCommerceManagementScreen(userSession: session)),
            ),
          ),
          _MenuCard(
            title: 'プロフィール',
            subtitle: '店舗プロフィールを確認',
            icon: Icons.person,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  userSession: session,
                  myUploadedVideos: const [],
                  onLogout: onLogout,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Icon(icon, color: Colors.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
