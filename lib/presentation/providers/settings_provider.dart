import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profile_repository.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _profileRepository = profileRepository ?? ProfileRepository();

  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;

  bool _saving = false;
  String? _message;
  String? _error;

  bool get isSaving => _saving;
  String? get message => _message;
  String? get error => _error;

  void clearFeedback() {
    _message = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> updateDisplayName({
    required String userId,
    required String displayName,
  }) async {
    final name = displayName.trim();
    if (name.length < 2) {
      _error = 'O nome deve ter pelo menos 2 caracteres.';
      notifyListeners();
      return false;
    }

    return _runSave(() async {
      await _authRepository.updateUser(
        UserAttributes(data: {'display_name': name}),
      );
      await _profileRepository.updateDisplayName(userId, name);
      _message = 'Nome atualizado.';
    });
  }

  Future<bool> updateEmail({
    required String userId,
    required String currentEmail,
    required String newEmail,
  }) async {
    final email = newEmail.trim().toLowerCase();
    if (!email.contains('@')) {
      _error = 'Informe um e-mail válido.';
      notifyListeners();
      return false;
    }
    if (email == currentEmail.trim().toLowerCase()) {
      _error = 'O novo e-mail é igual ao atual.';
      notifyListeners();
      return false;
    }

    return _runSave(() async {
      await _authRepository.updateUser(UserAttributes(email: email));
      await _profileRepository.updateEmail(userId, email);
      _message =
          'E-mail atualizado. Se o Supabase exigir confirmação, verifique sua caixa de entrada.';
    });
  }

  Future<bool> updatePassword({
    required String currentEmail,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.length < 6) {
      _error = 'A nova senha deve ter pelo menos 6 caracteres.';
      notifyListeners();
      return false;
    }
    if (newPassword != confirmPassword) {
      _error = 'A confirmação da senha não confere.';
      notifyListeners();
      return false;
    }

    return _runSave(() async {
      await _authRepository.reauthenticate(
        email: currentEmail,
        password: currentPassword,
      );
      await _authRepository.updateUser(UserAttributes(password: newPassword));
      _message = 'Senha atualizada com sucesso.';
    });
  }

  Future<bool> _runSave(Future<void> Function() action) async {
    _saving = true;
    _message = null;
    _error = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (e) {
      _error = _mapError(e);
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  String _mapError(Object e) {
    if (e is AuthException) {
      final code = e.code?.toLowerCase() ?? '';
      final message = e.message.toLowerCase();

      if (code == 'invalid_credentials' ||
          message.contains('invalid login credentials')) {
        return 'Senha atual incorreta.';
      }
      if (message.contains('same password')) {
        return 'A nova senha deve ser diferente da atual.';
      }
      if (message.contains('already registered') ||
          message.contains('already been registered')) {
        return 'Este e-mail já está em uso.';
      }
      if (message.contains('email address invalid')) {
        return 'E-mail inválido.';
      }
      if (e.message.isNotEmpty) return e.message;
    }

    return 'Não foi possível salvar. Tente novamente.';
  }
}
