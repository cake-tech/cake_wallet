import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_cash_wallet_addresses.g.dart';

class BitcoinCashWalletAddresses = BitcoinCashWalletAddressesBase with _$BitcoinCashWalletAddresses;

abstract class BitcoinCashWalletAddressesBase extends ElectrumWalletAddresses with Store {
  BitcoinCashWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.hdWallets,
    required super.network,
    required super.isHardwareWallet,
    super.initialAddresses,
    super.initialAddressPageType,
  }) : super(walletInfo);

  @override
  Future<void> init() async {
    await generateInitialAddresses(type: P2pkhAddressType.p2pkh);
    await super.init();
  }

  @override
  BitcoinBaseAddress generateAddress({
    required CWBitcoinDerivationType derivationType,
    required bool isChange,
    required int index,
    required BitcoinAddressType addressType,
    required BitcoinDerivationInfo derivationInfo,
  }) =>
      P2pkhAddress.fromDerivation(
        bip32: hdWallet,
        derivationInfo: derivationInfo,
        isChange: isChange,
        index: index,
      );
}
