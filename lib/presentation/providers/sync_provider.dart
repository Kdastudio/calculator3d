import 'package:flutter/foundation.dart';

import '../../data/repositories/calculation_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/quote_repository.dart';
import '../../data/repositories/storage_repository.dart';
import '../../domain/models/calculator_serializers.dart';
import '../../domain/models/cloud_models.dart';
import 'calculator_provider.dart';

class SyncProvider extends ChangeNotifier {
  SyncProvider({
    CalculationRepository? calculationRepository,
    QuoteRepository? quoteRepository,
    ProfileRepository? profileRepository,
    StorageRepository? storageRepository,
  })  : _calculationRepository = calculationRepository ?? CalculationRepository(),
        _quoteRepository = quoteRepository ?? QuoteRepository(),
        _profileRepository = profileRepository ?? ProfileRepository(),
        _storageRepository = storageRepository ?? StorageRepository();

  final CalculationRepository _calculationRepository;
  final QuoteRepository _quoteRepository;
  final ProfileRepository _profileRepository;
  final StorageRepository _storageRepository;

  List<SavedCalculation> _calculations = [];
  List<SavedQuote> _quotes = [];
  UserProfile? _profile;
  bool _loading = false;
  String? _message;
  String? _activeCalculationId;
  String? _activeQuoteId;

  List<SavedCalculation> get calculations => _calculations;
  List<SavedQuote> get quotes => _quotes;
  UserProfile? get profile => _profile;
  bool get isLoading => _loading;
  String? get message => _message;
  String? get activeCalculationId => _activeCalculationId;
  String? get activeQuoteId => _activeQuoteId;

