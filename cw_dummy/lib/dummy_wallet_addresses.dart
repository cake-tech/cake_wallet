import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_addresses.dart';

part 'dummy_wallet_addresses.g.dart';

class DummyWalletAddresses = DummyWalletAddressesBase with _$DummyWalletAddresses;

abstract class DummyWalletAddressesBase extends WalletAddresses with Store {
  DummyWalletAddressesBase(super.walletInfo);

  @override
  @observable
  late String address;

  @override
  Future<void> init() async => throw UnimplementedError();

  @override
  Future<void> updateAddressesInBox() async => throw UnimplementedError();

  // TODO: from electrum wallet addresses implementation
  Future<void> generateNewAddress() async => throw UnimplementedError();
}