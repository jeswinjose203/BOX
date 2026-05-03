import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;
  List<dynamic> _contests = [];
  List<dynamic> _movies = [];
  String _balance = '...';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getContests(),
        ApiService.getMovies(),
        ApiService.getBalance(),
      ]);
      if (!mounted) return;
      setState(() {
        _contests = results[0] as List;
        _movies = results[1] as List;
        _balance = (results[2] as Map)['balance']?.toString() ?? '0';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _movieTitle(dynamic movieId) {
    final movie = _movies.cast<Map>().where((m) => m['id'] == movieId).firstOrNull;
    return movie?['title'] ?? 'Unknown';
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Box Office Contest'),
        actions: [
          Chip(
            avatar: const Icon(Icons.account_balance_wallet, size: 18),
            label: Text('₹$_balance'),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _contests.isEmpty
                  ? const Center(child: Text('No contests available'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _contests.length,
                      itemBuilder: (ctx, i) {
                        final c = _contests[i];
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.emoji_events)),
                            title: Text(_movieTitle(c['movie_id'])),
                            subtitle: Text(
                              'Fee: ₹${c['entry_fee']}  •  Type: ${c['type']}\nDeadline: ${c['deadline'] ?? 'N/A'}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.pushNamed(context, '/contest', arguments: c['id']);
                              _load();
                            },
                          ),
                        );
                      },
                    ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          if (i == 1) {
            Navigator.pushNamed(context, '/wallet').then((_) => _load());
          } else if (i == 2) {
            Navigator.pushNamed(context, '/predictions');
          } else {
            setState(() => _navIndex = i);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Contests'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Predictions'),
        ],
      ),
    );
  }
}
