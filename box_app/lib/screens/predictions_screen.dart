import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  List<dynamic> _contests = [];
  Map<int, List<dynamic>> _predictionsByContest = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final me = await ApiService.getMe();
      final myId = me['id'];
      final contests = await ApiService.getContests();
      final Map<int, List<dynamic>> grouped = {};
      for (final c in contests) {
        try {
          final preds = await ApiService.getContestPredictions(c['id']);
          final mine = preds.where((p) => p['user_id'] == myId).toList();
          if (mine.isNotEmpty) grouped[c['id'] as int] = mine;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _contests = contests;
        _predictionsByContest = grouped;
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

  String _contestLabel(int contestId) {
    final c = _contests.cast<Map>().where((c) => c['id'] == contestId).firstOrNull;
    return c != null ? 'Contest #$contestId (${c['type']})' : 'Contest #$contestId';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Predictions')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _predictionsByContest.isEmpty
              ? const Center(child: Text('No predictions yet'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: _predictionsByContest.entries.map((entry) {
                      return Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(_contestLabel(entry.key),
                                  style: Theme.of(context).textTheme.titleSmall),
                            ),
                            ...entry.value.map((p) => ListTile(
                                  leading: const Icon(Icons.analytics),
                                  title: Text('Predicted: ₹${p['predicted_value']} Cr'),
                                  trailing: p['score'] != null
                                      ? Chip(label: Text('Score: ${p['score']}'))
                                      : const Chip(label: Text('Pending')),
                                )),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
