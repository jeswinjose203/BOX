import 'package:flutter/material.dart';
import 'services/api_service.dart';
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
import 'screens/admin/manage_withdrawals_screen.dart';
import 'screens/admin/scoring_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BoxOfficeApp());
}

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
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const StartupScreen(),
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
        '/admin/withdrawals': (_) => const ManageWithdrawalsScreen(),
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

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await ApiService.loadToken();
    String route = '/login';
    if (ApiService.isLoggedIn) {
      try {
        final me = await ApiService.getMe();
        route = me['is_admin'] == true ? '/admin' : '/dashboard';
      } catch (_) {
        await ApiService.clearToken();
      }
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}
