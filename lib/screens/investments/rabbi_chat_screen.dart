import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/investment_provider.dart';
import '../../services/rabbi_ai_service.dart';
import '../../services/audio_service.dart';

enum _State { checking, notInstalled, installing, installError, ready, consulting, done, error }

class RabbiChatScreen extends StatefulWidget {
  const RabbiChatScreen({super.key});

  @override
  State<RabbiChatScreen> createState() => _RabbiChatScreenState();
}

class _RabbiChatScreenState extends State<RabbiChatScreen> {
  _State _state = _State.checking;
  String _response = '';
  String _errorMessage = '';

  // Download progress: 0-100 from stream, or estimated via timer
  int _downloadProgress = 0;
  StreamSubscription<int>? _downloadSub;
  Timer? _estimateTimer;
  final _downloadStart = Stopwatch();

  @override
  void initState() {
    super.initState();
    AudioService.play(AudioService.rabbi);
    _checkModel();
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    _estimateTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkModel() async {
    // If a download is already running (user navigated away and back), reattach
    if (RabbiAiService.isDownloading) {
      setState(() => _state = _State.installing);
      _listenToDownload();
      return;
    }
    final installed = await RabbiAiService.isModelInstalled();
    if (!mounted) return;
    setState(() => _state = installed ? _State.ready : _State.notInstalled);
  }

  void _listenToDownload() {
    _downloadSub?.cancel();
    _downloadStart.reset();
    _downloadStart.start();
    _startEstimateTimer();

    _downloadSub = RabbiAiService.downloadProgress.listen(
      (pct) {
        if (!mounted) return;
        // Only update if the real value is higher than our estimate
        if (pct > _downloadProgress) {
          setState(() => _downloadProgress = pct);
        }
      },
      onDone: () {
        _estimateTimer?.cancel();
        if (!mounted) return;
        setState(() => _state = _State.ready);
      },
      onError: (e) {
        _estimateTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _state = _State.installError;
          _errorMessage = e.toString();
        });
      },
    );
  }

  // Smoothly animates 0→90% over ~4 min so the bar looks alive even if the
  // native EventChannel only fires a single event at completion.
  void _startEstimateTimer() {
    _estimateTimer?.cancel();
    const totalMs = 4 * 60 * 1000; // 4 minutes estimate
    _estimateTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (!mounted) return;
      final elapsed = _downloadStart.elapsedMilliseconds;
      final estimate = ((elapsed / totalMs) * 90).clamp(0.0, 90.0).toInt();
      if (estimate > _downloadProgress) {
        setState(() => _downloadProgress = estimate);
      }
    });
  }

  Future<void> _downloadModel() async {
    setState(() {
      _state = _State.installing;
      _downloadProgress = 0;
    });
    RabbiAiService.startDownload();
    _listenToDownload();
  }

  Future<void> _consult(InvestmentProvider provider) async {
    provider.consultRabbi();
    setState(() {
      _state = _State.consulting;
      _response = '';
    });

    try {
      await for (final token
          in RabbiAiService.getAdviceStream(provider.pendingMultipliers)) {
        if (!mounted) return;
        setState(() => _response += token);
      }
      if (!mounted) return;
      setState(() => _state = _State.done);
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('initialize') ||
          errStr.contains('tflite') ||
          errStr.contains('Failed to init')) {
        await RabbiAiService.resetModel();
        if (!mounted) return;
        setState(() {
          _state = _State.notInstalled;
          _errorMessage = 'Modelo incompatível removido. Baixe novamente.';
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _state = _State.error;
        _errorMessage = errStr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvestmentProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(RabbiAiService.rabbiName),
        backgroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _RabbiAvatar(speaking: _state == _State.consulting || _state == _State.done),
            const SizedBox(height: 24),
            _buildBody(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(InvestmentProvider provider) {
    switch (_state) {
      case _State.checking:
        return const CircularProgressIndicator(color: AppTheme.gold);

      case _State.notInstalled:
        return _DownloadPrompt(
          onDownload: _downloadModel,
          notice: _errorMessage.isNotEmpty ? _errorMessage : null,
        );

      case _State.installing:
        return _InstallingWidget(progress: _downloadProgress);

      case _State.installError:
        return _ErrorCard(
          message: 'Falha ao baixar o modelo:\n$_errorMessage',
          onRetry: _downloadModel,
        );

      case _State.ready:
        return Column(
          children: [
            _WarningCard(),
            const SizedBox(height: 24),
            _ConsultButtons(onAccept: () => _consult(provider)),
          ],
        );

      case _State.consulting:
        return Column(
          children: [
            _ResponseCard(text: _response, streaming: true),
            const SizedBox(height: 16),
            const Text(
              'O Rabi está consultando os astros...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        );

      case _State.done:
        return Column(
          children: [
            _ResponseCard(text: _response, streaming: false),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi, Shalom!'),
              ),
            ),
          ],
        );

      case _State.error:
        return _ErrorCard(
          message: 'Erro na inferência:\n$_errorMessage',
          onRetry: () => _consult(provider),
        );
    }
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _RabbiAvatar extends StatelessWidget {
  final bool speaking;
  const _RabbiAvatar({required this.speaking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: speaking ? AppTheme.gold : AppTheme.border, width: 2),
      ),
      child: ClipOval(
        child: Image.asset('assets/images/rabbi.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _DownloadPrompt extends StatelessWidget {
  final VoidCallback onDownload;
  final String? notice;
  const _DownloadPrompt({required this.onDownload, this.notice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.download_rounded, size: 36, color: AppTheme.gold),
          const SizedBox(height: 12),
          Text(
            'O Rabi precisa de seu cérebro',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (notice != null) ...[
            Text(
              notice!,
              style: const TextStyle(color: AppTheme.warning, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          const Text(
            'O modelo de IA do Rabi Mordechai ainda não foi baixado. '
            'São ~600 MB rodando inteiramente no seu dispositivo — '
            'sem nenhuma chamada de servidor, promessa de rabino.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onDownload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Baixar o Rabi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallingWidget extends StatelessWidget {
  final int progress;
  const _InstallingWidget({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress / 100 : null,
                    color: AppTheme.gold,
                    backgroundColor: AppTheme.border,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 38,
                child: Text(
                  progress > 0 ? '$progress%' : '…',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Baixando o Rabi...',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          const Text(
            'Isso pode levar alguns minutos.\nO modelo só é baixado uma vez.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber, size: 28, color: AppTheme.warning),
          const SizedBox(height: 10),
          Text(
            'Sabedoria Tem Preço',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'O Rabi conhece os multiplicadores do próximo ciclo, '
            'mas cobra 10% dos seus lucros.\n\n'
            '"Consultoria divina nunca foi de graça, meu filho."',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ConsultButtons extends StatelessWidget {
  final VoidCallback onAccept;
  const _ConsultButtons({required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Aceitar e Ouvir a Sabedoria (-10%)'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Não, obrigado Rabi'),
          ),
        ),
      ],
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final String text;
  final bool streaming;
  const _ResponseCard({required this.text, required this.streaming});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              text.isEmpty ? '...' : text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (streaming) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: AppTheme.gold),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 28),
          const SizedBox(height: 10),
          Text(
            message,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
