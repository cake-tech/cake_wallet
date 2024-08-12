import 'dart:io';

const bitcoinOutputPath = 'lib/bitcoin/bitcoin.dart';
const moneroOutputPath = 'lib/monero/monero.dart';
const havenOutputPath = 'lib/haven/haven.dart';
const ethereumOutputPath = 'lib/ethereum/ethereum.dart';
const bitcoinCashOutputPath = 'lib/bitcoin_cash/bitcoin_cash.dart';
const nanoOutputPath = 'lib/nano/nano.dart';
const polygonOutputPath = 'lib/polygon/polygon.dart';
const solanaOutputPath = 'lib/solana/solana.dart';
const tronOutputPath = 'lib/tron/tron.dart';
const wowneroOutputPath = 'lib/wownero/wownero.dart';
const walletTypesPath = 'lib/wallet_types.g.dart';
const secureStoragePath = 'lib/core/secure_storage.dart';
const pubspecDefaultPath = 'pubspec_default.yaml';
const pubspecOutputPath = 'pubspec.yaml';

Future<void> main(List<String> args) async {
  const prefix = '--';
  final hasBitcoin = args.contains('${prefix}bitcoin');
  final hasMonero = args.contains('${prefix}monero');
  final hasHaven = args.contains('${prefix}haven');
  final hasEthereum = args.contains('${prefix}ethereum');
  final hasBitcoinCash = args.contains('${prefix}bitcoinCash');
  final hasNano = args.contains('${prefix}nano');
  final hasBanano = args.contains('${prefix}banano');
  final hasPolygon = args.contains('${prefix}polygon');
  final hasSolana = args.contains('${prefix}solana');
  final hasTron = args.contains('${prefix}tron');
  final hasWownero = args.contains('${prefix}wownero');
  final excludeFlutterSecureStorage = args.contains('${prefix}excludeFlutterSecureStorage');

  await generateBitcoin(hasBitcoin);
  await generateMonero(hasMonero);
  await generateHaven(hasHaven);
  await generateEthereum(hasEthereum);
  await generateBitcoinCash(hasBitcoinCash);
  await generateNano(hasNano);
  await generatePolygon(hasPolygon);
  await generateSolana(hasSolana);
  await generateTron(hasTron);
  await generateWownero(hasWownero);
  // await generateBanano(hasEthereum);

  await generatePubspec(
    hasMonero: hasMonero,
    hasBitcoin: hasBitcoin,
    hasHaven: hasHaven,
    hasEthereum: hasEthereum,
    hasNano: hasNano,
    hasBanano: hasBanano,
    hasBitcoinCash: hasBitcoinCash,
    hasFlutterSecureStorage: !excludeFlutterSecureStorage,
    hasPolygon: hasPolygon,
    hasSolana: hasSolana,
    hasTron: hasTron,
    hasWownero: hasWownero,
  );
  await generateWalletTypes(
    hasMonero: hasMonero,
    hasBitcoin: hasBitcoin,
    hasHaven: hasHaven,
    hasEthereum: hasEthereum,
    hasNano: hasNano,
    hasBanano: hasBanano,
    hasBitcoinCash: hasBitcoinCash,
    hasPolygon: hasPolygon,
    hasSolana: hasSolana,
    hasTron: hasTron,
    hasWownero: hasWownero,
  );
  await injectSecureStorage(!excludeFlutterSecureStorage);
}

Future<void> generateBitcoin(bool hasImplementation) async {
  final outputFile = File(bitcoinOutputPath);
  const bitcoinCommonHeaders = """
import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:bip39/bip39.dart' as bip39;
""";
  const bitcoinCWHeaders = """
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/bitcoin_receive_page_option.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_wallet_service.dart';
import 'package:cw_bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/litecoin_wallet_service.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_bitcoin/script_hash.dart';
import 'package:cw_bitcoin/bitcoin_hardware_wallet_service.dart';
import 'package:mobx/mobx.dart';
""";
  const bitcoinCwPart = "part 'cw_bitcoin.dart';";
  const bitcoinContent = """
  
  class ElectrumSubAddress {
  ElectrumSubAddress({
    required this.id,
    required this.name,
    required this.address,
    required this.txCount,
    required this.balance,
    required this.isChange});
  final int id;
  final String name;
  final String address;
  final int txCount;
  final int balance;
  final bool isChange;
}

abstract class Bitcoin {
  TransactionPriority getMediumTransactionPriority();

  WalletCredentials createBitcoinRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    required DerivationType derivationType,
    required String derivationPath,
    String? passphrase,
  });
  WalletCredentials createBitcoinRestoreWalletFromWIFCredentials({required String name, required String password, required String wif, WalletInfo? walletInfo});
  WalletCredentials createBitcoinNewWalletCredentials({required String name, WalletInfo? walletInfo, String? password});
  WalletCredentials createBitcoinHardwareWalletCredentials({required String name, required HardwareAccountData accountData, WalletInfo? walletInfo});
  List<String> getWordList();
  Map<String, String> getWalletKeys(Object wallet);
  List<TransactionPriority> getTransactionPriorities();
  List<TransactionPriority> getLitecoinTransactionPriorities();
  TransactionPriority deserializeBitcoinTransactionPriority(int raw);
  TransactionPriority deserializeLitecoinTransactionPriority(int raw);
  int getFeeRate(Object wallet, TransactionPriority priority);
  Future<void> generateNewAddress(Object wallet, String label);
  Future<void> updateAddress(Object wallet,String address, String label);
  Object createBitcoinTransactionCredentials(List<Output> outputs, {required TransactionPriority priority, int? feeRate});
  Object createBitcoinTransactionCredentialsRaw(List<OutputInfo> outputs, {TransactionPriority? priority, required int feeRate});

  String getAddress(Object wallet);
  List<ElectrumSubAddress> getSilentPaymentAddresses(Object wallet);
  List<ElectrumSubAddress> getSilentPaymentReceivedAddresses(Object wallet);

  Future<int> estimateFakeSendAllTxAmount(Object wallet, TransactionPriority priority);
  List<ElectrumSubAddress> getSubAddresses(Object wallet);

  String formatterBitcoinAmountToString({required int amount});
  double formatterBitcoinAmountToDouble({required int amount});
  int formatterStringDoubleToBitcoinAmount(String amount);
  String bitcoinTransactionPriorityWithLabel(TransactionPriority priority, int rate, {int? customRate});

  List<Unspent> getUnspents(Object wallet);
  Future<void> updateUnspents(Object wallet);
  WalletService createBitcoinWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource, bool alwaysScan, bool isDirect);
  WalletService createLitecoinWalletService(Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource, bool isDirect);
  TransactionPriority getBitcoinTransactionPriorityMedium();
  TransactionPriority getBitcoinTransactionPriorityCustom();
  TransactionPriority getLitecoinTransactionPriorityMedium();
  TransactionPriority getBitcoinTransactionPrioritySlow();
  TransactionPriority getLitecoinTransactionPrioritySlow();
  Future<List<DerivationType>> compareDerivationMethods(
      {required String mnemonic, required Node node});
  Future<List<DerivationInfo>> getDerivationsFromMnemonic(
      {required String mnemonic, required Node node, String? passphrase});
  Map<DerivationType, List<DerivationInfo>> getElectrumDerivations();
  Future<void> setAddressType(Object wallet, dynamic option);
  ReceivePageOption getSelectedAddressType(Object wallet);
  List<ReceivePageOption> getBitcoinReceivePageOptions();
  BitcoinAddressType getBitcoinAddressType(ReceivePageOption option);
  bool hasSelectedSilentPayments(Object wallet);
  bool isBitcoinReceivePageOption(ReceivePageOption option);
  BitcoinAddressType getOptionToType(ReceivePageOption option);
  bool hasTaprootInput(PendingTransaction pendingTransaction);
  bool getScanningActive(Object wallet);
  Future<void> setScanningActive(Object wallet, bool active);
  bool isTestnet(Object wallet);

  Future<PendingTransaction> replaceByFee(Object wallet, String transactionHash, String fee);
  Future<bool> canReplaceByFee(Object wallet, String transactionHash);
  Future<bool> isChangeSufficientForFee(Object wallet, String txId, String newFee);
  int getFeeAmountForPriority(Object wallet, TransactionPriority priority, int inputsCount, int outputsCount, {int? size});
  int getEstimatedFeeWithFeeRate(Object wallet, int feeRate, int? amount,
      {int? outputsCount, int? size});
  int feeAmountWithFeeRate(Object wallet, int feeRate, int inputsCount, int outputsCount, {int? size});
  int getHeightByDate({required DateTime date});
  Future<void> rescan(Object wallet, {required int height, bool? doSingleScan});
  Future<bool> getNodeIsElectrsSPEnabled(Object wallet);
  void deleteSilentPaymentAddress(Object wallet, String address);
  Future<void> updateFeeRates(Object wallet);
  int getMaxCustomFeeRate(Object wallet);

  void setLedger(WalletBase wallet, Ledger ledger, LedgerDevice device);
  Future<List<HardwareAccountData>> getHardwareWalletAccounts(LedgerViewModel ledgerVM, {int index = 0, int limit = 5});
}
  """;

  const bitcoinEmptyDefinition = 'Bitcoin? bitcoin;\n';
  const bitcoinCWDefinition = 'Bitcoin? bitcoin = CWBitcoin();\n';

  final output = '$bitcoinCommonHeaders\n' +
      (hasImplementation ? '$bitcoinCWHeaders\n' : '\n') +
      (hasImplementation ? '$bitcoinCwPart\n\n' : '\n') +
      (hasImplementation ? bitcoinCWDefinition : bitcoinEmptyDefinition) +
      '\n' +
      bitcoinContent;

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}

