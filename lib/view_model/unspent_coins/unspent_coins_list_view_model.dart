//import 'package:cw_bitcoin/bitcoin_amount_format.dart';
//import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_item.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'unspent_coins_list_view_model.g.dart';

class UnspentCoinsListViewModel = UnspentCoinsListViewModelBase with _$UnspentCoinsListViewModel;

abstract class UnspentCoinsListViewModelBase with Store {
  UnspentCoinsListViewModelBase({
    @required this.wallet,
    @required Box<UnspentCoinsInfo> unspentCoinsInfo}) {
    _unspentCoinsInfo = unspentCoinsInfo;
    bitcoin.updateUnspents(wallet);
  }

  WalletBase wallet;
  Box<UnspentCoinsInfo> _unspentCoinsInfo;

  @computed
  ObservableList<UnspentCoinsItem> get items => ObservableList.of(bitcoin.getUnspents(wallet).map((elem) {
      final amount = bitcoin.formatterBitcoinAmountToString(amount: elem.value) +
          ' ${wallet.currency.title}';

      return UnspentCoinsItem(
          address: elem.address,
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
          .firstWhere((element) => element.walletId.contains(wallet.id) &&
          element.hash.contains(item.hash));

      info.isFrozen = item.isFrozen;
      info.isSending = item.isSending;
      info.note = item.note;

      await info.save();
      bitcoin.updateUnspents(wallet);
    } catch (e) {
      print(e.toString());
    }
  }
}