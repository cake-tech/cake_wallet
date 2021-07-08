import 'package:cake_wallet/entities/wallet_addresses_credentials.dart';
import 'package:cake_wallet/monero/monero_account_list.dart';
import 'package:cake_wallet/monero/monero_subaddress_list.dart';

class MoneroWalletAddressesCredentials extends WalletAddressesCredentials {

  MoneroAccountList accountList;
  MoneroSubaddressList subaddressList;
}