Future<void> generateMonero(bool hasImplementation) async {
  final outputFile = File(moneroOutputPath);
  const moneroCommonHeaders = """
import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/output_info.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';
import 'package:polyseed/polyseed.dart';""";
  const moneroCWHeaders = """
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_monero/monero_unspent.dart';
import 'package:cw_monero/monero_wallet_service.dart';
import 'package:cw_monero/api/wallet_manager.dart';
import 'package:cw_monero/monero_wallet.dart';
import 'package:cw_monero/monero_transaction_info.dart';
import 'package:cw_monero/monero_transaction_creation_credentials.dart';
import 'package:cw_core/account.dart' as monero_account;
import 'package:cw_monero/api/wallet.dart' as monero_wallet_api;
import 'package:cw_monero/mnemonics/english.dart';
import 'package:cw_monero/mnemonics/chinese_simplified.dart';
import 'package:cw_monero/mnemonics/dutch.dart';
import 'package:cw_monero/mnemonics/german.dart';
import 'package:cw_monero/mnemonics/japanese.dart';
import 'package:cw_monero/mnemonics/russian.dart';
import 'package:cw_monero/mnemonics/spanish.dart';
import 'package:cw_monero/mnemonics/portuguese.dart';
import 'package:cw_monero/mnemonics/french.dart';
import 'package:cw_monero/mnemonics/italian.dart';
import 'package:cw_monero/pending_monero_transaction.dart';
""";
  const moneroCwPart = "part 'cw_monero.dart';";
  const moneroContent = """
class Account {
  Account({required this.id, required this.label, this.balance});
  final int id;
  final String label;
  final String? balance;
}

class Subaddress {
  Subaddress({
    required this.id,
    required this.label,
    required this.address});
  final int id;
  final String label;
  final String address;
}

class MoneroBalance extends Balance {
  MoneroBalance({required this.fullBalance, required this.unlockedBalance})
      : formattedFullBalance = monero!.formatterMoneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance =
            monero!.formatterMoneroAmountToString(amount: unlockedBalance),
        super(unlockedBalance, fullBalance);

  MoneroBalance.fromString(
      {required this.formattedFullBalance,
      required this.formattedUnlockedBalance})
      : fullBalance = monero!.formatterMoneroParseAmount(amount: formattedFullBalance),
        unlockedBalance = monero!.formatterMoneroParseAmount(amount: formattedUnlockedBalance),
        super(monero!.formatterMoneroParseAmount(amount: formattedUnlockedBalance),
            monero!.formatterMoneroParseAmount(amount: formattedFullBalance));

  final int fullBalance;
  final int unlockedBalance;
  final String formattedFullBalance;
  final String formattedUnlockedBalance;

  @override
  String get formattedAvailableBalance => formattedUnlockedBalance;

  @override
  String get formattedAdditionalBalance => formattedFullBalance;
}

abstract class MoneroWalletDetails {
  @observable
  late Account account;

  @observable
  late MoneroBalance balance;
}

abstract class Monero {
  MoneroAccountList getAccountList(Object wallet);
  
  MoneroSubaddressList getSubaddressList(Object wallet);

  TransactionHistoryBase getTransactionHistory(Object wallet);

  MoneroWalletDetails getMoneroWalletDetails(Object wallet);

  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex);

  String getSubaddressLabel(Object wallet, int accountIndex, int addressIndex);

  int getHeightByDate({required DateTime date});
  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority getMoneroTransactionPrioritySlow();
  TransactionPriority getMoneroTransactionPriorityAutomatic();
  TransactionPriority deserializeMoneroTransactionPriority({required int raw});
  List<TransactionPriority> getTransactionPriorities();
  List<String> getMoneroWordList(String language);
  
  List<Unspent> getUnspents(Object wallet);
  Future<void> updateUnspents(Object wallet);

  Future<int> getCurrentHeight();

  WalletCredentials createMoneroRestoreWalletFromKeysCredentials({
    required String name,
    required String spendKey,
    required String viewKey,
    required String address,
    required String password,
    required String language,
    required int height});
  WalletCredentials createMoneroRestoreWalletFromSeedCredentials({required String name, required String password, required int height, required String mnemonic});
  WalletCredentials createMoneroNewWalletCredentials({required String name, required String language, required bool isPolyseed, String? password});
  Map<String, String> getKeys(Object wallet);
  int? getRestoreHeight(Object wallet);
  Object createMoneroTransactionCreationCredentials({required List<Output> outputs, required TransactionPriority priority});
  Object createMoneroTransactionCreationCredentialsRaw({required List<OutputInfo> outputs, required TransactionPriority priority});
  String formatterMoneroAmountToString({required int amount});
  double formatterMoneroAmountToDouble({required int amount});
  int formatterMoneroParseAmount({required String amount});
  Account getCurrentAccount(Object wallet);
  void monerocCheck();
  void setCurrentAccount(Object wallet, int id, String label, String? balance);
  void onStartup();
  int getTransactionInfoAccountId(TransactionInfo tx);
  WalletService createMoneroWalletService(Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource);
  Map<String, String> pendingTransactionInfo(Object transaction);
}

abstract class MoneroSubaddressList {
  ObservableList<Subaddress> get subaddresses;
  void update(Object wallet, {required int accountIndex});
  void refresh(Object wallet, {required int accountIndex});
  List<Subaddress> getAll(Object wallet);
  Future<void> addSubaddress(Object wallet, {required int accountIndex, required String label});
  Future<void> setLabelSubaddress(Object wallet,
      {required int accountIndex, required int addressIndex, required String label});
}

abstract class MoneroAccountList {
  ObservableList<Account> get accounts;
  void update(Object wallet);
  void refresh(Object wallet);
  List<Account> getAll(Object wallet);
  Future<void> addAccount(Object wallet, {required String label});
  Future<void> setLabelAccount(Object wallet, {required int accountIndex, required String label});
}
  """;

  const moneroEmptyDefinition = 'Monero? monero;\n';
  const moneroCWDefinition = 'Monero? monero = CWMonero();\n';

  final output = '$moneroCommonHeaders\n' +
      (hasImplementation ? '$moneroCWHeaders\n' : '\n') +
      (hasImplementation ? '$moneroCwPart\n\n' : '\n') +
      (hasImplementation ? moneroCWDefinition : moneroEmptyDefinition) +
      '\n' +
      moneroContent;

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}

