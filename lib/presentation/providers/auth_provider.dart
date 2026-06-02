import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../core/config/supabase_config.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_submit_result.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository() {
    _init();
  }

  final AuthRepository _authRepository;
  StreamSubscription<AuthState>? _subscription;

  User? _user;
  bool _loading = true;
  String? _error;
  String? _info;

  bool get isConfigured => Env.hasSupabase && SupabaseConfig.isReady;
  bool get isLoading => _loading;
  bool get isAuthenticated => _user != null;
  User? get user => _user;
  String? get error => _error;
  String? get info => _info;
  String? get userEmail => _user?.email;

  Future<void> _init() async {
    if (!isConfigured) {
      _loading = false;
      notifyListeners();
      return;
    }

    _user = _authRepository.currentUser;
    _subscription = _authRepository.authStateChanges.listen((state) {
      _user = state.session?.user;
      notifyListeners();
    });
    _loading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setBusy();
    try {
      final response = await _authRepository.signIn(
        email: email,
        password: password,
      );
      _user = response.session?.user ?? response.user;
      if (_user == null) {
        _error = 'Não foi possível iniciar a sessão.';
        return false;
      }
      _error = null;
      _info = null;
      return true;
    } catch (e) {
      _error = _mapError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<SignUpOutcome> signUp(String email, String password) async {
    _setBusy();
    try {
      final response = await _authRepository.signUp(
        email: email,
        password: password,
      );

      if (_isDuplicateRegistration(response.user)) {
        _error = 'Este e-mail já está cadastrado. Faça login.';
        return SignUpOutcome.failed;
      }

      if (response.session != null) {
        _user = response.session!.user;
        _error = null;
        _info = null;
        return SignUpOutcome.loggedIn;
      }

      if (response.user != null) {
        final loggedIn = await _trySignInAfterSignUp(email, password);
        if (loggedIn) {
          return SignUpOutcome.loggedIn;
        }

        _user = null;
        _error = null;
        _info =
            'Conta criada com sucesso! Agora faça login com seu e-mail e senha.';
        return SignUpOutcome.needsLogin;
      }

      _error = 'Não foi possível criar a conta.';
      return SignUpOutcome.failed;
    } catch (e) {
      _error = _mapError(e);
      return SignUpOutcome.failed;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  bool _isDuplicateRegistration(User? user) {
    if (user == null) return false;
    final identities = user.identities;
    return identities != null && identities.isEmpty;
  }

  Future<bool> _trySignInAfterSignUp(String email, String password) async {
    try {
      final response = await _authRepository.signIn(
        email: email,
        password: password,
      );
      final user = response.session?.user ?? response.user;
      if (user == null) return false;
      _user = user;
      _error = null;
      _info = null;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _user = null;
    _info = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _info = null;
    notifyListeners();
  }

  void clearInfo() {
    _info = null;
    notifyListeners();
  }

  void _setBusy() {
    _loading = true;
    _error = null;
    _info = null;
    notifyListeners();
  }

  String _mapError(Object e) {
    if (e is AuthException) {
      final code = e.code?.toLowerCase() ?? '';
      final message = e.message.toLowerCase();

      if (code == 'email_not_confirmed' ||
          message.contains('email not confirmed')) {
        return 'E-mail ainda não confirmado. Confirme pelo link recebido ou '
            'desative a confirmação de e-mail no painel do Supabase.';
      }
      if (code == 'invalid_credentials' ||
          message.contains('invalid login credentials')) {
        return 'E-mail ou senha inválidos.';
      }
      if (code == 'user_already_registered' ||
          message.contains('user already registered')) {
        return 'Este e-mail já está cadastrado. Faça login.';
      }
      if (message.contains('password should be at least')) {
        return 'A senha deve ter pelo menos 6 caracteres.';
      }
      if (message.contains('signup is disabled')) {
        return 'Cadastro desabilitado no Supabase.';
      }
      if (message.contains('database error') ||
          message.contains('saving new user')) {
        return 'Erro ao salvar o perfil no Supabase. Verifique se as migrations '
            'foram executadas no projeto.';
      }
      if (e.message.isNotEmpty) {
        return e.message;
      }
    }

    final message = e.toString();
    if (message.contains('Invalid login credentials')) {
      return 'E-mail ou senha inválidos.';
    }
    if (message.contains('User already registered')) {
      return 'Este e-mail já está cadastrado. Faça login.';
    }
    if (message.contains('Password should be at least')) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    return 'Erro de autenticação. Tente novamente.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
