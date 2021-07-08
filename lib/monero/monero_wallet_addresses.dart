import 'package:cake_wallet/entities/wallet_addresses.dart';
import 'package:cake_wallet/entities/wallet_addresses_credentials.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'monero_wallet_addresses_credentials.dart';

class MoneroWalletAddresses extends WalletAddresses {
  MoneroWalletAddresses(WalletInfo walletInfo) : super(walletInfo);

  @override
  Future<void> update(WalletAddressesCredentials credentials) async {
    try {
      if (credentials == null) {
        return;
      }

      final _credentials = credentials as MoneroWalletAddressesCredentials;
      final _accountList = _credentials.accountList;
      final _subaddressList = _credentials.subaddressList;

      if (_accountList == null || _subaddressList == null) {
        return;
      }

      addresses.clear();

      _accountList.accounts.forEach((account) {
        _subaddressList.update(accountIndex: account.id);
        _subaddressList.subaddresses.forEach((subaddress) {
          addresses[subaddress.address] = subaddress.label;
        });
      });

      await save();
    } catch (e) {
      print(e.toString());
    }
  }
}