import 'package:collection/collection.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/unspent_transaction_output.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_item.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'unspent_coins_list_view_model.g.dart';

class UnspentCoinsListViewModel = UnspentCoinsListViewModelBase with _$UnspentCoinsListViewModel;

abstract class UnspentCoinsListViewModelBase with Store {
  UnspentCoinsListViewModelBase(
      {required this.wallet, required Box<UnspentCoinsInfo> unspentCoinsInfo})
      : _unspentCoinsInfo = unspentCoinsInfo {
    _updateUnspents();
  }

  WalletBase wallet;
  final Box<UnspentCoinsInfo> _unspentCoinsInfo;

  @computed
  ObservableList<UnspentCoinsItem> get items =>
      ObservableList.of(_getUnspents().map((elem) {
        final amount = formatAmountToString(elem.value) + ' ${wallet.currency.title}';

        final info = getUnspentCoinInfo(elem.hash, elem.address, elem.value, elem.vout, elem.keyImage);

        return UnspentCoinsItem(
            address: elem.address,
            amount: amount,
            hash: elem.hash,
            isFrozen: info?.isFrozen ?? false,
            note: info?.note ?? '',
            isSending: info?.isSending ?? true,
            amountRaw: elem.value,
            vout: elem.vout,
          keyImage: elem.keyImage
        );
      }));

  Future<void> saveUnspentCoinInfo(UnspentCoinsItem item) async {
    try {
      final info = getUnspentCoinInfo(item.hash, item.address, item.amountRaw, item.vout, item.keyImage);
      if (info == null) {
        final newInfo = UnspentCoinsInfo(
            walletId: wallet.id,
            hash: item.hash,
            address: item.address,
            value: item.amountRaw,
            vout: item.vout,
            isFrozen: item.isFrozen,
            isSending: item.isSending,
            noteRaw: item.note,
            keyImage: item.keyImage
        );

        await _unspentCoinsInfo.add(newInfo);
        _updateUnspents();
        wallet.updateBalance();
        return;
      }
      info.isFrozen = item.isFrozen;
      info.isSending = item.isSending;
      info.note = item.note;

      await info.save();
      _updateUnspents();
      wallet.updateBalance();
    } catch (e) {
      print(e.toString());
    }
  }

  UnspentCoinsInfo? getUnspentCoinInfo(String hash, String address, int value, int vout, String? keyImage) {
    return _unspentCoinsInfo.values.firstWhereOrNull((element) =>
        element.walletId == wallet.id &&
        element.hash == hash &&
        element.address == address &&
        element.value == value &&
        element.vout == vout &&
        element.keyImage == keyImage
    );
  }

  String formatAmountToString(int fullBalance) {
    if (wallet.type == WalletType.monero)
      return monero!.formatterMoneroAmountToString(amount: fullBalance);
    if ([WalletType.bitcoin, WalletType.litecoin].contains(wallet.type))
      return bitcoin!.formatterBitcoinAmountToString(amount: fullBalance);
    return '';
  }


  void _updateUnspents() {
    if (wallet.type == WalletType.monero)
      return monero!.updateUnspents(wallet);
    if ([WalletType.bitcoin, WalletType.litecoin].contains(wallet.type))
      return bitcoin!.updateUnspents(wallet);
  }

  List<Unspent> _getUnspents() {
    if (wallet.type == WalletType.monero)
      return monero!.getUnspents(wallet);
    if ([WalletType.bitcoin, WalletType.litecoin].contains(wallet.type))
      return bitcoin!.getUnspents(wallet);
    return List.empty();
  }
}