Future<void> generateWownero(bool hasImplementation) async {
  final outputFile = File(wowneroOutputPath);
  const wowneroCommonHeaders = """
import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/output_info.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';
import 'package:polyseed/polyseed.dart';""";
  const wowneroCWHeaders = """
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_core/wownero_amount_format.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_wownero/wownero_unspent.dart';
import 'package:cw_wownero/wownero_wallet_service.dart';
import 'package:cw_wownero/wownero_wallet.dart';
import 'package:cw_wownero/wownero_transaction_info.dart';
import 'package:cw_wownero/wownero_transaction_creation_credentials.dart';
import 'package:cw_core/account.dart' as wownero_account;
import 'package:cw_wownero/api/wallet.dart' as wownero_wallet_api;
import 'package:cw_wownero/api/wallet_manager.dart';
import 'package:cw_wownero/mnemonics/english.dart';
import 'package:cw_wownero/mnemonics/chinese_simplified.dart';
import 'package:cw_wownero/mnemonics/dutch.dart';
import 'package:cw_wownero/mnemonics/german.dart';
import 'package:cw_wownero/mnemonics/japanese.dart';
import 'package:cw_wownero/mnemonics/russian.dart';
import 'package:cw_wownero/mnemonics/spanish.dart';
import 'package:cw_wownero/mnemonics/portuguese.dart';
import 'package:cw_wownero/mnemonics/french.dart';
import 'package:cw_wownero/mnemonics/italian.dart';
import 'package:cw_wownero/pending_wownero_transaction.dart';
""";
  const wowneroCwPart = "part 'cw_wownero.dart';";
  const wowneroContent = """
class Account {
  Account({required this.id, required this.label, this.balance});
  final int id;
  final String label;
  final String? balance;
}

class Subaddress {
  Subaddress({
    required this.id,
    required this.label,
    required this.address});
  final int id;
  final String label;
  final String address;
}

class WowneroBalance extends Balance {
  WowneroBalance({required this.fullBalance, required this.unlockedBalance})
      : formattedFullBalance = wownero!.formatterWowneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance =
            wownero!.formatterWowneroAmountToString(amount: unlockedBalance),
        super(unlockedBalance, fullBalance);

  WowneroBalance.fromString(
      {required this.formattedFullBalance,
      required this.formattedUnlockedBalance})
      : fullBalance = wownero!.formatterWowneroParseAmount(amount: formattedFullBalance),
        unlockedBalance = wownero!.formatterWowneroParseAmount(amount: formattedUnlockedBalance),
        super(wownero!.formatterWowneroParseAmount(amount: formattedUnlockedBalance),
            wownero!.formatterWowneroParseAmount(amount: formattedFullBalance));

  final int fullBalance;
  final int unlockedBalance;
  final String formattedFullBalance;
  final String formattedUnlockedBalance;

  @override
  String get formattedAvailableBalance => formattedUnlockedBalance;

  @override
  String get formattedAdditionalBalance => formattedFullBalance;
}

abstract class WowneroWalletDetails {
  @observable
  late Account account;

  @observable
  late WowneroBalance balance;
}

abstract class Wownero {
  WowneroAccountList getAccountList(Object wallet);
  
  WowneroSubaddressList getSubaddressList(Object wallet);

  TransactionHistoryBase getTransactionHistory(Object wallet);

  WowneroWalletDetails getWowneroWalletDetails(Object wallet);

  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex);

  String getSubaddressLabel(Object wallet, int accountIndex, int addressIndex);

  int getHeightByDate({required DateTime date});
  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority getWowneroTransactionPrioritySlow();
  TransactionPriority getWowneroTransactionPriorityAutomatic();
  TransactionPriority deserializeWowneroTransactionPriority({required int raw});
  List<TransactionPriority> getTransactionPriorities();
  List<String> getWowneroWordList(String language);
  
  List<Unspent> getUnspents(Object wallet);
  Future<void> updateUnspents(Object wallet);

  Future<int> getCurrentHeight();
  void wownerocCheck();

  WalletCredentials createWowneroRestoreWalletFromKeysCredentials({
    required String name,
    required String spendKey,
    required String viewKey,
    required String address,
    required String password,
    required String language,
    required int height});
  WalletCredentials createWowneroRestoreWalletFromSeedCredentials({required String name, required String password, required int height, required String mnemonic});
  WalletCredentials createWowneroNewWalletCredentials({required String name, required String language, required bool isPolyseed, String password});
  Map<String, String> getKeys(Object wallet);
  Object createWowneroTransactionCreationCredentials({required List<Output> outputs, required TransactionPriority priority});
  Object createWowneroTransactionCreationCredentialsRaw({required List<OutputInfo> outputs, required TransactionPriority priority});
  String formatterWowneroAmountToString({required int amount});
  double formatterWowneroAmountToDouble({required int amount});
  int formatterWowneroParseAmount({required String amount});
  Account getCurrentAccount(Object wallet);
  void setCurrentAccount(Object wallet, int id, String label, String? balance);
  void onStartup();
  int getTransactionInfoAccountId(TransactionInfo tx);
  WalletService createWowneroWalletService(Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource);
  Map<String, String> pendingTransactionInfo(Object transaction);
  String getLegacySeed(Object wallet, String langName);
}

abstract class WowneroSubaddressList {
  ObservableList<Subaddress> get subaddresses;
  void update(Object wallet, {required int accountIndex});
  void refresh(Object wallet, {required int accountIndex});
  List<Subaddress> getAll(Object wallet);
  Future<void> addSubaddress(Object wallet, {required int accountIndex, required String label});
  Future<void> setLabelSubaddress(Object wallet,
      {required int accountIndex, required int addressIndex, required String label});
}

abstract class WowneroAccountList {
  ObservableList<Account> get accounts;
  void update(Object wallet);
  void refresh(Object wallet);
  List<Account> getAll(Object wallet);
  Future<void> addAccount(Object wallet, {required String label});
  Future<void> setLabelAccount(Object wallet, {required int accountIndex, required String label});
}
  """;

  const wowneroEmptyDefinition = 'Wownero? wownero;\n';
  const wowneroCWDefinition = 'Wownero? wownero = CWWownero();\n';

  final output = '$wowneroCommonHeaders\n' +
      (hasImplementation ? '$wowneroCWHeaders\n' : '\n') +
      (hasImplementation ? '$wowneroCwPart\n\n' : '\n') +
      (hasImplementation ? wowneroCWDefinition : wowneroEmptyDefinition) +
      '\n' +
      wowneroContent;

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}

