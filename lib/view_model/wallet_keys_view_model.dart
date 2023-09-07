import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
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
  WalletKeysViewModelBase(this._appStore)
      : title = _appStore.wallet!.type == WalletType.bitcoin ||
                _appStore.wallet!.type == WalletType.litecoin ||
                _appStore.wallet!.type == WalletType.ethereum
            ? S.current.wallet_seed
            : S.current.wallet_keys,
        _restoreHeight = _appStore.wallet!.walletInfo.restoreHeight,
        _restoreHeightByTransactions = 0,
        items = ObservableList<StandartListItem>() {
    _populateItems();

    reaction((_) => _appStore.wallet, (WalletBase? _wallet) {
      _populateItems();
    });

    if (_appStore.wallet!.type == WalletType.monero || _appStore.wallet!.type == WalletType.haven) {
      final accountTransactions = _getWalletTransactions(_appStore.wallet!);
      if (accountTransactions.isNotEmpty) {
        final incomingAccountTransactions =
            accountTransactions.where((tx) => tx.direction == TransactionDirection.incoming);
        if (incomingAccountTransactions.isNotEmpty) {
          incomingAccountTransactions.toList().sort((a, b) => a.date.compareTo(b.date));
          _restoreHeightByTransactions = _getRestoreHeightByTransactions(
              _appStore.wallet!.type, incomingAccountTransactions.first.date);
        }
      }
    }
  }

  final ObservableList<StandartListItem> items;

  final String title;

  final AppStore _appStore;

  final int _restoreHeight;

  int _restoreHeightByTransactions;

  void _populateItems() {
    items.clear();

    if (_appStore.wallet!.type == WalletType.monero) {
      final keys = monero!.getKeys(_appStore.wallet!);

      items.addAll([
        if (keys['publicSpendKey'] != null)
          StandartListItem(title: S.current.spend_key_public, value: keys['publicSpendKey']!),
        if (keys['privateSpendKey'] != null)
          StandartListItem(title: S.current.spend_key_private, value: keys['privateSpendKey']!),
        if (keys['publicViewKey'] != null)
          StandartListItem(title: S.current.view_key_public, value: keys['publicViewKey']!),
        if (keys['privateViewKey'] != null)
          StandartListItem(title: S.current.view_key_private, value: keys['privateViewKey']!),
        StandartListItem(title: S.current.wallet_seed, value: _appStore.wallet!.seed!),
      ]);
    }

    if (_appStore.wallet!.type == WalletType.haven) {
      final keys = haven!.getKeys(_appStore.wallet!);

      items.addAll([
        if (keys['publicSpendKey'] != null)
          StandartListItem(title: S.current.spend_key_public, value: keys['publicSpendKey']!),
        if (keys['privateSpendKey'] != null)
          StandartListItem(title: S.current.spend_key_private, value: keys['privateSpendKey']!),
        if (keys['publicViewKey'] != null)
          StandartListItem(title: S.current.view_key_public, value: keys['publicViewKey']!),
        if (keys['privateViewKey'] != null)
          StandartListItem(title: S.current.view_key_private, value: keys['privateViewKey']!),
        StandartListItem(title: S.current.wallet_seed, value: _appStore.wallet!.seed!),
      ]);
    }

    if (_appStore.wallet!.type == WalletType.bitcoin ||
        _appStore.wallet!.type == WalletType.litecoin) {
      items.addAll([
        StandartListItem(title: S.current.wallet_seed, value: _appStore.wallet!.seed!),
      ]);
    }

    if (_appStore.wallet!.type == WalletType.ethereum) {
      items.addAll([
        if (_appStore.wallet!.privateKey != null)
          StandartListItem(title: S.current.private_key, value: _appStore.wallet!.privateKey!),
        if (_appStore.wallet!.seed != null)
          StandartListItem(title: S.current.wallet_seed, value: _appStore.wallet!.seed!),
      ]);
    }
  }

  Future<int?> _currentHeight() async {
    if (_appStore.wallet!.type == WalletType.haven) {
      return await haven!.getCurrentHeight();
    }
    if (_appStore.wallet!.type == WalletType.monero) {
      return monero_wallet.getCurrentHeight();
    }
    return null;
  }

  String get _scheme {
    switch (_appStore.wallet!.type) {
      case WalletType.monero:
        return 'monero-wallet';
      case WalletType.bitcoin:
        return 'bitcoin-wallet';
      case WalletType.litecoin:
        return 'litecoin-wallet';
      case WalletType.haven:
        return 'haven-wallet';
      case WalletType.ethereum:
        return 'ethereum-wallet';
      default:
        throw Exception('Unexpected wallet type: ${_appStore.wallet!.toString()}');
    }
  }

  Future<String?> get restoreHeight async {
    if (_restoreHeightByTransactions != 0)
      return getRoundedRestoreHeight(_restoreHeightByTransactions);
    if (_restoreHeight != 0) return _restoreHeight.toString();

    final currentHeight = await _currentHeight();
    if (currentHeight == null) return null;

    return getRoundedRestoreHeight(currentHeight);
  }

  Future<Map<String, String>> get _queryParams async {
    final restoreHeightResult = await restoreHeight;
    return {
      if (_appStore.wallet!.seed != null) 'seed': _appStore.wallet!.seed!,
      if (_appStore.wallet!.privateKey != null) 'private_key': _appStore.wallet!.privateKey!,
      if (restoreHeightResult != null) ...{'height': restoreHeightResult}
    };
  }

  Future<Uri> get url async => Uri(
        scheme: _scheme,
        queryParameters: await _queryParams,
      );

  List<TransactionInfo> _getWalletTransactions(WalletBase wallet) {
    if (wallet.type == WalletType.monero) {
      return monero!.getTransactionHistory(wallet).transactions.values.toList();
    } else if (wallet.type == WalletType.haven) {
      return haven!.getTransactionHistory(wallet).transactions.values.toList();
    }
    return [];
  }

  int _getRestoreHeightByTransactions(WalletType type, DateTime date) {
    if (type == WalletType.monero) {
      return monero!.getHeigthByDate(date: date);
    } else if (type == WalletType.haven) {
      return haven!.getHeightByDate(date: date);
    }
    return 0;
  }

  String getRoundedRestoreHeight(int height) => ((height / 1000).floor() * 1000).toString();
}
