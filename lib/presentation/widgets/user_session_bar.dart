import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/calculator_provider.dart';
import '../providers/sync_provider.dart';
import 'finalize_quote_bar.dart';

class UserSessionBar extends StatelessWidget {
  const UserSessionBar({
    super.key,
    required this.onLogout,
    this.showFinalize = false,
  });

  final VoidCallback onLogout;
  final bool showFinalize;

  String _resolveDisplayName(SyncProvider sync, AuthProvider auth) {
    final profileName = sync.profile?.displayName.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;

    final metadataName =
        auth.user?.userMetadata?['display_name'] as String?;
    if (metadataName != null && metadataName.trim().isNotEmpty) {
      return metadataName.trim();
    }

    final email = auth.userEmail;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Usuário';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sync = context.watch<SyncProvider>();
    final displayName = _resolveDisplayName(sync, auth);
    final finalized = context.select<CalculatorProvider, bool>(
      (p) => p.quoteData.isFinalized,
    );

    return Material(
      color: AppTheme.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              const Spacer(),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (showFinalize && !finalized) ...[
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => runFinalizeQuoteFlow(context),
                  icon: const Icon(AppIcons.checkCircle, size: 16),
                  label: const Text('Finalizar'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(AppIcons.logout, size: 16),
                label: const Text('Sair'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.border),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
