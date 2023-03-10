import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/haven/haven.dart';
import 'package:cw_monero/api/wallet.dart' as monero_wallet;

part 'wallet_keys_view_model.g.dart';

class WalletKeysViewModel = WalletKeysViewModelBase with _$WalletKeysViewModel;

abstract class WalletKeysViewModelBase with Store {
  WalletKeysViewModelBase(WalletBase wallet)
      : title = wallet.type == WalletType.bitcoin || wallet.type == WalletType.litecoin
            ? S.current.wallet_seed
            : S.current.wallet_keys,
        _wallet = wallet,
        _restoreHeight = wallet.walletInfo.restoreHeight,
        items = ObservableList<StandartListItem>() {
    if (wallet.type == WalletType.monero) {
      final keys = monero!.getKeys(wallet);
      _currentHeight = monero!.getHeigthByDate(date: DateTime.now());

      items.addAll([
        if (keys['publicSpendKey'] != null)
          StandartListItem(title: S.current.spend_key_public, value: keys['publicSpendKey']!),
        if (keys['privateSpendKey'] != null)
          StandartListItem(title: S.current.spend_key_private, value: keys['privateSpendKey']!),
        if (keys['publicViewKey'] != null)
          StandartListItem(title: S.current.view_key_public, value: keys['publicViewKey']!),
        if (keys['privateViewKey'] != null)
          StandartListItem(title: S.current.view_key_private, value: keys['privateViewKey']!),
        StandartListItem(title: S.current.wallet_seed, value: wallet.seed),
      ]);
    }

    if (wallet.type == WalletType.haven) {
      final keys = haven!.getKeys(wallet);
      _currentHeight = haven!.getHeigthByDate(date: DateTime.now());

      items.addAll([
        if (keys['publicSpendKey'] != null)
          StandartListItem(title: S.current.spend_key_public, value: keys['publicSpendKey']!),
        if (keys['privateSpendKey'] != null)
          StandartListItem(title: S.current.spend_key_private, value: keys['privateSpendKey']!),
        if (keys['publicViewKey'] != null)
          StandartListItem(title: S.current.view_key_public, value: keys['publicViewKey']!),
        if (keys['privateViewKey'] != null)
          StandartListItem(title: S.current.view_key_private, value: keys['privateViewKey']!),
        StandartListItem(title: S.current.wallet_seed, value: wallet.seed),
      ]);
    }

    if (wallet.type == WalletType.bitcoin || wallet.type == WalletType.litecoin) {
      items.addAll([
        StandartListItem(title: S.current.wallet_seed, value: wallet.seed),
      ]);
    }
  }

  final ObservableList<StandartListItem> items;

  final String title;

  final WalletBase _wallet;

  final int? _restoreHeight;

  int? _currentHeight;

  String get _path {
    switch (_wallet.type) {
      case WalletType.monero:
        return 'monero_wallet:';
      case WalletType.bitcoin:
        return 'bitcoin_wallet:';
      case WalletType.litecoin:
        return 'litecoin_wallet:';
      case WalletType.haven:
        return 'haven_wallet:';
      default:
        throw Exception('Unexpected wallet type: ${_wallet.toString()}');
    }
  }

  String get restoreHeight {
    if (_currentHeight == null) {
      return '';
    }
    if (_restoreHeight != 0) {
      return _restoreHeight.toString();
    }
    return ((_currentHeight! / 1000).floor() * 1000).toString();
  }

  Map<String, String> get _queryParams => {'seed': _wallet.seed, 'height': restoreHeight};

  Uri get url {
    return Uri(
      path: _path,
      queryParameters: _queryParams,
    );
  }
}
