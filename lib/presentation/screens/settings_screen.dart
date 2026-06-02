import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/layout/app_layout.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialValues());
  }

  void _loadInitialValues() {
    final sync = context.read<SyncProvider>();
    final auth = context.read<AuthProvider>();

    final profileName = sync.profile?.displayName.trim();
    final metadataName =
        auth.user?.userMetadata?['display_name'] as String?;

    _nameController.text = profileName?.isNotEmpty == true
        ? profileName!
        : (metadataName?.trim() ?? '');

    _emailController.text = auth.userEmail ?? sync.profile?.email ?? '';
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (!_nameFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final sync = context.read<SyncProvider>();
    final userId = auth.user?.id;
    if (userId == null) return;

    settings.clearFeedback();
    final ok = await settings.updateDisplayName(
      userId: userId,
      displayName: _nameController.text,
    );
    if (!mounted) return;

    if (ok) {
      await sync.refreshProfile(userId);
    }
  }

  Future<void> _saveEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final sync = context.read<SyncProvider>();
    final userId = auth.user?.id;
    final currentEmail = auth.userEmail;
    if (userId == null || currentEmail == null) return;

    settings.clearFeedback();
    final ok = await settings.updateEmail(
      userId: userId,
      currentEmail: currentEmail,
      newEmail: _emailController.text,
    );
    if (!mounted) return;

    if (ok) {
      await sync.refreshProfile(userId);
    }
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final currentEmail = auth.userEmail;
    if (currentEmail == null) return;

    settings.clearFeedback();
    final ok = await settings.updatePassword(
      currentEmail: currentEmail,
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (!mounted) return;

    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppLayout.pagePadding),
          sliver: SliverToBoxAdapter(
            child: AppLayout.pageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configurações',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gerencie os dados da sua conta.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  if (settings.message != null)
                    _FeedbackBanner(
                      text: settings.message!,
                      color: AppTheme.success,
                    ),
                  if (settings.error != null)
                    _FeedbackBanner(
                      text: settings.error!,
                      color: AppTheme.danger,
                    ),
                  if (settings.message != null || settings.error != null)
                    const SizedBox(height: 16),
                  AppCard(
                    title: 'Nome',
                    subtitle: 'Exibido no topo do aplicativo',
                    icon: AppIcons.user,
                    child: Form(
                      key: _nameFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Seu nome',
                              prefixIcon: Icon(AppIcons.user, size: 20),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe seu nome';
                              }
                              if (v.trim().length < 2) {
                                return 'Mínimo 2 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: PrimaryButton(
                              label: 'Salvar nome',
                              compact: true,
                              expand: false,
                              onPressed: settings.isSaving ? null : _saveName,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    title: 'E-mail',
                    subtitle: 'Usado para login e recuperação',
                    icon: AppIcons.mail,
                    child: Form(
                      key: _emailFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(AppIcons.mail, size: 20),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe o e-mail';
                              }
                              if (!v.contains('@')) return 'E-mail inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: PrimaryButton(
                              label: 'Salvar e-mail',
                              compact: true,
                              expand: false,
                              onPressed: settings.isSaving ? null : _saveEmail,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    title: 'Senha',
                    subtitle: 'Alteração exige a senha atual',
                    icon: AppIcons.lock,
                    child: Form(
                      key: _passwordFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _currentPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Senha atual',
                              prefixIcon: const Icon(AppIcons.lock, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureCurrentPassword
                                      ? AppIcons.eye
                                      : AppIcons.eyeOff,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscureCurrentPassword =
                                      !_obscureCurrentPassword,
                                ),
                              ),
                            ),
                            obscureText: _obscureCurrentPassword,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Informe a senha atual';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Nova senha',
                              prefixIcon: const Icon(AppIcons.lock, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword
                                      ? AppIcons.eye
                                      : AppIcons.eyeOff,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () =>
                                      _obscureNewPassword = !_obscureNewPassword,
                                ),
                              ),
                            ),
                            obscureText: _obscureNewPassword,
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirmar nova senha',
                              prefixIcon: const Icon(AppIcons.lock, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? AppIcons.eye
                                      : AppIcons.eyeOff,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (v) {
                              if (v != _newPasswordController.text) {
                                return 'As senhas não conferem';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: PrimaryButton(
                              label: 'Salvar senha',
                              compact: true,
                              expand: false,
                              onPressed:
                                  settings.isSaving ? null : _savePassword,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 13),
      ),
    );
  }
}
