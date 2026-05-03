import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.movie, 'label': 'Manage Movies', 'route': '/admin/movies'},
      {'icon': Icons.emoji_events, 'label': 'Manage Contests', 'route': '/admin/contests'},
      {'icon': Icons.payments, 'label': 'Manage Deposits', 'route': '/admin/deposits'},
      {'icon': Icons.scoreboard, 'label': 'Run Scoring', 'route': '/admin/scoring'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.clearToken();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: items.map((item) {
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pushNamed(context, item['route'] as String),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'] as IconData, size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(item['label'] as String, textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
