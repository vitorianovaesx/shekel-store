import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/investment_asset.dart';
import '../../providers/investment_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/compass_service.dart';
import '../../services/audio_service.dart';
import 'rabbi_chat_screen.dart';

class InvestmentScreen extends StatelessWidget {
  const InvestmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CompassData>(
      stream: CompassService.stream,
      builder: (context, snapshot) {
        final compassData = snapshot.data;
        final isPointing = compassData?.isPointingAtIsrael ?? false;
        final isLoading = !snapshot.hasData && !snapshot.hasError;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Consumer<InvestmentProvider>(
              builder: (ctx, prov, _) => Text('Loja de Sião — Dia ${prov.dayCount}'),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _CompassIndicator(data: compassData, loading: isLoading),
              ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              const _InvestmentBody(),
              if (!isPointing && !isLoading)
                Positioned.fill(
                  child: _CompassLockOverlay(heading: compassData?.heading ?? 0),
                ),
              if (isLoading)
                const Positioned.fill(
                  child: _CalibrationOverlay(),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Compass Overlay ────────────────────────────────────────────────────────────

class _CompassIndicator extends StatelessWidget {
  final CompassData? data;
  final bool loading;
  const _CompassIndicator({required this.data, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Icon(Icons.explore, size: 20, color: AppTheme.textSecondary);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          data?.isPointingAtIsrael == true ? Icons.location_on : Icons.explore,
          size: 18,
          color: data?.isPointingAtIsrael == true ? AppTheme.success : AppTheme.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '${data?.heading.toStringAsFixed(0) ?? '--'}°',
          style: TextStyle(
            color: data?.isPointingAtIsrael == true ? AppTheme.success : AppTheme.error,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _CalibrationOverlay extends StatelessWidget {
  const _CalibrationOverlay();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppTheme.background,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            CircularProgressIndicator(color: AppTheme.gold, strokeWidth: 2),
            SizedBox(height: 16),
            Text('Calibrando bússola...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            SizedBox(height: 4),
            Text('Segure o celular na horizontal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _CompassLockOverlay extends StatelessWidget {
  final double heading;
  const _CompassLockOverlay({required this.heading});

  @override
  Widget build(BuildContext context) {
    final targetBearing = CompassService.israelBearing;
    final delta = heading - targetBearing;
    final normalized = ((delta + 180) % 360) - 180;
    final hint = normalized > 0 ? '← gire para a esquerda' : 'gire para a direita →';

    return ColoredBox(
      color: AppTheme.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/compass.png', width: 64, height: 64),
              const SizedBox(height: 20),
              Text(
                'Aponte para Israel',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Segure o celular plano e gire até o nordeste.',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              _AnimatedCompassNeedle(delta: delta),
              const SizedBox(height: 24),
              Text(
                '${heading.toStringAsFixed(0)}°  →  ${targetBearing.toStringAsFixed(0)}°',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                hint,
                style: const TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCompassNeedle extends StatelessWidget {
  final double delta;
  const _AnimatedCompassNeedle({required this.delta});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.surfaceVariant, width: 2),
            ),
          ),
          const Positioned(
            top: 8,
            child: Icon(Icons.location_on, size: 18, color: AppTheme.gold),
          ),
          // Rotating needle showing current direction
          Transform.rotate(
            angle: delta * pi / 180,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 4, height: 45, color: AppTheme.error),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(width: 4, height: 45, color: AppTheme.textSecondary),
              ],
            ),
          ),
          const Icon(Icons.smartphone, size: 20, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}

// ── Investment Body ─────────────────────────────────────────────────────────

class _InvestmentBody extends StatelessWidget {
  const _InvestmentBody();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final provider = context.watch<InvestmentProvider>();

    return Column(
      children: [
        _PortfolioHeader(
          balance: user?.shekelBalance ?? 0,
          committed: provider.totalCommitted,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            children: [
              const SizedBox(height: 8),
              ...InvestmentAsset.all.map(
                (asset) => _AssetCard(asset: asset),
              ),
            ],
          ),
        ),
        _BottomBar(),
      ],
    );
  }
}

class _PortfolioHeader extends StatelessWidget {
  final int balance;
  final int committed;
  const _PortfolioHeader({required this.balance, required this.committed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Text('${balance - committed} ₪ disponível',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          if (committed > 0)
            Text('carrinho: $committed ₪',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Asset Card ──────────────────────────────────────────────────────────────

class _AssetCard extends StatefulWidget {
  final InvestmentAsset asset;
  const _AssetCard({required this.asset});

  @override
  State<_AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends State<_AssetCard> {
  final _controller = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAmountSubmit(InvestmentProvider provider, int userBalance) {
    final amount = int.tryParse(_controller.text) ?? 0;
    final ok = provider.setInvestment(widget.asset.id, amount, userBalance);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saldo insuficiente, oy vey! Você não é o Rothschild.'),
          backgroundColor: AppTheme.error,
        ),
      );
      _controller.text = (provider.investments[widget.asset.id] ?? 0).toString();
    } else if (amount > 0) {
      AudioService.playForAsset(widget.asset.id);
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvestmentProvider>();
    final userBalance = context.watch<UserProvider>().user?.shekelBalance ?? 0;
    final invested = provider.investments[widget.asset.id] ?? 0;
    final isLocked = provider.lockedAssets.contains(widget.asset.id);

    if (!_editing) {
      _controller.text = invested.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: invested > 0
              ? AppTheme.gold.withOpacity(0.4)
              : AppTheme.border,
          width: invested > 0 ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    widget.asset.imagePath,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.asset.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          if (widget.asset.alwaysLoss) ...[
                            const SizedBox(width: 6),
                            Text(
                              'sempre perde',
                              style: TextStyle(
                                color: AppTheme.error,
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        widget.asset.description,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _editing = true),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _editing ? AppTheme.gold : AppTheme.border,
                        ),
                      ),
                      child: _editing
                          ? TextField(
                              controller: _controller,
                              autofocus: true,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 14),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                filled: false,
                                suffixText: '₪',
                                suffixStyle:
                                    TextStyle(color: AppTheme.textSecondary),
                              ),
                              onSubmitted: (_) =>
                                  _onAmountSubmit(provider, userBalance),
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                invested > 0 ? '$invested ₪' : 'Comprar...',
                                style: TextStyle(
                                  color: invested > 0
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                ...[50, 100, 500].map((amt) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: GestureDetector(
                        onTap: () {
                          final current =
                              provider.investments[widget.asset.id] ?? 0;
                          final ok = provider.setInvestment(
                              widget.asset.id, current + amt, userBalance);
                          _controller.text =
                              (provider.investments[widget.asset.id] ?? 0)
                                  .toString();
                          if (ok) AudioService.playForAsset(widget.asset.id);
                        },
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '+$amt',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    )),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => provider.toggleLock(widget.asset.id),
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? AppTheme.gold.withOpacity(0.1)
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isLocked
                            ? AppTheme.gold.withOpacity(0.5)
                            : AppTheme.border,
                      ),
                    ),
                    child: Icon(
                      isLocked ? Icons.lock : Icons.lock_open,
                      size: 16,
                      color:
                          isLocked ? AppTheme.gold : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvestmentProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RabbiChatScreen()),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: provider.rabbiConsulted
                    ? AppTheme.success
                    : AppTheme.textSecondary,
                side: BorderSide(
                  color: provider.rabbiConsulted
                      ? AppTheme.success
                      : AppTheme.border,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology,
                      size: 16,
                      color: provider.rabbiConsulted
                          ? AppTheme.success
                          : AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    provider.rabbiConsulted ? 'Rabi consultado' : 'Consultar Rabi',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: provider.totalCommitted > 0
                  ? () => _showPassDayConfirm(context, provider)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Próximo Dia', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  SizedBox(width: 6),
                  Icon(Icons.skip_next, size: 18, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPassDayConfirm(BuildContext context, InvestmentProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Avançar para o próximo dia?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Carrinho: ${provider.totalCommitted} ₪',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (provider.rabbiConsulted) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.warning_amber, size: 14, color: AppTheme.warning),
                  SizedBox(width: 4),
                  Text('Taxa do Rabi: -10% dos lucros brutos',
                      style: TextStyle(color: AppTheme.warning, fontSize: 13)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Os multiplicadores de cada item serão revelados.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _passDay(context);
            },
            child: const Text('Shalom, passar!'),
          ),
        ],
      ),
    );
  }

  void _passDay(BuildContext context) {
    final provider = context.read<InvestmentProvider>();
    final userProvider = context.read<UserProvider>();
    final results = provider.passDay(userProvider);

    if (results.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(results['error'] as String),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if ((results['netChange'] as int) < 0) {
      AudioService.play(AudioService.loss);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DayResultsSheet(results: results),
    );
  }
}

// ── Day Results Sheet ─────────────────────────────────────────────────────────

class _DayResultsSheet extends StatelessWidget {
  final Map<String, dynamic> results;
  const _DayResultsSheet({required this.results});

  @override
  Widget build(BuildContext context) {
    final dayCount = results['dayCount'] as int;
    final totalInvested = results['totalInvested'] as int;
    final totalNet = results['totalNet'] as int;
    final netChange = results['netChange'] as int;
    final rabbiPenalty = results['rabbiPenalty'] as int;
    final assetResults =
        results['assetResults'] as Map<String, Map<String, dynamic>>;

    final isProfit = netChange >= 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Icon(
                isProfit ? Icons.trending_up : Icons.trending_down,
                size: 48,
                color: isProfit ? AppTheme.success : AppTheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Resultado do Dia $dayCount',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 20),
            // Per-asset results
            ...assetResults.entries.map((entry) {
              final asset = InvestmentAsset.all
                  .firstWhere((a) => a.id == entry.key);
              final r = entry.value;
              final mult = r['multiplier'] as double;
              final profit = r['profit'] as int;
              final isGain = profit >= 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        asset.imagePath,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Investido: ${r['invested']} ₪ × ${mult.toStringAsFixed(3)}x',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${r['earned']} ₪',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${isGain ? '+' : ''}$profit ₪',
                          style: TextStyle(
                            color: isGain ? AppTheme.success : AppTheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (rabbiPenalty > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.warning.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, size: 24, color: AppTheme.warning),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Taxa de sabedoria do Rabi',
                        style: TextStyle(color: AppTheme.warning),
                      ),
                    ),
                    Text(
                      '-$rabbiPenalty ₪',
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(color: AppTheme.surfaceVariant),
            // Summary
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Gasto',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  Text('$totalInvested ₪'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Recebido',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  Text('$totalNet ₪'),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isProfit ? Icons.savings : Icons.money_off,
                        size: 18,
                        color: isProfit ? AppTheme.success : AppTheme.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isProfit ? 'Lucro Líquido' : 'Prejuízo',
                        style: TextStyle(
                          color: isProfit ? AppTheme.success : AppTheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${isProfit ? '+' : ''}$netChange ₪',
                    style: TextStyle(
                      color: isProfit ? AppTheme.success : AppTheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                isProfit
                    ? _profitQuote()
                    : _lossQuote(),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Começar o Próximo Dia'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _profitQuote() {
    const quotes = [
      '"Como diria meu pai: guardai os shekels hoje, para gastá-los amanhã no Shabbat."',
      '"Mazal Tov! O Talmude não previu isso, mas eu sim."',
      '"Um dia bom de investimento compensa três dias no IDF S.A."',
    ];
    return quotes[Random().nextInt(quotes.length)];
  }

  String _lossQuote() {
    const quotes = [
      '"Shiva pelo seu saldo. Que ele descanse em paz."',
      '"Não se preocupe. Pior que o IDF S.A. é difícil."',
      '"O deserto tem 40 anos. Seu portfólio tem essa semana."',
    ];
    return quotes[Random().nextInt(quotes.length)];
  }
}
