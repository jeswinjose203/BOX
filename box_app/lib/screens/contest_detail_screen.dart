import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ContestDetailScreen extends StatefulWidget {
  final int contestId;
  const ContestDetailScreen({super.key, required this.contestId});

  @override
  State<ContestDetailScreen> createState() => _ContestDetailScreenState();
}

class _ContestDetailScreenState extends State<ContestDetailScreen> {
  Map<String, dynamic>? _contest;
  List<dynamic> _predictions = [];
  List<dynamic> _leaderboard = [];
  bool _loading = true;
  bool _joined = false;
  bool _predicted = false;
  final _predictionCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  int? _myUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final me = await ApiService.getMe();
      _myUserId = me['id'];
      final contest = await ApiService.getContest(widget.contestId);
      List<dynamic> preds = [];
      try {
        preds = await ApiService.getContestPredictions(widget.contestId);
      } catch (_) {}
      List<dynamic> lb = [];
      try {
        lb = await ApiService.getLeaderboard(widget.contestId);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _contest = contest;
        _predictions = preds;
        _leaderboard = lb;
        _joined = (contest['participants'] as List?)?.contains(_myUserId) ?? false;
        _predicted = preds.any((p) => p['user_id'] == _myUserId);
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

  Future<void> _join() async {
    final entryFee = (_contest!['entry_fee'] as num).toDouble();
    final amount = double.tryParse(_amountCtrl.text);
    final predictedValue = double.tryParse(_predictionCtrl.text);
    if (amount == null || amount < entryFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Minimum amount is ₹$entryFee')),
      );
      return;
    }
    if (predictedValue == null || predictedValue < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid predicted value (>= 0)')),
      );
      return;
    }
    try {
      await ApiService.joinContest(widget.contestId, amount, predictedValue);
      _amountCtrl.clear();
      _predictionCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined and prediction submitted!')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _predict() async {
    final val = double.tryParse(_predictionCtrl.text);
    if (val == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid number')));
      return;
    }
    try {
      await ApiService.createPrediction(widget.contestId, val);
      _predictionCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prediction submitted!')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contest Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _contest == null
              ? const Center(child: Text('Contest not found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Contest #${_contest!['id']}', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text('Type: ${_contest!['type']}'),
                              Text('Entry Fee: ₹${_contest!['entry_fee']}'),
                              Text('Deadline: ${_contest!['deadline'] ?? 'N/A'}'),
                              if (_contest!['is_distributed'] == true)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Chip(
                                    avatar: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                    label: const Text('Completed', style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_contest!['is_distributed'] != true && !_joined) ...[
                        Text('Join Contest', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Minimum: ₹${_contest!['entry_fee']}', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amountCtrl,
                          decoration: const InputDecoration(labelText: 'Amount (₹)'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _predictionCtrl,
                          decoration: const InputDecoration(labelText: 'Predicted Box Office (₹ Cr)'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed: _join,
                              icon: const Icon(Icons.add),
                              label: const Text('Join & Predict'),
                            ),
                          ],
                        ),
                      ],
                      if (_contest!['is_distributed'] != true && _joined && !_predicted) ...[
                        Text('Submit Prediction', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _predictionCtrl,
                                decoration: const InputDecoration(labelText: 'Predicted Value (₹ Cr)'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(onPressed: _predict, child: const Text('Submit')),
                          ],
                        ),
                      ],
                      if (_joined && _predicted)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.check_circle, color: Colors.green),
                            title: Text('Prediction submitted'),
                          ),
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
                ),
    );
  }
}
