import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env.dart';
import '../../core/config/supabase_config.dart';
import '../../data/repositories/auth_repository.dart';

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

  bool get isConfigured => Env.hasSupabase && SupabaseConfig.isReady;
  bool get isLoading => _loading;
  bool get isAuthenticated => _user != null;
  User? get user => _user;
  String? get error => _error;
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
      await _authRepository.signIn(email: email, password: password);
      _user = _authRepository.currentUser;
      _error = null;
      return true;
    } catch (e) {
      _error = _mapError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password) async {
    _setBusy();
    try {
      await _authRepository.signUp(email: email, password: password);
      _user = _authRepository.currentUser;
      _error = null;
      return true;
    } catch (e) {
      _error = _mapError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setBusy() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  String _mapError(Object e) {
    final message = e.toString();
    if (message.contains('Invalid login credentials')) {
      return 'E-mail ou senha inválidos.';
    }
    if (message.contains('User already registered')) {
      return 'Este e-mail já está cadastrado.';
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
