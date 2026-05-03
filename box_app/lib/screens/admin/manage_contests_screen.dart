import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageContestsScreen extends StatefulWidget {
  const ManageContestsScreen({super.key});

  @override
  State<ManageContestsScreen> createState() => _ManageContestsScreenState();
}

class _ManageContestsScreenState extends State<ManageContestsScreen> {
  List<dynamic> _contests = [];
  List<dynamic> _movies = [];
  bool _loading = true;
  bool _submitting = false;
  int? _selectedMovieId;
  final _feeCtrl = TextEditingController();
  final _typeCtrl = TextEditingController(text: 'opening_weekend');
  final _deadlineCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([ApiService.getContests(), ApiService.getMovies()]);
      if (!mounted) return;
      setState(() {
        _contests = results[0];
        _movies = results[1];
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

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) {
        final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        _deadlineCtrl.text = dt.toIso8601String();
      }
    }
  }

  Future<void> _createContest() async {
    final fee = double.tryParse(_feeCtrl.text);
    if (_selectedMovieId == null || fee == null || _typeCtrl.text.isEmpty || _deadlineCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill in all fields')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiService.createContest(_selectedMovieId!, fee, _typeCtrl.text.trim(), _deadlineCtrl.text.trim());
      _feeCtrl.clear();
      _deadlineCtrl.clear();
      _selectedMovieId = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contest created!')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _movieTitle(dynamic movieId) {
    final m = _movies.cast<Map>().where((m) => m['id'] == movieId).firstOrNull;
    return m?['title'] ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Contests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Create Contest', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedMovieId,
                  decoration: const InputDecoration(labelText: 'Movie'),
                  items: _movies.map<DropdownMenuItem<int>>((m) {
                    return DropdownMenuItem(value: m['id'] as int, child: Text(m['title']));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedMovieId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _feeCtrl,
                  decoration: const InputDecoration(labelText: 'Entry Fee (₹)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _typeCtrl,
                  decoration: const InputDecoration(labelText: 'Type (e.g. opening_weekend)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _deadlineCtrl,
                  decoration: const InputDecoration(labelText: 'Deadline', suffixIcon: Icon(Icons.calendar_today)),
                  readOnly: true,
                  onTap: _pickDeadline,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _submitting ? null : _createContest,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create Contest'),
                ),
                const SizedBox(height: 24),
                Text('Contests', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_contests.isEmpty) const Text('No contests yet'),
                ..._contests.map((c) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.emoji_events),
                        title: Text(_movieTitle(c['movie_id'])),
                        subtitle: Text('Fee: ₹${c['entry_fee']}  •  ${c['type']}\nDeadline: ${c['deadline'] ?? 'N/A'}'),
                        isThreeLine: true,
                      ),
                    )),
              ],
            ),
    );
  }
}
