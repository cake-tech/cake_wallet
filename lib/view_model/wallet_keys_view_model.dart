import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/monero/monero.dart';

part 'wallet_keys_view_model.g.dart';

class WalletKeysViewModel = WalletKeysViewModelBase with _$WalletKeysViewModel;

abstract class WalletKeysViewModelBase with Store {
  WalletKeysViewModelBase(WalletBase wallet)
      : items = ObservableList<StandartListItem>() {
    if (wallet.type == WalletType.monero) {
      final keys = monero.getKeys(wallet);

      items.addAll([
        StandartListItem(
            title: S.current.spend_key_public, value: keys['publicSpendKey']),
        StandartListItem(
            title: S.current.spend_key_private, value: keys['privateSpendKey']),
        StandartListItem(
            title: S.current.view_key_public, value: keys['publicViewKey']),
        StandartListItem(
            title: S.current.view_key_private, value: keys['privateViewKey']),
        StandartListItem(title: S.current.wallet_seed, value: wallet.seed),
      ]);
    }

    if (wallet.type == WalletType.bitcoin || wallet.type == WalletType.litecoin) {
      final keys = bitcoin.getWalletKeys(wallet);

      items.addAll([
        StandartListItem(title: 'WIF', value: keys['wif']),
        StandartListItem(title: S.current.public_key, value: keys['publicKey']),
        StandartListItem(title: S.current.private_key, value: keys['privateKey']),
        StandartListItem(title: S.current.wallet_seed, value: wallet.seed)
      ]);
    }
  }

  final ObservableList<StandartListItem> items;
}
