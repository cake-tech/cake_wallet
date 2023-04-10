import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_base.dart';

class PayfuraBuyProvider {
  PayfuraBuyProvider({required SettingsStore settingsStore, required WalletBase wallet})
      : this._settingsStore = settingsStore,
        this._wallet = wallet;

  final SettingsStore _settingsStore;
  final WalletBase _wallet;

  static const _baseUrl = 'exchange.payfura.com';

  Uri requestUrl() {
    return Uri.https(_baseUrl, '', <String, dynamic>{
      'apiKey': secrets.payfuraApiKey,
      'to': _wallet.currency.title,
      'from': _settingsStore.fiatCurrency.title,
      'walletAddress': '${_wallet.currency.title}:${_wallet.walletAddresses.address}',
      'mode': 'buy'
    });
  }
}
