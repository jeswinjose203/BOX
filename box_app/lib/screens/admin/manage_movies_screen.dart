import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageMoviesScreen extends StatefulWidget {
  const ManageMoviesScreen({super.key});

  @override
  State<ManageMoviesScreen> createState() => _ManageMoviesScreenState();
}

class _ManageMoviesScreenState extends State<ManageMoviesScreen> {
  List<dynamic> _movies = [];
  bool _loading = true;
  bool _submitting = false;
  final _titleCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _movies = await ApiService.getMovies();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      _dateCtrl.text = date.toIso8601String().split('T')[0];
    }
  }

  Future<void> _addMovie() async {
    if (_titleCtrl.text.isEmpty || _dateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in title and release date')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiService.createMovie(_titleCtrl.text.trim(), _dateCtrl.text.trim());
      _titleCtrl.clear();
      _dateCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Movie added!')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Movies')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Add Movie', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dateCtrl,
                  decoration: const InputDecoration(labelText: 'Release Date', suffixIcon: Icon(Icons.calendar_today)),
                  readOnly: true,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _submitting ? null : _addMovie,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Add Movie'),
                ),
                const SizedBox(height: 24),
                Text('Movies', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_movies.isEmpty) const Text('No movies yet'),
                ..._movies.map((m) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.movie),
                        title: Text(m['title'] ?? ''),
                        subtitle: Text('Release: ${m['release_date'] ?? 'N/A'}'),
                      ),
                    )),
              ],
            ),
    );
  }
}
