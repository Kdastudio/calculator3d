import 'package:flutter/foundation.dart';

import '../../core/constants/calculator_constants.dart';
import '../../data/repositories/quote_history_repository.dart';
import '../../domain/models/quote_history_models.dart';
import 'calculator_provider.dart';

class QuoteHistoryProvider extends ChangeNotifier {
  QuoteHistoryProvider({QuoteHistoryRepository? repository})
    : _repository = repository ?? QuoteHistoryRepository();

  final QuoteHistoryRepository _repository;

  List<QuoteHistoryEntry> _entries = [];
  bool _loading = false;
  bool _initialized = false;
  String? _message;

  List<QuoteHistoryEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _loading;
  bool get isInitialized => _initialized;
  String? get message => _message;

  Future<void> initialize() async {
    if (_initialized) return;
    _loading = true;
    notifyListeners();

    try {
      _entries = await _repository.loadAll();
      _initialized = true;
    } catch (e) {
      _message = 'Erro ao carregar histórico: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      _entries = await _repository.loadAll();
    } catch (e) {
      _message = 'Erro ao atualizar histórico: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addFromCalculator(CalculatorProvider calculator) async {
    final quote = calculator.quoteData;
    if (!quote.isFinalized) return;

    final entry = QuoteHistoryEntry(
      id: _repository.newId(),
      quote: quote,
      currencyCode: calculator.currency.code,
      total: quote.total,
      savedAt: DateTime.tryParse(quote.finalizedAt ?? '') ?? DateTime.now(),
    );

    await _repository.add(entry);
    _entries = await _repository.loadAll();
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    await _repository.delete(id);
    _entries = _entries.where((e) => e.id != id).toList();
    notifyListeners();
  }

  void loadIntoCalculator(
    CalculatorProvider calculator,
    QuoteHistoryEntry entry,
  ) {
    final currency = CalculatorConstants.currencies.firstWhere(
      (c) => c.code == entry.currencyCode,
      orElse: () => CalculatorConstants.currencies.first,
    );
    calculator.applySavedQuote(quote: entry.quote, currency: currency);
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }
}
