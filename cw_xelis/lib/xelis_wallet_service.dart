import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_xelis/src/api/wallet.dart';
import 'package:cw_xelis/src/api/network.dart';

class XelisNewWalletCredentials extends WalletCredentials {
  XelisNewWalletCredentials(
      {required String name, required this.language, this.passphrase, String? password})
      : super(name: name, password: password);

  final String language;
  final String? passphrase;
}

class XelisRestoreWalletFromSeedCredentials extends WalletCredentials {
  XelisRestoreWalletFromSeedCredentials(
      {required String name, required this.mnemonic, required this.passphrase, int height = 0, String? password})
      : super(name: name, password: password, height: height);

  final String mnemonic;
  final String passphrase;
}

class XelisWalletService extends WalletService<
    XelisNewWalletCredentials,
    XelisRestoreWalletFromSeedCredentials,
> 
with Store, WalletKeysFile {
  XelisWalletService(super.walletInfoSource);

  @override
  WalletType getType() => WalletType.xelis;

  Future<String> pathForTables() async {
    final root = await getAppDir();
    final prefix = walletTypeToString(WalletType.xelis).toLowerCase();
    final walletsDir = Directory('${root.path}/wallets');
    final walletDire = Directory('${walletsDir.path}/$prefix/tables');

    if (!walletDire.existsSync()) {
      walletDire.createSync(recursive: true);
    }

    return walletDire.path;
  }

  @override
  Future<XelisWallet> create(XelisNewWalletCredentials credentials, {bool? isTestnet}) async {
    final fullPath = await pathForWallet(name: credentials.name, type:WalletType.xelis);
    final tablePath = await pathForTables();
    final tableState = await getTableState();

    final Network network;

    if (isTestnet == false) {
      network = Network.mainnet
    } else {
      network = Network.testnet
    }

    final wallet = await x_wallet.createXelisWallet(
      name: fullPath,
      directory: "",
      password: credentials.password,
      network: network,
      precomputedTablesPath: tablePath,
      l1Low: tableState.currentSize.isLow,
    );

    return wallet;
  }

  @override
  Future<XelisWallet> openWallet(String name, String password, {bool? isTestnet}) async {
    final fullPath = await pathForWallet(name: credentials.name, type:WalletType.xelis);
    final tablePath = await pathForTables();
    final tableState = await getTableState();

    final Network network;

    if (isTestnet == false) {
      network = Network.mainnet
    } else {
      network = Network.testnet
    }

    try {
      final wallet = await openXelisWallet(
        name: fullPath,
        directory: directory,
        password: password,
        network: network,
        precomputedTablesPath: tablePath,
        l1Low: tableState.currentSize.isLow,
      );

      saveBackup(name);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);

      final wallet = await openXelisWallet(
        name: fullPath,
        directory: directory,
        password: password,
        network: network,
        precomputedTablesPath: tablePath,
        l1Low: tableState.currentSize.isLow,
      );

      return wallet;
    }
  }

  // @override
  // Future<void> rename(String currentName, String password, String newName) async {
  //   final currentWalletInfo = walletInfoSource.values
  //       .firstWhere((info) => info.id == WalletBase.idFor(currentName, getType()));
  //   final currentWallet = await EthereumWallet.open(
  //     password: password,
  //     name: currentName,
  //     walletInfo: currentWalletInfo,
  //     encryptionFileUtils: encryptionFileUtilsFor(isDirect),
  //   );

  //   await currentWallet.renameWalletFiles(newName);
  //   await saveBackup(newName);

  //   final newWalletInfo = currentWalletInfo;
  //   newWalletInfo.id = WalletBase.idFor(newName, getType());
  //   newWalletInfo.name = newName;

  //   await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  // }

  // @override
  // Future<EthereumWallet> restoreFromHardwareWallet(
  //     EVMChainRestoreWalletFromHardware credentials) async {
  //   credentials.walletInfo!.derivationInfo = DerivationInfo(
  //     derivationType: DerivationType.bip39,
  //     derivationPath: "m/44'/60'/${credentials.hwAccountData.accountIndex}'/0/0"
  //   );
  //   credentials.walletInfo!.hardwareWalletType = credentials.hardwareWalletType;
  //   credentials.walletInfo!.address = credentials.hwAccountData.address;

  //   final wallet = EthereumWallet(
  //     walletInfo: credentials.walletInfo!,
  //     password: credentials.password!,
  //     client: client,
  //     encryptionFileUtils: encryptionFileUtilsFor(isDirect),
  //   );

  //   await wallet.init();
  //   wallet.addInitialTokens();
  //   await wallet.save();

  //   return wallet;
  // }

  // @override
  // Future<EthereumWallet> restoreFromKeys(EVMChainRestoreWalletFromPrivateKey credentials,
  //     {bool? isTestnet}) async {
  //   final wallet = EthereumWallet(
  //     password: credentials.password!,
  //     privateKey: credentials.privateKey,
  //     walletInfo: credentials.walletInfo!,
  //     client: client,
  //     encryptionFileUtils: encryptionFileUtilsFor(isDirect),
  //   );

  //   await wallet.init();
  //   wallet.addInitialTokens();
  //   await wallet.save();

  //   return wallet;
  // }

  // @override
  // Future<EthereumWallet> restoreFromSeed(EVMChainRestoreWalletFromSeedCredentials credentials,
  //     {bool? isTestnet}) async {
  //   if (!bip39.validateMnemonic(credentials.mnemonic)) {
  //     throw EthereumMnemonicIsIncorrectException();
  //   }

  //   final wallet = EthereumWallet(
  //     password: credentials.password!,
  //     mnemonic: credentials.mnemonic,
  //     walletInfo: credentials.walletInfo!,
  //     passphrase: credentials.passphrase,
  //     client: client,
  //     encryptionFileUtils: encryptionFileUtilsFor(isDirect),
  //   );

  //   await wallet.init();
  //   wallet.addInitialTokens();
  //   await wallet.save();

  //   return wallet;
  // }
}
