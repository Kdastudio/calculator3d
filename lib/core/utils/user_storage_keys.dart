/// Chaves de SharedPreferences isoladas por usuário autenticado.
class UserStorageKeys {
  UserStorageKeys._();

  static String stock(String userId) => 'kda3d_stock_$userId';

  static String supplies(String userId) => 'kda3d_supplies_$userId';

  static String supplyHistory(String userId) => 'kda3d_supply_history_$userId';

  static String quoteHistory(String userId) => 'kda3d_quote_history_$userId';
}