Future<void> generateHaven(bool hasImplementation) async {
  final outputFile = File(havenOutputPath);
  const havenCommonHeaders = """
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/output_info.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';
import 'package:cw_core/crypto_currency.dart';""";
  const havenCWHeaders = """
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_haven/haven_wallet_service.dart';
import 'package:cw_haven/haven_wallet.dart';
import 'package:cw_haven/haven_transaction_info.dart';
import 'package:cw_haven/haven_transaction_history.dart';
import 'package:cw_core/account.dart' as monero_account;
import 'package:cw_haven/api/wallet.dart' as monero_wallet_api;
import 'package:cw_haven/mnemonics/english.dart';
import 'package:cw_haven/mnemonics/chinese_simplified.dart';
import 'package:cw_haven/mnemonics/dutch.dart';
import 'package:cw_haven/mnemonics/german.dart';
import 'package:cw_haven/mnemonics/japanese.dart';
import 'package:cw_haven/mnemonics/russian.dart';
import 'package:cw_haven/mnemonics/spanish.dart';
import 'package:cw_haven/mnemonics/portuguese.dart';
import 'package:cw_haven/mnemonics/french.dart';
import 'package:cw_haven/mnemonics/italian.dart';
import 'package:cw_haven/haven_transaction_creation_credentials.dart';
import 'package:cw_haven/api/balance_list.dart';
""";
  const havenCwPart = "part 'cw_haven.dart';";
  const havenContent = """
class Account {
  Account({required this.id, required this.label});
  final int id;
  final String label;
}

class Subaddress {
  Subaddress({
    required this.id,
    required this.label,
    required this.address});
  final int id;
  final String label;
  final String address;
}

class HavenBalance extends Balance {
  HavenBalance({required this.fullBalance, required this.unlockedBalance})
      : formattedFullBalance = haven!.formatterMoneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance =
            haven!.formatterMoneroAmountToString(amount: unlockedBalance),
        super(unlockedBalance, fullBalance);

  HavenBalance.fromString(
      {required this.formattedFullBalance,
      required this.formattedUnlockedBalance})
      : fullBalance = haven!.formatterMoneroParseAmount(amount: formattedFullBalance),
        unlockedBalance = haven!.formatterMoneroParseAmount(amount: formattedUnlockedBalance),
        super(haven!.formatterMoneroParseAmount(amount: formattedUnlockedBalance),
            haven!.formatterMoneroParseAmount(amount: formattedFullBalance));

  final int fullBalance;
  final int unlockedBalance;
  final String formattedFullBalance;
  final String formattedUnlockedBalance;

  @override
  String get formattedAvailableBalance => formattedUnlockedBalance;

  @override
  String get formattedAdditionalBalance => formattedFullBalance;
}

class AssetRate {
  AssetRate(this.asset, this.rate);

  final String asset;
  final int rate;
}

abstract class HavenWalletDetails {
  // FIX-ME: it's abstract class
  @observable
  late Account account;
  // FIX-ME: it's abstract class
  @observable
  late HavenBalance balance;
}

abstract class Haven {
  HavenAccountList getAccountList(Object wallet);
  
  MoneroSubaddressList getSubaddressList(Object wallet);

  TransactionHistoryBase getTransactionHistory(Object wallet);

  HavenWalletDetails getMoneroWalletDetails(Object wallet);

  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex);

  int getHeightByDate({required DateTime date});
  Future<int> getCurrentHeight();
  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority deserializeMoneroTransactionPriority({required int raw});
  List<TransactionPriority> getTransactionPriorities();
  List<String> getMoneroWordList(String language);

  WalletCredentials createHavenRestoreWalletFromKeysCredentials({
      required String name,
      required String spendKey,
      required String viewKey,
      required String address,
      required String password,
      required String language,
      required int height});
  WalletCredentials createHavenRestoreWalletFromSeedCredentials({required String name, required String password, required int height, required String mnemonic});
  WalletCredentials createHavenNewWalletCredentials({required String name, required String language, String? password});
  Map<String, String> getKeys(Object wallet);
  Object createHavenTransactionCreationCredentials({required List<Output> outputs, required TransactionPriority priority, required String assetType});
  String formatterMoneroAmountToString({required int amount});
  double formatterMoneroAmountToDouble({required int amount});
  int formatterMoneroParseAmount({required String amount});
  Account getCurrentAccount(Object wallet);
  void setCurrentAccount(Object wallet, int id, String label);
  void onStartup();
  int getTransactionInfoAccountId(TransactionInfo tx);
  WalletService createHavenWalletService(Box<WalletInfo> walletInfoSource);
  CryptoCurrency assetOfTransaction(TransactionInfo tx);
  List<AssetRate> getAssetRate();
}

abstract class MoneroSubaddressList {
  ObservableList<Subaddress> get subaddresses;
  void update(Object wallet, {required int accountIndex});
  void refresh(Object wallet, {required int accountIndex});
  List<Subaddress> getAll(Object wallet);
  Future<void> addSubaddress(Object wallet, {required int accountIndex, required String label});
  Future<void> setLabelSubaddress(Object wallet,
      {required int accountIndex, required int addressIndex, required String label});
}

abstract class HavenAccountList {
  ObservableList<Account> get accounts;
  void update(Object wallet);
  void refresh(Object wallet);
  List<Account> getAll(Object wallet);
  Future<void> addAccount(Object wallet, {required String label});
  Future<void> setLabelAccount(Object wallet, {required int accountIndex, required String label});
}
  """;

  const havenEmptyDefinition = 'Haven? haven;\n';
  const havenCWDefinition = 'Haven? haven = CWHaven();\n';

  final output = '$havenCommonHeaders\n' +
      (hasImplementation ? '$havenCWHeaders\n' : '\n') +
      (hasImplementation ? '$havenCwPart\n\n' : '\n') +
      (hasImplementation ? havenCWDefinition : havenEmptyDefinition) +
      '\n' +
      havenContent;

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}

