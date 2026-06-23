import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/theme.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/shekel_balance_widget.dart';
import 'history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploadingAvatar = false;

  Future<void> _pickAndSaveAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (picked == null || !mounted) return;

    final user = context.read<UserProvider>().user;
    if (user == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final destPath = p.join(appDir.path, 'avatar_${user.id}.jpg');
      await File(picked.path).copy(destPath);

      if (!mounted) return;
      await context.read<UserProvider>().updateAvatarUrl(destPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto atualizada!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar foto: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _editDisplayName() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final ctrl = TextEditingController(text: user.displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Editar nome'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nome de exibição'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Salvar')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      await context.read<UserProvider>().updateDisplayName(result);
    }
  }

  void _shareProfile() {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    Share.share(
      '🪙 Olha meu perfil na ShekelStore!\n'
      '👤 ${user.displayName} (@${user.username})\n'
      '💰 Saldo: ${user.shekelBalance} shekels\n'
      '🏆 Total ganho: ${user.totalWon} shekels\n'
      'Baixe o app e ganhe 1000 shekels grátis!',
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('Sair')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.signOut();
      if (!mounted) return;
      context.read<UserProvider>().clearUser();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareProfile),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _AvatarSection(
              user: user,
              uploading: _uploadingAvatar,
              onPickCamera: _pickAndSaveAvatar,
            ),
            const SizedBox(height: 24),
            _ProfileCard(user: user, onEditName: _editDisplayName),
            const SizedBox(height: 16),
            _StatsCard(user: user),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('Ver histórico completo'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Compartilhar perfil'),
                onPressed: _shareProfile,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: AppTheme.error),
                label: const Text('Sair da conta',
                    style: TextStyle(color: AppTheme.error)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error)),
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final dynamic user;
  final bool uploading;
  final VoidCallback onPickCamera;

  const _AvatarSection({
    required this.user,
    required this.uploading,
    required this.onPickCamera,
  });

  @override
  Widget build(BuildContext context) {
    final avatarPath = user?.avatarUrl as String?;
    final hasAvatar =
        avatarPath != null && File(avatarPath).existsSync();

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          onTap: onPickCamera,
          child: CircleAvatar(
            radius: 56,
            backgroundColor: AppTheme.surfaceVariant,
            backgroundImage:
                hasAvatar ? FileImage(File(avatarPath)) : null,
            child: uploading
                ? const CircularProgressIndicator(color: AppTheme.gold)
                : !hasAvatar
                    ? Text(
                        (user?.displayName as String? ?? 'S')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
          ),
        ),
        GestureDetector(
          onTap: onPickCamera,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
                color: AppTheme.gold, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt, color: Colors.black, size: 18),
          ),
        ),
      ],
    ).animate().fadeIn().scale();
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onEditName;

  const _ProfileCard({required this.user, required this.onEditName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? '...',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '@${user?.username ?? '...'}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppTheme.gold),
                onPressed: onEditName,
              ),
            ],
          ),
          const Divider(height: 24),
          ShekelBalanceWidget(balance: user?.shekelBalance ?? 0, large: true),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final dynamic user;
  const _StatsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estatísticas de jogo',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _StatRow(
              icon: Icons.emoji_events,
              iconColor: AppTheme.gold,
              label: 'Total ganho',
              value: '${user?.totalWon ?? 0} ₪',
              color: AppTheme.success),
          const SizedBox(height: 12),
          _StatRow(
              icon: Icons.money_off,
              iconColor: AppTheme.error,
              label: 'Total perdido',
              value: '${user?.totalLost ?? 0} ₪',
              color: AppTheme.error),
          const SizedBox(height: 12),
          _StatRow(
              icon: Icons.show_chart,
              iconColor: (user?.netProfit ?? 0) >= 0
                  ? AppTheme.success
                  : AppTheme.error,
              label: 'Lucro líquido',
              value: '${user?.netProfit ?? 0} ₪',
              color: (user?.netProfit ?? 0) >= 0
                  ? AppTheme.success
                  : AppTheme.error),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color color;

  const _StatRow(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
