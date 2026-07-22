import "dart:developer";

import "package:cw_core/payment_uris.dart";
import "package:cw_core/wallet_addresses.dart";
import "package:mobx/mobx.dart";

part "evm_chain_wallet_addresses.g.dart";

class EVMChainWalletAddresses = EVMChainWalletAddressesBase with _$EVMChainWalletAddresses;

abstract class EVMChainWalletAddressesBase extends WalletAddresses with Store {
  EVMChainWalletAddressesBase(super.walletInfo, this._selectedChainId) : address = "";

  @override
  @observable
  String address;

  @override
  String get primaryAddress => address;

  final int _selectedChainId;

  @override
  Future<void> init() async {
    address = walletInfo.address;
    await updateAddressesInBox();
  }

  @override
  Future<void> updateAddressesInBox() async {
    try {
      addressesMap.clear();
      addressesMap[address] = "";
      await saveAddressesInBox();
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  PaymentURI getPaymentUri(String amount) => ERC681URI(
        address: address,
        amount: amount,
        chainId: _selectedChainId,
        contractAddress: null,
      );
}
