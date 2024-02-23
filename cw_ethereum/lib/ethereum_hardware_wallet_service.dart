import 'package:cw_evm/evm_chain_hardware_wallet_service.dart';
import 'package:ledger_ethereum/ledger_ethereum.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

class EthereumHardwareWalletService extends EVMChainHardwareWalletService {
  EthereumHardwareWalletService(LedgerDevice device) : super(device);

  @override
  Future<List<String>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final ethereumLedgerApp = EthereumLedgerApp(ledger);

    print("Start loading availableAccounts"); // TODO: (Konsti) remove
    await ledger.connect(device, options: LedgerOptions(connectionTimeout: Duration(seconds: 10)));

    final version = await ethereumLedgerApp.getVersion(device);
    print(version.version); // TODO: (Konsti) remove

    final accounts = <String>[];
    final indexRange = List.generate(limit, (i) => i + index);

    for (final i in indexRange) {
      final derivationPath = "m/44'/60'/$i'/0/0";
      print(derivationPath); // TODO: (Konsti) remove
      final account = await ethereumLedgerApp.getAccounts(device, derivationPath);
      accounts.addAll(account);
    }

    await ledger.disconnect(device);

    return accounts;
  }
}
