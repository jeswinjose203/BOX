import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/contest_detail_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/predictions_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/manage_movies_screen.dart';
import 'screens/admin/manage_contests_screen.dart';
import 'screens/admin/manage_deposits_screen.dart';
import 'screens/admin/scoring_screen.dart';

void main() => runApp(const BoxOfficeApp());

class BoxOfficeApp extends StatelessWidget {
  const BoxOfficeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Box Office Contest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/wallet': (_) => const WalletScreen(),
        '/predictions': (_) => const PredictionsScreen(),
        '/admin': (_) => const AdminDashboardScreen(),
        '/admin/movies': (_) => const ManageMoviesScreen(),
        '/admin/contests': (_) => const ManageContestsScreen(),
        '/admin/deposits': (_) => const ManageDepositsScreen(),
        '/admin/scoring': (_) => const ScoringScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/contest') {
          final contestId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (_) => ContestDetailScreen(contestId: contestId),
          );
        }
        return null;
      },
    );
  }
}
