import 'package:cake_wallet/bitcoin/electrum_wallet_addresses_credentials.dart';
import 'package:cake_wallet/entities/wallet_addresses.dart';
import 'package:cake_wallet/entities/wallet_addresses_credentials.dart';
import 'package:cake_wallet/entities/wallet_info.dart';

class ElectrumWalletAddresses extends WalletAddresses {
  ElectrumWalletAddresses(WalletInfo walletInfo) : super(walletInfo);

  @override
  Future<void> update(WalletAddressesCredentials credentials) async {
    try {
      if (credentials == null) {
        return;
      }

      final _credentials = credentials as ElectrumWalletAddressesCredentials;
      final _address = _credentials.address;
      final _label = '';

      if (_address == null || _address.isEmpty) {
        return;
      }

      addresses.clear();
      addresses[_address] = _label;

      await save();
    } catch (e) {
      print(e.toString());
    }
  }
}