import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_item.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'unspent_coins_list_view_model.g.dart';

class UnspentCoinsListViewModel = UnspentCoinsListViewModelBase with _$UnspentCoinsListViewModel;

abstract class UnspentCoinsListViewModelBase with Store {
  UnspentCoinsListViewModelBase(
      {required this.wallet, required Box<UnspentCoinsInfo> unspentCoinsInfo})
      : _unspentCoinsInfo = unspentCoinsInfo,
        _items = ObservableList<UnspentCoinsItem>() {
    _updateUnspentCoinsInfo();
    _updateUnspents();
  }

  WalletBase wallet;
  final Box<UnspentCoinsInfo> _unspentCoinsInfo;

  @observable
  ObservableList<UnspentCoinsItem> _items;

  @computed
  ObservableList<UnspentCoinsItem> get items => _items;

  Future<void> saveUnspentCoinInfo(UnspentCoinsItem item) async {
    try {
      final info =
          getUnspentCoinInfo(item.hash, item.address, item.amountRaw, item.vout, item.keyImage);

      info.isFrozen = item.isFrozen;
      info.isSending = item.isSending;
      info.note = item.note;

      await info.save();
      await _updateUnspents();
      await wallet.updateBalance();
    } catch (e) {
      print(e.toString());
    }
  }

  UnspentCoinsInfo getUnspentCoinInfo(
          String hash, String address, int value, int vout, String? keyImage) =>
      _unspentCoinsInfo.values.firstWhere((element) =>
          element.walletId == wallet.id &&
          element.hash == hash &&
          element.address == address &&
          element.value == value &&
          element.vout == vout &&
          element.keyImage == keyImage);

  String formatAmountToString(int fullBalance) {
    if (wallet.type == WalletType.monero)
      return monero!.formatterMoneroAmountToString(amount: fullBalance);
    if ([WalletType.bitcoin, WalletType.litecoin, WalletType.bitcoinCash].contains(wallet.type))
      return bitcoin!.formatterBitcoinAmountToString(amount: fullBalance);
    return '';
  }

  Future<void> _updateUnspents() async {
    if (wallet.type == WalletType.monero) {
      await monero!.updateUnspents(wallet);
    }
    if ([WalletType.bitcoin, WalletType.litecoin, WalletType.bitcoinCash].contains(wallet.type)) {
      await bitcoin!.updateUnspents(wallet);
    }

    _updateUnspentCoinsInfo();
  }

  List<Unspent> _getUnspents() {
    if (wallet.type == WalletType.monero) return monero!.getUnspents(wallet);
    if ([WalletType.bitcoin, WalletType.litecoin, WalletType.bitcoinCash].contains(wallet.type))
      return bitcoin!.getUnspents(wallet);
    return List.empty();
  }

  @action
  void _updateUnspentCoinsInfo() {
    _items.clear();
    _items.addAll(_getUnspents().map((elem) {
      final info =
          getUnspentCoinInfo(elem.hash, elem.address, elem.value, elem.vout, elem.keyImage);

      return UnspentCoinsItem(
        address: elem.address,
        amount: '${formatAmountToString(elem.value)} ${wallet.currency.title}',
        hash: elem.hash,
        isFrozen: info.isFrozen,
        note: info.note,
        isSending: info.isSending,
        amountRaw: elem.value,
        vout: elem.vout,
        keyImage: elem.keyImage,
        isChange: elem.isChange,
      );
    }));
  }
}
