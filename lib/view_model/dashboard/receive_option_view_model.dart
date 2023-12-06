import 'package:cake_wallet/entities/receive_page_option.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cake_wallet/generated/i18n.dart';

part 'receive_option_view_model.g.dart';

class ReceiveOptionViewModel = ReceiveOptionViewModelBase with _$ReceiveOptionViewModel;

abstract class ReceiveOptionViewModelBase with Store {
  ReceiveOptionViewModelBase(this._wallet, this.initialPageOption)
      : selectedReceiveOption = initialPageOption ??
            (_wallet.type == WalletType.bitcoin
                ? _wallet.walletAddresses.addressPageType
                : ReceivePageOption.mainnet),
        _options = [] {
    final walletType = _wallet.type;
    _options = walletType == WalletType.haven
        ? [ReceivePageOption.mainnet]
        : walletType == WalletType.bitcoin
            ? [
                bitcoin.AddressType.p2wpkh,
                bitcoin.AddressType.p2sp,
                bitcoin.AddressType.p2tr,
                bitcoin.AddressType.p2pkh,
                ...ReceivePageOption.values.where((element) => element != ReceivePageOption.mainnet)
              ]
            : ReceivePageOption.values;
  }

  final WalletBase _wallet;

  final dynamic initialPageOption;

  List<dynamic> _options;

  @observable
  dynamic selectedReceiveOption;

  List<dynamic> get options => _options;

  @action
  void selectReceiveOption(dynamic option) {
    selectedReceiveOption = option;
  }
}

String describeOption(dynamic option) {
  if (option is ReceivePageOption) {
    return option.toString();
  }

  if (option is bitcoin.AddressType) {
    switch (option) {
      case bitcoin.AddressType.p2sp:
        return S.current.bitcoin_silent_payments;
      case bitcoin.AddressType.p2pkh:
        return S.current.bitcoin_legacy;
      default:
        return option.toString();
    }
  }

  return "";
}
