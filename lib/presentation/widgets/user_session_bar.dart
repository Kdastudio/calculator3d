import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/sync_provider.dart';

class UserSessionBar extends StatelessWidget {
  const UserSessionBar({
    super.key,
    required this.onLogout,
  });

  final VoidCallback onLogout;

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
              const SizedBox(width: 12),
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
