import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/investment_asset.dart';
import 'user_provider.dart';

class InvestmentProvider extends ChangeNotifier {
  final _rng = Random();

  // assetId -> amount committed this cycle
  Map<String, int> _investments = {};
  // assetIds with auto-reinvest lock
  final Set<String> _lockedAssets = {};
  // multipliers that WILL apply on next passDay
  Map<String, double> _pendingMultipliers = {};
  // whether rabbi was consulted this cycle (costs 10%)
  bool _rabbiConsulted = false;
  int _dayCount = 1;
  Map<String, dynamic>? _lastResults;

  Map<String, int> get investments => Map.unmodifiable(_investments);
  Set<String> get lockedAssets => Set.unmodifiable(_lockedAssets);
  Map<String, double> get pendingMultipliers => Map.unmodifiable(_pendingMultipliers);
  bool get rabbiConsulted => _rabbiConsulted;
  int get dayCount => _dayCount;
  Map<String, dynamic>? get lastResults => _lastResults;

  int get totalCommitted => _investments.values.fold(0, (a, b) => a + b);

  int projectedEarnings() {
    int total = _investments.entries.fold(0, (sum, e) {
      return sum + (e.value * (_pendingMultipliers[e.key] ?? 1.0)).round();
    });
    if (_rabbiConsulted) total = (total * 0.9).round();
    return total;
  }

  void initialize() {
    _pendingMultipliers = _generateMultipliers();
    notifyListeners();
  }

  // Returns false if user can't afford the total commitment
  bool setInvestment(String assetId, int amount, int userBalance) {
    final othersTotal = totalCommitted - (_investments[assetId] ?? 0);
    if (othersTotal + amount > userBalance) return false;
    if (amount <= 0) {
      _investments.remove(assetId);
    } else {
      _investments[assetId] = amount;
    }
    notifyListeners();
    return true;
  }

  void toggleLock(String assetId) {
    if (_lockedAssets.contains(assetId)) {
      _lockedAssets.remove(assetId);
    } else {
      _lockedAssets.add(assetId);
    }
    notifyListeners();
  }

  void consultRabbi() {
    _rabbiConsulted = true;
    notifyListeners();
  }

  // Applies pending multipliers, updates balance, resets state
  Map<String, dynamic> passDay(UserProvider userProvider) {
    if (_investments.isEmpty) {
      return {'error': 'Carrinho vazio! Compre algo antes de passar o dia, meshugener!'};
    }

    final assetResults = <String, Map<String, dynamic>>{};
    int totalInvested = 0;
    int totalGross = 0;

    for (final entry in _investments.entries) {
      if (entry.value <= 0) continue;
      final mult = _pendingMultipliers[entry.key] ?? 1.0;
      final earned = (entry.value * mult).round();
      assetResults[entry.key] = {
        'invested': entry.value,
        'multiplier': mult,
        'earned': earned,
        'profit': earned - entry.value,
      };
      totalInvested += entry.value;
      totalGross += earned;
    }

    int rabbiPenalty = 0;
    if (_rabbiConsulted && totalGross > 0) {
      rabbiPenalty = (totalGross * 0.10).round();
    }
    final totalNet = totalGross - rabbiPenalty;

    // Net balance change: we get back totalNet but had invested totalInvested
    final netChange = totalNet - totalInvested;
    userProvider.addToBalance(netChange);

    final results = {
      'dayCount': _dayCount,
      'totalInvested': totalInvested,
      'totalGross': totalGross,
      'totalNet': totalNet,
      'netChange': netChange,
      'rabbiPenalty': rabbiPenalty,
      'assetResults': assetResults,
    };

    _lastResults = results;
    _dayCount++;
    _rabbiConsulted = false;

    // Preserve locked investments for next cycle
    final newInvestments = <String, int>{};
    for (final assetId in _lockedAssets) {
      if (_investments.containsKey(assetId)) {
        newInvestments[assetId] = _investments[assetId]!;
      }
    }
    _investments = newInvestments;

    // New multipliers for next cycle
    _pendingMultipliers = _generateMultipliers();

    notifyListeners();
    return results;
  }

  Map<String, double> _generateMultipliers() {
    return {
      for (final asset in InvestmentAsset.all) asset.id: asset.generateMultiplier(_rng),
    };
  }
}
