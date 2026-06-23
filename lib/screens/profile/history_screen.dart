import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/bet_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/user_provider.dart';
import '../../services/local_db_service.dart';
import '../../widgets/transaction_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<BetModel> _bets = [];
  List<TransactionModel> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = context.read<UserProvider>().user?.id;
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        LocalDbService.fetchBets(userId),
        LocalDbService.fetchTransactions(userId),
      ]);
      setState(() {
        _bets = results[0] as List<BetModel>;
        _transactions = results[1] as List<TransactionModel>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _shareHistory() {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final wins = _bets.where((b) => b.isWin).length;
    final losses = _bets.length - wins;

    Share.share(
      '📊 Meu histórico na ShekelStore!\n'
      '🏆 Vitórias: $wins\n'
      '💸 Derrotas: $losses\n'
      '💰 Saldo atual: ${user.shekelBalance} shekels\n'
      'Junte-se a mim! #ShekelStore',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareHistory),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.gold,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.gold,
          tabs: const [Tab(text: 'Apostas'), Tab(text: 'Transações')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : TabBarView(
              controller: _tabController,
              children: [
                _BetsTab(bets: _bets),
                _TransactionsTab(transactions: _transactions),
              ],
            ),
    );
  }
}

class _BetsTab extends StatelessWidget {
  final List<BetModel> bets;
  const _BetsTab({required this.bets});

  @override
  Widget build(BuildContext context) {
    if (bets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎲', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text('Nenhuma aposta ainda'),
          ],
        ),
      );
    }

    final wins = bets.where((b) => b.isWin).length;
    final losses = bets.length - wins;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SummaryItem(label: 'Vitórias', value: '$wins', color: AppTheme.success),
              Container(width: 1, height: 32, color: AppTheme.surfaceVariant),
              _SummaryItem(label: 'Derrotas', value: '$losses', color: AppTheme.error),
              Container(width: 1, height: 32, color: AppTheme.surfaceVariant),
              _SummaryItem(
                label: 'Taxa de vitória',
                value:
                    '${wins == 0 ? 0 : (wins / bets.length * 100).toStringAsFixed(0)}%',
                color: AppTheme.gold,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: bets.length,
            itemBuilder: (_, i) => _BetTile(bet: bets[i]),
          ),
        ),
      ],
    );
  }
}

class _BetTile extends StatelessWidget {
  final BetModel bet;
  const _BetTile({required this.bet});

  @override
  Widget build(BuildContext context) {
    final color = bet.isWin ? AppTheme.success : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(bet.gameEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bet.gameLabel,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(bet.createdAt.toLocal()),
                  style:
                      Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bet.isWin ? '+${bet.profit} 🪙' : '-${bet.amount} 🪙',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text('Apostou: ${bet.amount} 🪙',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  final List<TransactionModel> transactions;
  const _TransactionsTab({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💰', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text('Nenhuma transação ainda'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (_, i) => TransactionTile(transaction: transactions[i]),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
