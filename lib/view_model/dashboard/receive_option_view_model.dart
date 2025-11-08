import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'receive_option_view_model.g.dart';

class ReceiveOptionViewModel = ReceiveOptionViewModelBase with _$ReceiveOptionViewModel;

abstract class ReceiveOptionViewModelBase with Store {
  ReceiveOptionViewModelBase(this._wallet, this.initialPageOption)
      : selectedReceiveOption = initialPageOption ??
            ([WalletType.bitcoin, WalletType.litecoin].contains(_wallet.type)
                ? bitcoin!.getSelectedAddressType(_wallet)
                : (_wallet.type == WalletType.decred && _wallet.isTestnet)
                    ? ReceivePageOption.testnet
                    : ReceivePageOption.mainnet);

  final WalletBase _wallet;

  final ReceivePageOption? initialPageOption;

  @observable
  ReceivePageOption selectedReceiveOption;

  List<ReceivePageOption> get options => _wallet.walletAddresses.receivePageOptions;

  @action
  void selectReceiveOption(ReceivePageOption option) => selectedReceiveOption = option;
}
