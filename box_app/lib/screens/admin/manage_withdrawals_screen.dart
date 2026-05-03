import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageWithdrawalsScreen extends StatefulWidget {
  const ManageWithdrawalsScreen({super.key});

  @override
  State<ManageWithdrawalsScreen> createState() => _ManageWithdrawalsScreenState();
}

class _ManageWithdrawalsScreenState extends State<ManageWithdrawalsScreen> {
  List<dynamic> _withdrawals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _withdrawals = await ApiService.getAllWithdrawals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _approve(int id) async {
    try {
      await ApiService.approveWithdrawal(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved!')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _reject(int id) async {
    try {
      await ApiService.rejectWithdrawal(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected!')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Withdrawals')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _withdrawals.isEmpty
                  ? const Center(child: Text('No withdrawals'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _withdrawals.length,
                      itemBuilder: (ctx, i) {
                        final w = _withdrawals[i];
                        final status = (w['status'] ?? 'PENDING').toString().toUpperCase();
                        final isPending = status == 'PENDING';
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text('User #${w['user_id']}', style: Theme.of(context).textTheme.titleSmall)),
                                    Chip(
                                      label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      backgroundColor: _statusColor(status),
                                    ),
                                  ],
                                ),
                                Text('Amount: ₹${w['amount']}'),
                                Text('UPI: ${w['upi_id']}'),
                                if (isPending)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        FilledButton(
                                          onPressed: () => _approve(w['id']),
                                          child: const Text('Approve'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () => _reject(w['id']),
                                          child: const Text('Reject'),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
