import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ScoringScreen extends StatefulWidget {
  const ScoringScreen({super.key});

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen> {
  List<dynamic> _contests = [];
  List<dynamic> _leaderboard = [];
  int? _selectedContestId;
  final _actualCtrl = TextEditingController();
  bool _loading = true;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _contests = await ApiService.getContests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _runScoring() async {
    final val = double.tryParse(_actualCtrl.text);
    if (_selectedContestId == null || val == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select contest and enter actual value')),
      );
      return;
    }
    setState(() => _running = true);
    try {
      await ApiService.runScoring(_selectedContestId!, val);
      final lb = await ApiService.getLeaderboard(_selectedContestId!);
      if (!mounted) return;
      setState(() => _leaderboard = lb);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scoring complete!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _loadLeaderboard() async {
    if (_selectedContestId == null) return;
    try {
      final lb = await ApiService.getLeaderboard(_selectedContestId!);
      if (mounted) setState(() => _leaderboard = lb);
    } catch (_) {
      if (mounted) setState(() => _leaderboard = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scoring')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedContestId,
                  decoration: const InputDecoration(labelText: 'Select Contest'),
                  items: _contests.map<DropdownMenuItem<int>>((c) {
                    return DropdownMenuItem(value: c['id'] as int, child: Text('Contest #${c['id']} (${c['type']})'));
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedContestId = v;
                      _leaderboard = [];
                    });
                    _loadLeaderboard();
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _actualCtrl,
                  decoration: const InputDecoration(labelText: 'Actual Value (₹ Cr)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _running ? null : _runScoring,
                  icon: _running
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow),
                  label: const Text('Run Scoring'),
                ),
                if (_leaderboard.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Leaderboard', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Rank')),
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Score')),
                    ],
                    rows: _leaderboard.asMap().entries.map((e) {
                      final lb = e.value;
                      return DataRow(cells: [
                        DataCell(Text('${e.key + 1}')),
                        DataCell(Text(lb['username']?.toString() ?? 'User ${lb['user_id']}')),
                        DataCell(Text(lb['score']?.toString() ?? '-')),
                      ]);
                    }).toList(),
                  ),
                ],
              ],
            ),
    );
  }
}