Future<void> generateEthereum(bool hasImplementation) async {
  final outputFile = File(ethereumOutputPath);
  const ethereumCommonHeaders = """
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:web3dart/web3dart.dart';

""";
  const ethereumCWHeaders = """
import 'package:cw_evm/evm_chain_formatter.dart';
import 'package:cw_evm/evm_chain_mnemonics.dart';
import 'package:cw_evm/evm_chain_transaction_credentials.dart';
import 'package:cw_evm/evm_chain_transaction_info.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/evm_chain_wallet_creation_credentials.dart';
import 'package:cw_evm/evm_chain_hardware_wallet_service.dart';
import 'package:cw_evm/evm_ledger_credentials.dart';
import 'package:cw_evm/evm_chain_wallet.dart';

import 'package:cw_ethereum/ethereum_client.dart';
import 'package:cw_ethereum/ethereum_wallet.dart';
import 'package:cw_ethereum/ethereum_wallet_service.dart';

import 'package:eth_sig_util/util/utils.dart';

""";
  const ethereumCwPart = "part 'cw_ethereum.dart';";
  const ethereumContent = """
abstract class Ethereum {
  List<String> getEthereumWordList(String language);
  WalletService createEthereumWalletService(Box<WalletInfo> walletInfoSource, bool isDirect);
  WalletCredentials createEthereumNewWalletCredentials({required String name, WalletInfo? walletInfo, String? password});
  WalletCredentials createEthereumRestoreWalletFromSeedCredentials({required String name, required String mnemonic, required String password});
  WalletCredentials createEthereumRestoreWalletFromPrivateKey({required String name, required String privateKey, required String password});
  WalletCredentials createEthereumHardwareWalletCredentials({required String name, required HardwareAccountData hwAccountData, WalletInfo? walletInfo});
  String getAddress(WalletBase wallet);
  String getPrivateKey(WalletBase wallet);
  String getPublicKey(WalletBase wallet);
  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority getEthereumTransactionPrioritySlow();
  List<TransactionPriority> getTransactionPriorities();
  TransactionPriority deserializeEthereumTransactionPriority(int raw);

  Object createEthereumTransactionCredentials(
    List<Output> outputs, {
    required TransactionPriority priority,
    required CryptoCurrency currency,
    int? feeRate,
  });

  Object createEthereumTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    TransactionPriority? priority,
    required CryptoCurrency currency,
    required int feeRate,
  });

  int formatterEthereumParseAmount(String amount);
  double formatterEthereumAmountToDouble({TransactionInfo? transaction, BigInt? amount, int exponent = 18});
  List<Erc20Token> getERC20Currencies(WalletBase wallet);
  Future<void> addErc20Token(WalletBase wallet, CryptoCurrency token);
  Future<void> deleteErc20Token(WalletBase wallet, CryptoCurrency token);
  Future<void> removeTokenTransactionsInHistory(WalletBase wallet, CryptoCurrency token);
  Future<Erc20Token?> getErc20Token(WalletBase wallet, String contractAddress);
  
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction);
  void updateEtherscanUsageState(WalletBase wallet, bool isEnabled);
  Web3Client? getWeb3Client(WalletBase wallet);
  String getTokenAddress(CryptoCurrency asset);
  
  void setLedger(WalletBase wallet, Ledger ledger, LedgerDevice device);
  Future<List<HardwareAccountData>> getHardwareWalletAccounts(LedgerViewModel ledgerVM, {int index = 0, int limit = 5});
}
  """;

  const ethereumEmptyDefinition = 'Ethereum? ethereum;\n';
  const ethereumCWDefinition = 'Ethereum? ethereum = CWEthereum();\n';

  final output = '$ethereumCommonHeaders\n' +
      (hasImplementation ? '$ethereumCWHeaders\n' : '\n') +
      (hasImplementation ? '$ethereumCwPart\n\n' : '\n') +
      (hasImplementation ? ethereumCWDefinition : ethereumEmptyDefinition) +
      '\n' +
      ethereumContent;

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}

Future<void> generatePolygon(bool hasImplementation) async {
  final outputFile = File(polygonOutputPath);
  const polygonCommonHeaders = """
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:web3dart/web3dart.dart';

""";
  const polygonCWHeaders = """
import 'package:cw_evm/evm_chain_formatter.dart';
import 'package:cw_evm/evm_chain_mnemonics.dart';
import 'package:cw_evm/evm_chain_transaction_credentials.dart';
import 'package:cw_evm/evm_chain_transaction_info.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/evm_chain_wallet_creation_credentials.dart';
import 'package:cw_evm/evm_chain_hardware_wallet_service.dart';
import 'package:cw_evm/evm_ledger_credentials.dart';
import 'package:cw_evm/evm_chain_wallet.dart';

import 'package:cw_polygon/polygon_client.dart';
import 'package:cw_polygon/polygon_wallet.dart';
import 'package:cw_polygon/polygon_wallet_service.dart';

import 'package:eth_sig_util/util/utils.dart';

""";
  const polygonCwPart = "part 'cw_polygon.dart';";
  const polygonContent = """
abstract class Polygon {
  List<String> getPolygonWordList(String language);
  WalletService createPolygonWalletService(Box<WalletInfo> walletInfoSource, bool isDirect);
  WalletCredentials createPolygonNewWalletCredentials({required String name, WalletInfo? walletInfo, String? password});
  WalletCredentials createPolygonRestoreWalletFromSeedCredentials({required String name, required String mnemonic, required String password});
  WalletCredentials createPolygonRestoreWalletFromPrivateKey({required String name, required String privateKey, required String password});
  WalletCredentials createPolygonHardwareWalletCredentials({required String name, required HardwareAccountData hwAccountData, WalletInfo? walletInfo});
  String getAddress(WalletBase wallet);
  String getPrivateKey(WalletBase wallet);
  String getPublicKey(WalletBase wallet);
  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority getPolygonTransactionPrioritySlow();
  List<TransactionPriority> getTransactionPriorities();
  TransactionPriority deserializePolygonTransactionPriority(int raw);

  Object createPolygonTransactionCredentials(
    List<Output> outputs, {
    required TransactionPriority priority,
    required CryptoCurrency currency,
    int? feeRate,
  });

  Object createPolygonTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    TransactionPriority? priority,
    required CryptoCurrency currency,
    required int feeRate,
  });

  int formatterPolygonParseAmount(String amount);
  double formatterPolygonAmountToDouble({TransactionInfo? transaction, BigInt? amount, int exponent = 18});
  List<Erc20Token> getERC20Currencies(WalletBase wallet);
  Future<void> addErc20Token(WalletBase wallet, CryptoCurrency token);
  Future<void> deleteErc20Token(WalletBase wallet, CryptoCurrency token);
  Future<void> removeTokenTransactionsInHistory(WalletBase wallet, CryptoCurrency token);
  Future<Erc20Token?> getErc20Token(WalletBase wallet, String contractAddress);
  
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction);
  void updatePolygonScanUsageState(WalletBase wallet, bool isEnabled);
  Web3Client? getWeb3Client(WalletBase wallet);
  String getTokenAddress(CryptoCurrency asset);
  
  void setLedger(WalletBase wallet, Ledger ledger, LedgerDevice device);
  Future<List<HardwareAccountData>> getHardwareWalletAccounts(LedgerViewModel ledgerVM, {int index = 0, int limit = 5});
}
  """;

  const polygonEmptyDefinition = 'Polygon? polygon;\n';
  const polygonCWDefinition = 'Polygon? polygon = CWPolygon();\n';

  final output = '$polygonCommonHeaders\n' +
      (hasImplementation ? '$polygonCWHeaders\n' : '\n') +
      (hasImplementation ? '$polygonCwPart\n\n' : '\n') +
      (hasImplementation ? polygonCWDefinition : polygonEmptyDefinition) +
      '\n' +
      polygonContent;

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}

