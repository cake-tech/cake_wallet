import 'package:cake_wallet/store/yat/yat_store.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/utils/list_item.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_account_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'dart:async';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/haven/haven.dart';

part 'wallet_address_list_view_model.g.dart';

class WalletAddressListViewModel = WalletAddressListViewModelBase
    with _$WalletAddressListViewModel;

abstract class PaymentURI {
  PaymentURI({this.amount, this.address});

  final String amount;
  final String address;
}

class MoneroURI extends PaymentURI {
  MoneroURI({String amount, String address})
      : super(amount: amount, address: address);

  @override
  String toString() {
    var base = 'monero:' + address;

    if (amount?.isNotEmpty ?? false) {
      base += '?tx_amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class HavenURI extends PaymentURI {
  HavenURI({String amount, String address})
      : super(amount: amount, address: address);

  @override
  String toString() {
    var base = 'haven:' + address;

    if (amount?.isNotEmpty ?? false) {
      base += '?tx_amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class BitcoinURI extends PaymentURI {
  BitcoinURI({String amount, String address})
      : super(amount: amount, address: address);

  @override
  String toString() {
    var base = 'bitcoin:' + address;

    if (amount?.isNotEmpty ?? false) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class LitecoinURI extends PaymentURI {
  LitecoinURI({String amount, String address})
      : super(amount: amount, address: address);

  @override
  String toString() {
    var base = 'litecoin:' + address;

    if (amount?.isNotEmpty ?? false) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

abstract class WalletAddressListViewModelBase with Store {
  WalletAddressListViewModelBase({
    @required AppStore appStore,
    @required this.yatStore
  }) {
    _appStore = appStore;
    _wallet = _appStore.wallet;
    hasAccounts = _wallet?.type == WalletType.monero || _wallet?.type == WalletType.haven;

    _onWalletChangeReaction = reaction((_) => _appStore.wallet, (WalletBase<
            Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>
        wallet) {
      _wallet = wallet;
      hasAccounts = _wallet.type == WalletType.monero;
    });
    _init();
  }

  @observable
  String amount;

  @computed
  WalletType get type => _wallet.type;

  @computed
  WalletAddressListItem get address =>
      WalletAddressListItem(address: _wallet.walletAddresses.address);

  @computed
  PaymentURI get uri {
    if (_wallet.type == WalletType.monero) {
      return MoneroURI(amount: amount, address: address.address);
    }

    if (_wallet.type == WalletType.haven) {
      return HavenURI(amount: amount, address: address.address);
    }

    if (_wallet.type == WalletType.bitcoin) {
      return BitcoinURI(amount: amount, address: address.address);
    }

    if (_wallet.type == WalletType.litecoin) {
      return LitecoinURI(amount: amount, address: address.address);
    }

    return null;
  }

  @computed
  ObservableList<ListItem> get items =>
      ObservableList<ListItem>()..addAll(_baseItems)..addAll(addressList);

  @computed
  ObservableList<ListItem> get addressList {
    final wallet = _wallet;
    final addressList = ObservableList<ListItem>();

    if (wallet.type == WalletType.monero) {
      final primaryAddress = monero.getSubaddressList(wallet).subaddresses.first;
      final addressItems = monero
        .getSubaddressList(wallet)
        .subaddresses
          .map((subaddress) {
        final isPrimary = subaddress == primaryAddress;

        return WalletAddressListItem(
            id: subaddress.id,
            isPrimary: isPrimary,
            name: subaddress.label,
            address: subaddress.address);
      });
      addressList.addAll(addressItems);
    }

    if (wallet.type == WalletType.haven) {
      final primaryAddress = haven.getSubaddressList(wallet).subaddresses.first;
      final addressItems = haven
        .getSubaddressList(wallet)
        .subaddresses
          .map((subaddress) {
        final isPrimary = subaddress == primaryAddress;

        return WalletAddressListItem(
            id: subaddress.id,
            isPrimary: isPrimary,
            name: subaddress.label,
            address: subaddress.address);
      });
      addressList.addAll(addressItems);
    }

    if (wallet.type == WalletType.bitcoin) {
      final primaryAddress = bitcoin.getAddress(wallet);
      final bitcoinAddresses = bitcoin.getAddresses(wallet).map((addr) {
        final isPrimary = addr == primaryAddress;

        return WalletAddressListItem(
            isPrimary: isPrimary, name: null, address: addr);
      });
      addressList.addAll(bitcoinAddresses);
    }

    return addressList;
  }

  @observable
  bool hasAccounts;

  @computed
  String get accountLabel {
    final wallet = _wallet;

    if (wallet.type == WalletType.monero) {
      return monero.getCurrentAccount(wallet).label;
    }

    if (wallet.type == WalletType.haven) {
      return haven.getCurrentAccount(wallet).label;
    }

    return null;
  }

  @computed
  bool get hasAddressList => _wallet.type == WalletType.monero || _wallet.type == WalletType.haven;

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>
      _wallet;

  List<ListItem> _baseItems;

  AppStore _appStore;

  final YatStore yatStore;

  ReactionDisposer _onWalletChangeReaction;

  @action
  void setAddress(WalletAddressListItem address) =>
      _wallet.walletAddresses.address = address.address;

  void _init() {
    _baseItems = [];

    if (_wallet.type == WalletType.monero || _wallet.type == WalletType.haven) {
      _baseItems.add(WalletAccountListHeader());
    }

    _baseItems.add(WalletAddressListHeader());
  }
}
