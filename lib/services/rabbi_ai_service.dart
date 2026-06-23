import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/investment_asset.dart';

class RabbiAiService {
  static const String rabbiName = 'Rabi Mordechai Ibn Shekel';

  static final _gemma = FlutterGemmaPlugin.instance;
  static InferenceModel? _model;

  // Broadcast controller so multiple screen instances share one download
  static StreamController<int>? _downloadCtrl;

  static String get _modelUrl => AppConstants.huggingFaceToken.isNotEmpty
      ? '${AppConstants.rabbiModelUrl}?token=${AppConstants.huggingFaceToken}'
      : AppConstants.rabbiModelUrl;

  static bool get isDownloading =>
      _downloadCtrl != null && !_downloadCtrl!.isClosed;

  /// Fast check via SharedPreferences — does not block on flutter_gemma internals.
  static Future<bool> isModelInstalled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.rabbiModelInstalledKey) ?? false;
  }

  /// Start a download (no-op if already in progress). Returns immediately.
  static void startDownload() {
    if (isDownloading) return;
    _downloadCtrl = StreamController<int>.broadcast();
    _runDownload();
  }

  static Future<void> _runDownload() async {
    try {
      await for (final pct
          in _gemma.modelManager.loadModelFromNetworkWithProgress(_modelUrl)) {
        _downloadCtrl?.add(pct);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.rabbiModelInstalledKey, true);
      await _downloadCtrl?.close();
      _downloadCtrl = null;
    } catch (e) {
      _downloadCtrl?.addError(e);
      await _downloadCtrl?.close();
      _downloadCtrl = null;
    }
  }

  /// Returns the shared broadcast stream (empty if not downloading).
  static Stream<int> get downloadProgress =>
      _downloadCtrl?.stream ?? const Stream.empty();

  static Future<void> resetModel() async {
    _model = null;
    _downloadCtrl?.close();
    _downloadCtrl = null;
    try {
      await _gemma.modelManager.deleteModel();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.rabbiModelInstalledKey, false);
  }

  static Future<void> _ensureModel() async {
    if (_model != null) return;
    _model = await _gemma.init(
      maxTokens: 512,
      temperature: 0.85,
      topK: 40,
    );
  }

  static Stream<String> getAdviceStream(Map<String, double> multipliers) async* {
    await _ensureModel();
    yield* _model!.getResponseAsync(
      prompt: _buildPrompt(multipliers),
      isChat: false,
    );
  }

  static String _buildPrompt(Map<String, double> multipliers) {
    final sorted = multipliers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final lines = sorted.map((e) {
      final asset = InvestmentAsset.all.firstWhere((a) => a.id == e.key);
      return '  ${asset.name}: ${e.value.toStringAsFixed(2)}x';
    }).join('\n');

    return 'Você é o Rabi Mordechai Ibn Shekel, consultor financeiro judeu dramático, sábio e levemente corrupto. '
        'Fale com sabedoria talmúdica misturada com referências bíblicas aplicadas a finanças. '
        'Use expressões em ídiche ocasionalmente. Seja engraçado e sarcástico. Você cobra 10%% dos lucros.\n\n'
        'Multiplicadores de hoje:\n$lines\n\n'
        'Analise os melhores e piores investimentos em 3-4 parágrafos curtos. Narre como um sábio, não liste. Responda em português.';
  }
}