Future<void> generateBitcoinCash(bool hasImplementation) async {
  final outputFile = File(bitcoinCashOutputPath);
  const bitcoinCashCommonHeaders = """
import 'dart:typed_data';

import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';
""";
  const bitcoinCashCWHeaders = """
import 'package:cw_bitcoin_cash/cw_bitcoin_cash.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
""";
  const bitcoinCashCwPart = "part 'cw_bitcoin_cash.dart';";
  const bitcoinCashContent = """
abstract class BitcoinCash {
  String getCashAddrFormat(String address);

  WalletService createBitcoinCashWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource, bool isDirect);

  WalletCredentials createBitcoinCashNewWalletCredentials(
      {required String name, WalletInfo? walletInfo, String? password});

  WalletCredentials createBitcoinCashRestoreWalletFromSeedCredentials(
      {required String name, required String mnemonic, required String password});

  TransactionPriority deserializeBitcoinCashTransactionPriority(int raw);

  TransactionPriority getDefaultTransactionPriority();

  List<TransactionPriority> getTransactionPriorities();
  
  TransactionPriority getBitcoinCashTransactionPrioritySlow();
}
  """;

  const bitcoinCashEmptyDefinition = 'BitcoinCash? bitcoinCash;\n';
  const bitcoinCashCWDefinition = 'BitcoinCash? bitcoinCash = CWBitcoinCash();\n';

  final output = '$bitcoinCashCommonHeaders\n' +
      (hasImplementation ? '$bitcoinCashCWHeaders\n' : '\n') +
      (hasImplementation ? '$bitcoinCashCwPart\n\n' : '\n') +
      (hasImplementation ? bitcoinCashCWDefinition : bitcoinCashEmptyDefinition) +
      '\n' +
      bitcoinCashContent;

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}

Future<void> generateNano(bool hasImplementation) async {
  final outputFile = File(nanoOutputPath);
  const nanoCommonHeaders = """
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/nano_account.dart';
import 'package:cw_core/account.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/nano_account_info_response.dart';
import 'package:cw_core/n2_node.dart';
import 'package:mobx/mobx.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/view_model/send/output.dart';
""";
  const nanoCWHeaders = """
import 'package:cw_nano/nano_client.dart';
import 'package:cw_nano/nano_mnemonic.dart';
import 'package:cw_nano/nano_wallet.dart';
import 'package:cw_nano/nano_wallet_service.dart';
import 'package:cw_nano/nano_transaction_info.dart';
import 'package:cw_nano/nano_transaction_credentials.dart';
import 'package:cw_nano/nano_wallet_creation_credentials.dart';
// needed for nano_util:
import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import "package:ed25519_hd_key/ed25519_hd_key.dart";
import 'package:libcrypto/libcrypto.dart';
import 'package:nanodart/nanodart.dart' as ND;
import 'package:nanoutil/nanoutil.dart';
""";
  const nanoCwPart = "part 'cw_nano.dart';";
  const nanoContent = """
abstract class Nano {
  NanoAccountList getAccountList(Object wallet);

  Account getCurrentAccount(Object wallet);

  void setCurrentAccount(Object wallet, int id, String label, String? balance);

  WalletService createNanoWalletService(Box<WalletInfo> walletInfoSource, bool isDirect);

  WalletCredentials createNanoNewWalletCredentials({
    required String name,
    String? password,
  });
  
  WalletCredentials createNanoRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required String mnemonic,
    required DerivationType derivationType,
  });

  WalletCredentials createNanoRestoreWalletFromKeysCredentials({
    required String name,
    required String password,
    required String seedKey,
    required DerivationType derivationType,
  });

  List<String> getNanoWordList(String language);
  Map<String, String> getKeys(Object wallet);
  Object createNanoTransactionCredentials(List<Output> outputs);
  Future<void> changeRep(Object wallet, String address);
  Future<bool> updateTransactions(Object wallet);
  BigInt getTransactionAmountRaw(TransactionInfo transactionInfo);
  String getRepresentative(Object wallet);
  Future<List<N2Node>> getN2Reps(Object wallet);
  bool isRepOk(Object wallet);
}

abstract class NanoAccountList {
  ObservableList<NanoAccount> get accounts;
  void update(Object wallet);
  void refresh(Object wallet);
  Future<List<NanoAccount>> getAll(Object wallet);
  Future<void> addAccount(Object wallet, {required String label});
  Future<void> setLabelAccount(Object wallet, {required int accountIndex, required String label});
}

abstract class NanoUtil {
  bool isValidBip39Seed(String seed);
  static const int maxDecimalDigits = 6; // Max digits after decimal
  BigInt rawPerNano = BigInt.parse("1000000000000000000000000000000");
  BigInt rawPerNyano = BigInt.parse("1000000000000000000000000");
  BigInt rawPerBanano = BigInt.parse("100000000000000000000000000000");
  BigInt rawPerXMR = BigInt.parse("1000000000000");
  BigInt convertXMRtoNano = BigInt.parse("1000000000000000000");
  String getRawAsUsableString(String? raw, BigInt rawPerCur);
  String getRawAccuracy(String? raw, BigInt rawPerCur);
  String getAmountAsRaw(String amount, BigInt rawPerCur);

  // derivationInfo:
  Future<AccountInfoResponse?> getInfoFromSeedOrMnemonic(
    DerivationType derivationType, {
    String? seedKey,
    String? mnemonic,
    required Node node,
  });
  Future<List<DerivationType>> compareDerivationMethods({
    String? mnemonic,
    String? privateKey,
    required Node node,
  });
  Future<List<DerivationInfo>> getDerivationsFromMnemonic({
    String? mnemonic,
    String? seedKey,
    required Node node,
  });
}
  """;

  const nanoEmptyDefinition = 'Nano? nano;\nNanoUtil? nanoUtil;\n';
  const nanoCWDefinition = 'Nano? nano = CWNano();\nNanoUtil? nanoUtil = CWNanoUtil();\n';

  final output = '$nanoCommonHeaders\n' +
      (hasImplementation ? '$nanoCWHeaders\n' : '\n') +
      (hasImplementation ? '$nanoCwPart\n\n' : '\n') +
      (hasImplementation ? nanoCWDefinition : nanoEmptyDefinition) +
      '\n' +
      nanoContent;

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}

