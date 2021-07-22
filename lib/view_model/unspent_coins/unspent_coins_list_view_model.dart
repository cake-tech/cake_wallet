import 'package:cake_wallet/bitcoin/bitcoin_amount_format.dart';
import 'package:cake_wallet/bitcoin/electrum_wallet.dart';
import 'package:cake_wallet/bitcoin/unspent_coins_info.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_item.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'unspent_coins_list_view_model.g.dart';

class UnspentCoinsListViewModel = UnspentCoinsListViewModelBase with _$UnspentCoinsListViewModel;

abstract class UnspentCoinsListViewModelBase with Store {
  UnspentCoinsListViewModelBase({
    @required WalletBase wallet,
    @required Box<UnspentCoinsInfo> unspentCoinsInfo}) {
    _unspentCoinsInfo = unspentCoinsInfo;
    _wallet = wallet as ElectrumWallet;
    _wallet.updateUnspent();
  }

  ElectrumWallet _wallet;
  Box<UnspentCoinsInfo> _unspentCoinsInfo;

  @computed
  ObservableList<UnspentCoinsItem> get items =>
    ObservableList.of(_wallet.unspentCoins.map((elem) {
      final amount = bitcoinAmountToString(amount: elem.value) +
          ' ${_wallet.currency.title}';

      return UnspentCoinsItem(
          address: elem.address.address,
          amount: amount,
          hash: elem.hash,
          isFrozen: elem.isFrozen,
          note: elem.note,
          isSending: elem.isSending
      );
    }));

  Future<void> saveUnspentCoinInfo(UnspentCoinsItem item) async {
    try {
      final info = _unspentCoinsInfo.values
          .firstWhere((element) => element.walletId.contains(_wallet.id) &&
          element.hash.contains(item.hash));

      info.isFrozen = item.isFrozen;
      info.isSending = item.isSending;
      info.note = item.note;

      await info.save();
      await _wallet.updateUnspent();
    } catch (e) {
      print(e.toString());
    }
  }
}