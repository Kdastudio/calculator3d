import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/calculator_provider.dart';
import '../providers/sync_provider.dart';
import '../screens/login_screen.dart';
import 'common_widgets.dart';

class CloudSyncBar extends StatelessWidget {
  const CloudSyncBar({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sync = context.watch<SyncProvider>();

    if (!auth.isConfigured) {
      return AppBanner(
        tone: AppBannerTone.warning,
        icon: AppIcons.cloudOff,
        message: 'Nuvem desativada — rode com --dart-define-from-file=.env',
      );
    }

    if (!auth.isAuthenticated) {
      return AppBanner(
        icon: AppIcons.cloudOff,
        message: 'Entre para salvar e sincronizar entre dispositivos',
        action: GhostButton(
          label: 'Entrar',
          icon: AppIcons.login,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.cloud, size: 16, color: AppTheme.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  auth.userEmail ?? 'Conectado',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              if (sync.isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (sync.message != null) ...[
            const SizedBox(height: 6),
            Text(
              sync.message!,
              style: const TextStyle(fontSize: 12, color: AppTheme.success),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SyncChip(
                label: 'Salvar cálculo',
                icon: AppIcons.save,
                onPressed: sync.isLoading ? null : () => _saveCalculation(context),
              ),
              _SyncChip(
                label: 'Salvar orçamento',
                icon: AppIcons.fileText,
                onPressed: sync.isLoading ? null : () => _saveQuote(context),
              ),
              _SyncChip(
                label: 'Salvar perfil',
                icon: AppIcons.building,
                onPressed: sync.isLoading ? null : () => _saveProfile(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveCalculation(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final sync = context.read<SyncProvider>();
    final calculator = context.read<CalculatorProvider>();
    if (auth.user == null) return;

    calculator.calculate();
    await sync.saveCalculation(calculator, auth.user!.id);
  }

  Future<void> _saveQuote(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final sync = context.read<SyncProvider>();
    final calculator = context.read<CalculatorProvider>();
    if (auth.user == null) return;

    await sync.saveQuote(calculator, auth.user!.id);
  }

  Future<void> _saveProfile(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final sync = context.read<SyncProvider>();
    final calculator = context.read<CalculatorProvider>();
    if (auth.user == null) return;

    await sync.saveProfileFromCalculator(calculator, auth.user!.id);
  }
}

class _SyncChip extends StatelessWidget {
  const _SyncChip({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: AppTheme.textMuted),
      label: Text(label),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }
}