Future<void> generateSolana(bool hasImplementation) async {
  final outputFile = File(solanaOutputPath);
  const solanaCommonHeaders = """
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';
import 'package:solana/solana.dart';

""";
  const solanaCWHeaders = """
import 'package:cw_solana/spl_token.dart';
import 'package:cw_solana/solana_wallet.dart';
import 'package:cw_solana/solana_mnemonics.dart';
import 'package:cw_solana/solana_wallet_service.dart';
import 'package:cw_solana/solana_transaction_info.dart';
import 'package:cw_solana/solana_transaction_credentials.dart';
import 'package:cw_solana/solana_wallet_creation_credentials.dart';
""";
  const solanaCwPart = "part 'cw_solana.dart';";
  const solanaContent = """
abstract class Solana {
  List<String> getSolanaWordList(String language);
  WalletService createSolanaWalletService(Box<WalletInfo> walletInfoSource, bool isDirect);
  WalletCredentials createSolanaNewWalletCredentials(
      {required String name, WalletInfo? walletInfo, String? password});
  WalletCredentials createSolanaRestoreWalletFromSeedCredentials(
      {required String name, required String mnemonic, required String password});
  WalletCredentials createSolanaRestoreWalletFromPrivateKey(
      {required String name, required String privateKey, required String password});

  String getAddress(WalletBase wallet);
  String getPrivateKey(WalletBase wallet);
  String getPublicKey(WalletBase wallet);
  Ed25519HDKeyPair? getWalletKeyPair(WalletBase wallet);

  Object createSolanaTransactionCredentials(
    List<Output> outputs, {
    required CryptoCurrency currency,
  });

  Object createSolanaTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    required CryptoCurrency currency,
  });
  List<CryptoCurrency> getSPLTokenCurrencies(WalletBase wallet);
  Future<void> addSPLToken(
    WalletBase wallet,
    CryptoCurrency token,
    String contractAddress,
  );
  Future<void> deleteSPLToken(WalletBase wallet, CryptoCurrency token);
  Future<CryptoCurrency?> getSPLToken(WalletBase wallet, String contractAddress);

  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction);
  double getTransactionAmountRaw(TransactionInfo transactionInfo);
  String getTokenAddress(CryptoCurrency asset);
  List<int>? getValidationLength(CryptoCurrency type);
  double? getEstimateFees(WalletBase wallet);
}

  """;

  const solanaEmptyDefinition = 'Solana? solana;\n';
  const solanaCWDefinition = 'Solana? solana = CWSolana();\n';

  final output = '$solanaCommonHeaders\n' +
      (hasImplementation ? '$solanaCWHeaders\n' : '\n') +
      (hasImplementation ? '$solanaCwPart\n\n' : '\n') +
      (hasImplementation ? solanaCWDefinition : solanaEmptyDefinition) +
      '\n' +
      solanaContent;

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}

Future<void> generateTron(bool hasImplementation) async {
  final outputFile = File(tronOutputPath);
  const tronCommonHeaders = """
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';

""";
  const tronCWHeaders = """
import 'package:cw_evm/evm_chain_mnemonics.dart';
import 'package:cw_tron/tron_transaction_credentials.dart';
import 'package:cw_tron/tron_transaction_info.dart';
import 'package:cw_tron/tron_wallet_creation_credentials.dart';

import 'package:cw_tron/tron_client.dart';
import 'package:cw_tron/tron_token.dart';
import 'package:cw_tron/tron_wallet.dart';
import 'package:cw_tron/tron_wallet_service.dart';

""";
  const tronCwPart = "part 'cw_tron.dart';";
  const tronContent = """
abstract class Tron {
  List<String> getTronWordList(String language);
  WalletService createTronWalletService(Box<WalletInfo> walletInfoSource, bool isDirect);
  WalletCredentials createTronNewWalletCredentials({required String name, WalletInfo? walletInfo, String? password});
  WalletCredentials createTronRestoreWalletFromSeedCredentials({required String name, required String mnemonic, required String password});
  WalletCredentials createTronRestoreWalletFromPrivateKey({required String name, required String privateKey, required String password});
  String getAddress(WalletBase wallet);

  Object createTronTransactionCredentials(
    List<Output> outputs, {
    required CryptoCurrency currency,
  });

  List<CryptoCurrency> getTronTokenCurrencies(WalletBase wallet);
  Future<void> addTronToken(WalletBase wallet, CryptoCurrency token, String contractAddress);
  Future<void> deleteTronToken(WalletBase wallet, CryptoCurrency token);
  Future<CryptoCurrency?> getTronToken(WalletBase wallet, String contractAddress);
  
  double getTransactionAmountRaw(TransactionInfo transactionInfo);
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction);
  String getTokenAddress(CryptoCurrency asset);
  String getTronBase58Address(String hexAddress, WalletBase wallet);

  String? getTronNativeEstimatedFee(WalletBase wallet);
  String? getTronTRC20EstimatedFee(WalletBase wallet);
  
  void updateTronGridUsageState(WalletBase wallet, bool isEnabled);
}
  """;

  const tronEmptyDefinition = 'Tron? tron;\n';
  const tronCWDefinition = 'Tron? tron = CWTron();\n';

  final output = '$tronCommonHeaders\n' +
      (hasImplementation ? '$tronCWHeaders\n' : '\n') +
      (hasImplementation ? '$tronCwPart\n\n' : '\n') +
      (hasImplementation ? tronCWDefinition : tronEmptyDefinition) +
      '\n' +
      tronContent;

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(output);
}

