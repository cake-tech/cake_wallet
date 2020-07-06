import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';

part 'wallet_keys_view_model.g.dart';

class WalletKeysViewModel = WalletKeysViewModelBase with _$WalletKeysViewModel;

abstract class WalletKeysViewModelBase with Store {
  WalletKeysViewModelBase(WalletBase wallet)
      : items = ObservableList<StandartListItem>() {
    if (wallet is MoneroWallet) {
      final keys = wallet.keys;

      items.addAll([
        StandartListItem(
            title: S.current.spend_key_public, value: keys.publicSpendKey),
        StandartListItem(
            title: S.current.spend_key_private, value: keys.privateSpendKey),
        StandartListItem(
            title: S.current.view_key_public, value: keys.publicViewKey),
        StandartListItem(
            title: S.current.view_key_private, value: keys.privateViewKey),
      ]);
    }

    if (wallet is BitcoinWallet) {
      final keys = wallet.keys;

      items.addAll([
        StandartListItem(title: 'WIF', value: keys.wif),
        StandartListItem(title: 'Public key', value: keys.publicKey),
        StandartListItem(title: 'Private key', value: keys.privateKey)
      ]);
    }
  }

  final ObservableList<StandartListItem> items;
}