  Future<void> loadAll(String userId) async {
    _loading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _calculationRepository.list(userId),
        _quoteRepository.list(userId),
        _profileRepository.fetchProfile(userId),
      ]);

      _calculations = results[0] as List<SavedCalculation>;
      _quotes = results[1] as List<SavedQuote>;
      _profile = results[2] as UserProfile?;
      _message = null;
    } catch (e) {
      _message = 'Falha ao sincronizar: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile(String userId) async {
    try {
      _profile = await _profileRepository.fetchProfile(userId);
      notifyListeners();
    } catch (e) {
      _message = 'Falha ao atualizar perfil: $e';
      notifyListeners();
    }
  }

  Future<void> applyProfileToCalculator(CalculatorProvider calculator, String userId) async {
    _profile ??= await _profileRepository.fetchProfile(userId);
    if (_profile == null) return;

    final profile = _profile!;
    List<int>? logoBytes;
    if (profile.logoPath != null) {
      try {
        final bytes = await _storageRepository.downloadFile('logos', profile.logoPath!);
        logoBytes = bytes?.toList();
      } catch (_) {
        logoBytes = null;
      }
    }

    calculator.applyCloudProfile(
      currency: CalculatorSerializer.currencyFromCode(profile.currencyCode),
      quote: calculator.quoteData.copyWith(
        companyName: profile.companyName,
        companyEmail: profile.companyEmail,
        companyPhone: profile.companyPhone,
        companySlogan: profile.companySlogan,
        companyLogoBytes: logoBytes,
      ),
    );
  }

  Future<bool> saveProfileFromCalculator(CalculatorProvider calculator, String userId) async {
    _loading = true;
    notifyListeners();

    try {
      var logoPath = _profile?.logoPath;
      final logoBytes = calculator.quoteData.companyLogoBytes;

      if (logoBytes != null && logoBytes.isNotEmpty) {
        logoPath = await _storageRepository.uploadLogo(
          userId: userId,
          bytes: Uint8List.fromList(logoBytes),
          fileName: 'logo.png',
        );
      }

      final profile = UserProfile(
        id: userId,
        email: _profile?.email,
        displayName: _profile?.displayName ?? '',
        companyName: calculator.quoteData.companyName,
        companyEmail: calculator.quoteData.companyEmail,
        companyPhone: calculator.quoteData.companyPhone,
        companySlogan: calculator.quoteData.companySlogan,
        logoPath: logoPath,
        currencyCode: calculator.currency.code,
      );

      await _profileRepository.upsertProfile(userId, profile);
      _profile = profile;
      _message = 'Perfil sincronizado.';
      return true;
    } catch (e) {
      _message = 'Erro ao salvar perfil: $e';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> saveCalculation(CalculatorProvider calculator, String userId) async {
    _loading = true;
    notifyListeners();

    try {
      String? gcodePath;
      final gcodeBytes = calculator.gCodeContentBytes;
      final gcodeName = calculator.gCodeFileName;

      if (gcodeBytes != null && gcodeName != null) {
        gcodePath = await _storageRepository.uploadGcode(
          userId: userId,
          bytes: Uint8List.fromList(gcodeBytes),
          fileName: gcodeName,
        );
      }

      final id = await _calculationRepository.save(
        userId: userId,
        costInputs: calculator.costInputs,
        taxInputs: calculator.taxInputs,
        currency: calculator.currency,
        results: calculator.results,
        gcodePath: gcodePath,
        gcodeFilename: gcodeName,
        existingId: _activeCalculationId,
      );

      _activeCalculationId = id;
      await loadAll(userId);
      _message = 'Cálculo salvo na nuvem.';
      return true;
    } catch (e) {
      _message = 'Erro ao salvar cálculo: $e';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> saveQuote(CalculatorProvider calculator, String userId) async {
    _loading = true;
    notifyListeners();

    try {
      var logoPath = _profile?.logoPath;
      final logoBytes = calculator.quoteData.companyLogoBytes;

      if (logoBytes != null && logoBytes.isNotEmpty) {
        logoPath = await _storageRepository.uploadLogo(
          userId: userId,
          bytes: Uint8List.fromList(logoBytes),
          fileName: 'quote_logo.png',
        );
      }

      final id = await _quoteRepository.save(
        userId: userId,
        quote: calculator.quoteData,
        currency: calculator.currency,
        logoPath: logoPath,
        existingId: _activeQuoteId,
      );

      _activeQuoteId = id;
      await loadAll(userId);
      _message = 'Orçamento salvo na nuvem.';
      return true;
    } catch (e) {
      _message = 'Erro ao salvar orçamento: $e';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCalculation(String id, CalculatorProvider calculator) async {
    _loading = true;
    notifyListeners();

    try {
      final state = await _calculationRepository.loadState(id);
      if (state == null) return;

      Uint8List? gcodeBytes;
      if (state.gcodePath != null) {
        gcodeBytes = await _calculationRepository.downloadGcode(state.gcodePath);
      }

      calculator.applySavedCalculation(
        costInputs: state.cost,
        taxInputs: state.tax,
        currency: state.currency,
        results: state.results,
        gcodeFileName: state.gcodeFilename,
        gcodeContent: gcodeBytes?.toList(),
      );

      _activeCalculationId = id;
      _message = 'Cálculo carregado.';
    } catch (e) {
      _message = 'Erro ao carregar cálculo: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadQuote(String id, CalculatorProvider calculator) async {
    _loading = true;
    notifyListeners();

    try {
      List<int>? logoBytes;
      final saved = _quotes.firstWhere((q) => q.id == id);
      if (saved.logoPath != null) {
        final bytes = await _storageRepository.downloadFile('logos', saved.logoPath!);
        logoBytes = bytes?.toList();
      }

      final state = await _quoteRepository.loadState(id, logoBytes: logoBytes);
      if (state == null) return;

      calculator.applySavedQuote(
        quote: state.quote,
        currency: state.currency,
      );

      _activeQuoteId = id;
      _message = 'Orçamento carregado.';
    } catch (e) {
      _message = 'Erro ao carregar orçamento: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCalculation(String id, String userId) async {
    await _calculationRepository.delete(id);
    if (_activeCalculationId == id) _activeCalculationId = null;
    await loadAll(userId);
  }

  Future<void> deleteQuote(String id, String userId) async {
    await _quoteRepository.delete(id);
    if (_activeQuoteId == id) _activeQuoteId = null;
    await loadAll(userId);
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  void resetSession() {
    _calculations = [];
    _quotes = [];
    _profile = null;
    _activeCalculationId = null;
    _activeQuoteId = null;
    _message = null;
    notifyListeners();
  }
}
