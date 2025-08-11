import 'package:flutter/material.dart';
import 'login_page.dart';
import 'main.dart';
import 'profile_page.dart';
import 'laporan_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String laporan = '/laporan';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case home:
        return MaterialPageRoute(
          builder: (_) => const MyHomePage(title: 'Dimsum Gerobak'),
        );
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case laporan:
        return MaterialPageRoute(builder: (_) => const LaporanPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
