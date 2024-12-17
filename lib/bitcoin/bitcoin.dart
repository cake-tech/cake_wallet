import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:hive/hive.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart' as ledger;
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:bip39/bip39.dart' as bip39;

import 'package:cw_bitcoin/utils.dart';
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/bitcoin_receive_page_option.dart';
import 'package:cw_bitcoin/bitcoin_payjoin.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_wallet_service.dart';
import 'package:cw_bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/litecoin_wallet.dart';
import 'package:cw_bitcoin/litecoin_wallet_service.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_bitcoin/bitcoin_hardware_wallet_service.dart';
import 'package:cw_bitcoin/litecoin_hardware_wallet_service.dart';
import 'package:mobx/mobx.dart';

part 'cw_bitcoin.dart';

Bitcoin? bitcoin = CWBitcoin();

class ElectrumSubAddress {
  ElectrumSubAddress(
      {required this.id,
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
  WalletCredentials createBitcoinRestoreWalletFromWIFCredentials(
      {required String name,
      required String password,
      required String wif,
      WalletInfo? walletInfo});
  WalletCredentials createBitcoinNewWalletCredentials(
      {required String name,
      WalletInfo? walletInfo,
      String? password,
      String? passphrase,
      String? mnemonic,
      String? parentAddress});
  WalletCredentials createBitcoinHardwareWalletCredentials(
      {required String name,
      required HardwareAccountData accountData,
      WalletInfo? walletInfo});
  List<String> getWordList();
  Map<String, String> getWalletKeys(Object wallet);
  List<TransactionPriority> getTransactionPriorities();
  List<TransactionPriority> getLitecoinTransactionPriorities();
  TransactionPriority deserializeBitcoinTransactionPriority(int raw);
  TransactionPriority deserializeLitecoinTransactionPriority(int raw);
  int getFeeRate(Object wallet, TransactionPriority priority);
  Future<void> generateNewAddress(Object wallet, String label);
  Future<void> updateAddress(Object wallet, String address, String label);
  Object createBitcoinTransactionCredentials(List<Output> outputs,
      {required TransactionPriority priority,
      int? feeRate,
      UnspentCoinType coinTypeToSpendFrom = UnspentCoinType.any});

  String getAddress(Object wallet);
  List<ElectrumSubAddress> getSilentPaymentAddresses(Object wallet);
  List<ElectrumSubAddress> getSilentPaymentReceivedAddresses(Object wallet);

  Future<int> estimateFakeSendAllTxAmount(
      Object wallet, TransactionPriority priority);
  List<ElectrumSubAddress> getSubAddresses(Object wallet);

  String formatterBitcoinAmountToString({required int amount});
  double formatterBitcoinAmountToDouble({required int amount});
  int formatterStringDoubleToBitcoinAmount(String amount);
  String bitcoinTransactionPriorityWithLabel(
      TransactionPriority priority, int rate,
      {int? customRate});

  List<Unspent> getUnspents(Object wallet,
      {UnspentCoinType coinTypeToSpendFrom = UnspentCoinType.any});
  Future<void> updateUnspents(Object wallet);
  WalletService createBitcoinWalletService(Box<WalletInfo> walletInfoSource,
      Box<UnspentCoinsInfo> unspentCoinSource, bool alwaysScan, bool isDirect);
  WalletService createLitecoinWalletService(Box<WalletInfo> walletInfoSource,
      Box<UnspentCoinsInfo> unspentCoinSource, bool alwaysScan, bool isDirect);
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
  List<ReceivePageOption> getLitecoinReceivePageOptions();
  BitcoinAddressType getBitcoinAddressType(ReceivePageOption option);
  bool hasSelectedSilentPayments(Object wallet);
  bool isBitcoinReceivePageOption(ReceivePageOption option);
  BitcoinAddressType getOptionToType(ReceivePageOption option);
  bool hasTaprootInput(PendingTransaction pendingTransaction);
  bool getScanningActive(Object wallet);
  Future<void> setScanningActive(Object wallet, bool active);
  bool isTestnet(Object wallet);

  Future<PendingTransaction> replaceByFee(
      Object wallet, String transactionHash, String fee);
  Future<String?> canReplaceByFee(Object wallet, Object tx);
  int getTransactionVSize(Object wallet, String txHex);
  Future<bool> isChangeSufficientForFee(
      Object wallet, String txId, String newFee);
  int getFeeAmountForPriority(Object wallet, TransactionPriority priority,
      int inputsCount, int outputsCount,
      {int? size});
  int getEstimatedFeeWithFeeRate(Object wallet, int feeRate, int? amount,
      {int? outputsCount, int? size});
  int feeAmountWithFeeRate(
      Object wallet, int feeRate, int inputsCount, int outputsCount,
      {int? size});
  Future<bool> checkIfMempoolAPIIsEnabled(Object wallet);
  Future<int> getHeightByDate(
      {required DateTime date, bool? bitcoinMempoolAPIEnabled});
  int getLitecoinHeightByDate({required DateTime date});
  Future<void> rescan(Object wallet, {required int height, bool? doSingleScan});
  Future<bool> getNodeIsElectrsSPEnabled(Object wallet);
  void deleteSilentPaymentAddress(Object wallet, String address);
  Future<void> updateFeeRates(Object wallet);
  int getMaxCustomFeeRate(Object wallet);
  void setLedgerConnection(
      WalletBase wallet, ledger.LedgerConnection connection);
  Future<List<HardwareAccountData>> getHardwareWalletBitcoinAccounts(
      LedgerViewModel ledgerVM,
      {int index = 0,
      int limit = 5});
  Future<List<HardwareAccountData>> getHardwareWalletLitecoinAccounts(
      LedgerViewModel ledgerVM,
      {int index = 0,
      int limit = 5});
  List<Output> updateOutputs(
      PendingTransaction pendingTransaction, List<Output> outputs);
  bool txIsReceivedSilentPayment(TransactionInfo txInfo);
  bool txIsMweb(TransactionInfo txInfo);
  Future<void> setMwebEnabled(Object wallet, bool enabled);
  bool getMwebEnabled(Object wallet);
  String? getUnusedMwebAddress(Object wallet);
  String? getUnusedSegwitAddress(Object wallet);

  Future<Map<String, dynamic>> buildV2PjStr({
    int? amount,
    required String address,
    required bool isTestnet,
    required BigInt expireAfter,
  });

  Future<UncheckedProposal> handleReceiverSession(Receiver session);

  Future<String> extractOriginalTransaction(UncheckedProposal proposal);

  Future<PayjoinProposal> processProposal({
    required UncheckedProposal proposal,
    required Object receiverWallet,
  });

  Future<String> sendFinalProposal(PayjoinProposal finalProposal);

  Future<String> getTxIdFromPsbt(String psbtBase64);

  Future<Uri?> stringToPjUri(String pj);
  Future<String> buildOriginalPsbt(
    Object wallet,
    dynamic pjUri,
    int fee,
    double amount,
    Object credentials,
  );

  Future<Sender> buildPayjoinRequest(
    String originalPsbt,
    dynamic pjUri,
    int fee,
  );

  Future<String> requestAndPollV2Proposal(
    Sender sender,
  );

  Future<PendingBitcoinTransaction> extractPjTx(
    Object wallet,
    String psbtString,
    Object credentials,
  );
}
