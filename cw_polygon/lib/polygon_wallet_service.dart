import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/evm_chain_wallet_creation_credentials.dart';
import 'package:cw_evm/evm_chain_wallet_service.dart';
import 'package:cw_polygon/polygon_client.dart';
import 'package:cw_polygon/polygon_mnemonics_exception.dart';
import 'package:cw_polygon/polygon_wallet.dart';

class PolygonWalletService extends EVMChainWalletService<PolygonWallet> {
  PolygonWalletService(
    super.walletInfoSource, super.isDirect, {
    required this.client,
  });

  late PolygonClient client;

  @override
  WalletType getType() => WalletType.polygon;

  @override
  Future<PolygonWallet> create(EVMChainNewWalletCredentials credentials, {bool? isTestnet}) async {
    final strength = credentials.seedPhraseLength == 24 ? 256 : 128;

    final mnemonic = credentials.mnemonic ?? bip39.generateMnemonic(strength: strength);

    final wallet = PolygonWallet(
      walletInfo: credentials.walletInfo!,
      mnemonic: mnemonic,
      password: credentials.password!,
      client: client,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();
    return wallet;
  }

  @override
  Future<PolygonWallet> openWallet(String name, String password) async {
    final walletInfo =
        walletInfoSource.values.firstWhere((info) => info.id == WalletBase.idFor(name, getType()));

    try {
      final wallet = await PolygonWallet.open(
        name: name,
        password: password,
        walletInfo: walletInfo,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );

      await wallet.init();
      await wallet.save();
      saveBackup(name);
      return wallet;
    } catch (_) {
      await restoreWalletFilesFromBackup(name);

      final wallet = await PolygonWallet.open(
        name: name,
        password: password,
        walletInfo: walletInfo,
        encryptionFileUtils: encryptionFileUtilsFor(isDirect),
      );

      await wallet.init();
      await wallet.save();
      return wallet;
    }
  }

  @override
  Future<PolygonWallet> restoreFromKeys(EVMChainRestoreWalletFromPrivateKey credentials,
      {bool? isTestnet}) async {
    final wallet = PolygonWallet(
      password: credentials.password!,
      privateKey: credentials.privateKey,
      walletInfo: credentials.walletInfo!,
      client: client,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();
    return wallet;
  }

  @override
  Future<PolygonWallet> restoreFromHardwareWallet(
      EVMChainRestoreWalletFromHardware credentials) async {
    credentials.walletInfo!.derivationInfo = DerivationInfo(
        derivationType: DerivationType.bip39,
        derivationPath: "m/44'/60'/${credentials.hwAccountData.accountIndex}'/0/0"
    );
    credentials.walletInfo!.hardwareWalletType = credentials.hardwareWalletType;
    credentials.walletInfo!.address = credentials.hwAccountData.address;

    final wallet = PolygonWallet(
      walletInfo: credentials.walletInfo!,
      password: credentials.password!,
      client: client,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();

    return wallet;
  }

  @override
  Future<PolygonWallet> restoreFromSeed(EVMChainRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    if (!bip39.validateMnemonic(credentials.mnemonic)) {
      throw PolygonMnemonicIsIncorrectException();
    }

    final wallet = PolygonWallet(
      password: credentials.password!,
      mnemonic: credentials.mnemonic,
      walletInfo: credentials.walletInfo!,
      client: client,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await wallet.init();
    wallet.addInitialTokens();
    await wallet.save();

    return wallet;
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values
        .firstWhere((info) => info.id == WalletBase.idFor(currentName, getType()));
    final currentWallet = await PolygonWallet.open(
      password: password,
      name: currentName,
      walletInfo: currentWalletInfo,
      encryptionFileUtils: encryptionFileUtilsFor(isDirect),
    );

    await currentWallet.renameWalletFiles(newName);
    await saveBackup(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }
}