Future<void> generatePubspec({
  required bool hasMonero,
  required bool hasBitcoin,
  required bool hasHaven,
  required bool hasEthereum,
  required bool hasNano,
  required bool hasBanano,
  required bool hasBitcoinCash,
  required bool hasFlutterSecureStorage,
  required bool hasPolygon,
  required bool hasSolana,
  required bool hasTron,
  required bool hasWownero,
}) async {
  const cwCore = """
  cw_core:
    path: ./cw_core
    """;
  const cwMonero = """
  cw_monero:
    path: ./cw_monero
  """;
  const cwBitcoin = """
  cw_bitcoin:
    path: ./cw_bitcoin
  """;
  const cwHaven = """
  cw_haven:
    path: ./cw_haven
  """;
  const cwSharedExternal = """
  cw_shared_external:
    path: ./cw_shared_external
  """;
  const flutterSecureStorage = """
  flutter_secure_storage:
    git:
      url: https://github.com/cake-tech/flutter_secure_storage.git
      path: flutter_secure_storage
      ref: cake-8.1.0
      version: 8.1.0
  """;
  const cwEthereum = """
  cw_ethereum:
    path: ./cw_ethereum
  """;
  const cwBitcoinCash = """
  cw_bitcoin_cash:
    path: ./cw_bitcoin_cash
  """;
  const cwNano = """
  cw_nano:
    path: ./cw_nano
  """;
  const cwBanano = """
  cw_banano:
    path: ./cw_banano
  """;
  const cwPolygon = """
  cw_polygon:
    path: ./cw_polygon
  """;
  const cwSolana = """
  cw_solana:
    path: ./cw_solana
  """;
  const cwEVM = """
  cw_evm:
    path: ./cw_evm
    """;
  const cwTron = """
  cw_tron:
    path: ./cw_tron
    """;
  const cwWownero = """
  cw_wownero:
    path: ./cw_wownero
    """;
  final inputFile = File(pubspecOutputPath);
  final inputText = await inputFile.readAsString();
  final inputLines = inputText.split('\n');
  final dependenciesIndex = inputLines.indexWhere((line) => Platform.isWindows
      // On Windows it could contains `\r` (Carriage Return). It could be fixed in newer dart versions.
      ? line.toLowerCase() == 'dependencies:\r' || line.toLowerCase() == 'dependencies:'
      : line.toLowerCase() == 'dependencies:');
  var output = cwCore;

  if (hasMonero) {
    output += '\n$cwMonero';
  }

  if (hasBitcoin) {
    output += '\n$cwBitcoin';
  }

  if (hasEthereum) {
    output += '\n$cwEthereum';
  }

  if (hasNano) {
    output += '\n$cwNano';
  }

  if (hasBanano) {
    output += '\n$cwBanano';
  }

  if (hasBitcoinCash) {
    output += '\n$cwBitcoinCash';
  }

  if (hasPolygon) {
    output += '\n$cwPolygon';
  }

  if (hasSolana) {
    output += '\n$cwSolana';
  }

  if (hasTron) {
    output += '\n$cwTron';
  }

  if (hasHaven) {
    output += '\n$cwSharedExternal\n$cwHaven';
  }

  if (hasFlutterSecureStorage) {
    output += '\n$flutterSecureStorage\n';
  }

  if (hasEthereum || hasPolygon) {
    output += '\n$cwEVM';
  }

  if (hasWownero) {
    output += '\n$cwWownero';
  }

  final outputLines = output.split('\n');
  inputLines.insertAll(dependenciesIndex + 1, outputLines);
  final outputContent = inputLines.join('\n');
  final outputFile = File(pubspecOutputPath);

  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  await outputFile.writeAsString(outputContent);
}

Future<void> generateWalletTypes({
  required bool hasMonero,
  required bool hasBitcoin,
  required bool hasHaven,
  required bool hasEthereum,
  required bool hasNano,
  required bool hasBanano,
  required bool hasBitcoinCash,
  required bool hasPolygon,
  required bool hasSolana,
  required bool hasTron,
  required bool hasWownero,
}) async {
  final walletTypesFile = File(walletTypesPath);

  if (walletTypesFile.existsSync()) {
    await walletTypesFile.delete();
  }

  const outputHeader = "import 'package:cw_core/wallet_type.dart';";
  const outputDefinition = 'final availableWalletTypes = <WalletType>[';
  var outputContent = outputHeader + '\n\n' + outputDefinition + '\n';

  if (hasMonero) {
    outputContent += '\tWalletType.monero,\n';
  }

  if (hasBitcoin) {
    outputContent += '\tWalletType.bitcoin,\n';
  }

  if (hasEthereum) {
    outputContent += '\tWalletType.ethereum,\n';
  }

  if (hasBitcoin) {
    outputContent += '\tWalletType.litecoin,\n';
  }

  if (hasBitcoinCash) {
    outputContent += '\tWalletType.bitcoinCash,\n';
  }

  if (hasPolygon) {
    outputContent += '\tWalletType.polygon,\n';
  }

  if (hasSolana) {
    outputContent += '\tWalletType.solana,\n';
  }

  if (hasTron) {
    outputContent += '\tWalletType.tron,\n';
  }

  if (hasNano) {
    outputContent += '\tWalletType.nano,\n';
  }

  if (hasBanano) {
    outputContent += '\tWalletType.banano,\n';
  }

  if (hasWownero) {
    outputContent += '\tWalletType.wownero,\n';
  }

  if (hasHaven) {
    outputContent += '\tWalletType.haven,\n';
  }

  outputContent += '];\n';
  await walletTypesFile.writeAsString(outputContent);
}

Future<void> injectSecureStorage(bool hasFlutterSecureStorage) async {
  const flutterSecureStorageHeader = """
import 'dart:async';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
""";
  const abstractSecureStorage = """
abstract class SecureStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String? value});
  Future<void> delete({required String key});
  // Legacy
  Future<String?> readNoIOptions({required String key});
 }""";
  const defaultSecureStorage = """
class DefaultSecureStorage extends SecureStorage {
  DefaultSecureStorage._(this._secureStorage);

  factory DefaultSecureStorage() => _instance;

  static final _instance = DefaultSecureStorage._(FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  ));
   
  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> read({required String key}) async => await _readInternal(key, false);

  @override
  Future<void> write({required String key, required String? value}) async {
    // delete the value before writing on macOS because of a weird bug
    // https://github.com/mogol/flutter_secure_storage/issues/581
    if (Platform.isMacOS) {
      await _secureStorage.delete(key: key);
    }
    await _secureStorage.write(key: key, value: value);
  }

  @override
  Future<void> delete({required String key}) async => _secureStorage.delete(key: key);

  @override
  Future<String?> readNoIOptions({required String key}) async => await _readInternal(key, true);

  Future<String?> _readInternal(String key, bool useNoIOptions) async {
    return await _secureStorage.read(
      key: key,
      iOptions: useNoIOptions ? IOSOptions() : null,
    );
  }
 }""";
  const fakeSecureStorage = """
class FakeSecureStorage extends SecureStorage {
  @override
  Future<String?> read({required String key}) async => null;
  @override
  Future<void> write({required String key, required String? value}) async {}
  @override
  Future<void> delete({required String key}) async {}
  @override
  Future<String?> readNoIOptions({required String key}) async => null;
 }""";
  final outputFile = File(secureStoragePath);
  final header = hasFlutterSecureStorage
      ? '${flutterSecureStorageHeader}\n\nfinal SecureStorage secureStorageShared = DefaultSecureStorage();\n'
      : 'final SecureStorage secureStorageShared = FakeSecureStorage();\n';
  var output = '';
  if (outputFile.existsSync()) {
    await outputFile.delete();
  }

  output += '${header}\n${abstractSecureStorage}\n\n';

  if (hasFlutterSecureStorage) {
    output += '${defaultSecureStorage}\n';
  } else {
    output += '${fakeSecureStorage}\n';
  }

  await outputFile.writeAsString(output);
}
