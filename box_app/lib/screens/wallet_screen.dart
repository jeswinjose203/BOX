import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String _balance = '...';
  List<dynamic> _deposits = [];
  List<dynamic> _withdrawals = [];
  bool _loading = true;
  bool _submittingDeposit = false;
  bool _submittingWithdrawal = false;
  final _depositAmountCtrl = TextEditingController();
  final _utrCtrl = TextEditingController();
  final _withdrawAmountCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getBalance(),
        ApiService.getMyDeposits(),
        ApiService.getMyWithdrawals(),
      ]);
      if (!mounted) return;
      setState(() {
        _balance = (results[0] as Map)['balance']?.toString() ?? '0';
        _deposits = results[1] as List;
        _withdrawals = results[2] as List;
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

  Future<void> _requestDeposit() async {
    final amount = double.tryParse(_depositAmountCtrl.text);
    if (amount == null || _utrCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid amount and UTR')),
      );
      return;
    }
    setState(() => _submittingDeposit = true);
    try {
      await ApiService.requestDeposit(amount, _utrCtrl.text.trim());
      _depositAmountCtrl.clear();
      _utrCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deposit requested!')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submittingDeposit = false);
    }
  }

  Future<void> _requestWithdrawal() async {
    final amount = double.tryParse(_withdrawAmountCtrl.text);
    if (amount == null || _upiCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid amount and UPI ID')),
      );
      return;
    }
    setState(() => _submittingWithdrawal = true);
    try {
      await ApiService.requestWithdrawal(amount, _upiCtrl.text.trim());
      _withdrawAmountCtrl.clear();
      _upiCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal requested!')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submittingWithdrawal = false);
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
      appBar: AppBar(title: const Text('Wallet')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance_wallet, size: 48),
                          const SizedBox(height: 8),
                          Text('₹$_balance', style: Theme.of(context).textTheme.headlineMedium),
                          const Text('Available Balance'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Deposit section
                  Text('Request Deposit', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _depositAmountCtrl,
                    decoration: const InputDecoration(labelText: 'Amount (₹)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _utrCtrl,
                    decoration: const InputDecoration(labelText: 'UTR Number'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _submittingDeposit ? null : _requestDeposit,
                    child: _submittingDeposit
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Submit Deposit Request'),
                  ),
                  const SizedBox(height: 24),
                  // Withdrawal section
                  Text('Request Withdrawal', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _withdrawAmountCtrl,
                    decoration: const InputDecoration(labelText: 'Amount (₹)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _upiCtrl,
                    decoration: const InputDecoration(labelText: 'UPI ID'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _submittingWithdrawal ? null : _requestWithdrawal,
                    child: _submittingWithdrawal
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Submit Withdrawal Request'),
                  ),
                  const SizedBox(height: 24),
                  // Deposit history
                  Text('My Deposits', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_deposits.isEmpty) const Text('No deposits yet'),
                  ..._deposits.map((d) => Card(
                        child: ListTile(
                          title: Text('₹${d['amount']}'),
                          subtitle: Text('UTR: ${d['utr']}'),
                          trailing: Chip(
                            label: Text(d['status'] ?? 'PENDING', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: _statusColor(d['status'] ?? 'PENDING'),
                          ),
                        ),
                      )),
                  const SizedBox(height: 24),
                  // Withdrawal history
                  Text('My Withdrawals', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_withdrawals.isEmpty) const Text('No withdrawals yet'),
                  ..._withdrawals.map((w) => Card(
                        child: ListTile(
                          title: Text('₹${w['amount']}'),
                          subtitle: Text('UPI: ${w['upi_id']}'),
                          trailing: Chip(
                            label: Text(w['status'] ?? 'PENDING', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: _statusColor(w['status'] ?? 'PENDING'),
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}
