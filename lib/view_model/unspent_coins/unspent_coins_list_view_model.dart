import 'package:cw_core/unspent_coins_info.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_item.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:collection/collection.dart';

part 'unspent_coins_list_view_model.g.dart';

class UnspentCoinsListViewModel = UnspentCoinsListViewModelBase with _$UnspentCoinsListViewModel;

abstract class UnspentCoinsListViewModelBase with Store {
  UnspentCoinsListViewModelBase(
      {required this.wallet, required Box<UnspentCoinsInfo> unspentCoinsInfo})
      : _unspentCoinsInfo = unspentCoinsInfo {
    bitcoin!.updateUnspents(wallet);
  }

  WalletBase wallet;
  final Box<UnspentCoinsInfo> _unspentCoinsInfo;

  @computed
  ObservableList<UnspentCoinsItem> get items =>
      ObservableList.of(bitcoin!.getUnspents(wallet).map((elem) {
        final amount = bitcoin!.formatterBitcoinAmountToString(amount: elem.value) +
            ' ${wallet.currency.title}';

        final info = getUnspentCoinInfo(elem.hash, elem.address, elem.value, elem.vout);

        return UnspentCoinsItem(
            address: elem.address,
            amount: amount,
            hash: elem.hash,
            isFrozen: info?.isFrozen ?? false,
            note: info?.note ?? '',
            isSending: info?.isSending ?? true,
            amountRaw: elem.value,
            vout: elem.vout);
      }));

  Future<void> saveUnspentCoinInfo(UnspentCoinsItem item) async {
    try {
      final info = getUnspentCoinInfo(item.hash, item.address, item.amountRaw, item.vout);
      if (info == null) {
        final newInfo = UnspentCoinsInfo(
            walletId: wallet.id,
            hash: item.hash,
            address: item.address,
            value: item.amountRaw,
            vout: item.vout,
            isFrozen: item.isFrozen,
            isSending: item.isSending,
            noteRaw: item.note);

        await _unspentCoinsInfo.add(newInfo);
        bitcoin!.updateUnspents(wallet);
        wallet.updateBalance();
        return;
      }
      info.isFrozen = item.isFrozen;
      info.isSending = item.isSending;
      info.note = item.note;

      await info.save();
      bitcoin!.updateUnspents(wallet);
      wallet.updateBalance();
    } catch (e) {
      print(e.toString());
    }
  }

  UnspentCoinsInfo? getUnspentCoinInfo(String hash, String address, int value, int vout) {
    return _unspentCoinsInfo.values.firstWhereOrNull((element) =>
        element.walletId == wallet.id &&
        element.hash == hash &&
        element.address == address &&
        element.value == value &&
        element.vout == vout);
  }
}
