import 'dart:convert';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain/solana/solana.dart' show SolanaTransaction;
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/zcash/zcash.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/provider/pegaroute_exchange_provider.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/evm_call_data_transaction_credentials.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/solana_serialized_transaction_credentials.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/wallet_base.dart';
import 'pegaroute_approval.dart';
import 'pegaroute_capability_gate.dart';
import 'pegaroute_native_eth.dart';
import 'pegaroute_solana_wire.dart';
import 'pegaroute_trade_record.dart';
import 'pegaroute_trade_store.dart';

/// Provider-specific use of Cake preparation/confirmation/commit primitives.
/// No broadcasting in preparation and no ordinary-transfer fallback.
Future<PegaroutePendingDeposit> preparePegarouteDeposit({required Trade trade,
    required WalletBase wallet, required TransactionPriority? priority,
    required PegaRouteExchangeProvider provider, required void Function() checkContext}) async {
  final captured = await provider.store.latest(trade);
  final record = PegarouteTradeRecord.read(captured);
  void validate() {
    checkContext();
    PegarouteTradeStore.same(captured, trade);
    if (wallet.id != captured.walletId || wallet.walletAddresses.address != captured.fromWalletAddress ||
        wallet.chainId != captured.chainId || !PegaRouteExchangeProvider.supportsWallet(wallet, captured.from!)) {
      throw StateError('Pegaroute wallet binding changed');
    }
  }
  validate();
  PegarouteTradeStore.eligible(captured);
  final approval = await preparePegarouteApproval(wallet: wallet, trade: captured,
      store: provider.store, priority: priority, checkContext: validate);
  validate();
  final current = await provider.store.latest(captured);
  validate();
  PegarouteTradeStore.eligible(current);
  final wire = record.execution;
  final amount = Money(record.sourceUnits(captured.amount), captured.from!);
  final native = PegarouteTradeRecord.currency(record.source);
  PendingTransaction pending;
  String? expectedTarget;
  String? expectedData;
  BigInt? expectedValue;
  int? suppliedGas;
  if (approval != null) {
    pending = approval.pending;
    expectedTarget = approval.to;
    expectedData = approval.data;
    expectedValue = BigInt.zero;
    suppliedGas = 65000;
  } else if (wire.family == 'evm') {
    if (evm == null || amount.amount.bitLength > 256) throw StateError('Unsupported EVM operation');
    await requirePegarouteAllowance(wallet, record, validate);
    final rawGas = wire.gasLimit;
    suppliedGas = rawGas == null ? null : int.tryParse(rawGas);
    if (rawGas != null && (suppliedGas == null || suppliedGas < 21000)) {
      throw StateError('Invalid supplied EVM gas limit');
    }
    expectedTarget = wire.to!;
    expectedData = wire.data;
    expectedValue = amount.amount;
    if (wire.mode == 'native-transfer' && suppliedGas == null) {
      pending = await wallet.createTransaction(evm!.createEVMTransactionCredentialsRaw([
        OutputInfo(address: wire.to!, cryptoAmount: amount, sendAll: false, isParsedAddress: false),
      ], currency: native, priority: priority, feeRate: 0, useBlinkProtection: false));
    } else {
      String? token;
      BigInt? tokenAmount;
      if (record.sourceAsset.token != record.sourceAsset.nativeToken) {
        token = record.sourceAsset.token.split('-').last;
        tokenAmount = amount.amount;
        expectedValue = BigInt.zero;
        if (wire.mode == 'erc20-transfer') {
          expectedData = '0xa9059cbb${wire.to!.substring(2).toLowerCase().padLeft(64, '0')}'
              '${amount.amount.toRadixString(16).padLeft(64, '0')}';
          expectedTarget = token;
        }
      }
      // A small floor still requires real fee estimation and a fresh balance.
      pending = await wallet.createTransaction(EvmCallDataTransactionCredentials(
          to: expectedTarget, data: expectedData ?? '0x', value: Money(expectedValue, native),
          priority: priority, gasLimit: suppliedGas ?? 21000,
          sourceTokenAddress: token, sourceTokenAmount: tokenAmount, useBlinkProtection: false));
    }
  } else if (wire.mode == 'serialized-tx') {
    pending = await wallet.createTransaction(SolanaSerializedTransactionCredentials(
        transactionBase58: Base58Encoder.encode(decodePegarouteSolanaTransaction(
            wire.serializedTransaction!, wire.encoding!)),
        amount: amount, destinationAddress: captured.payoutAddress!));
  } else {
    var memo = wire.memo;
    if (PegarouteCapabilityGate.utxo.contains(record.source) && memo != null) {
      // The Bitcoin builder detects hex: encode even text such as "1234".
      memo = BytesUtils.toHexString(utf8.encode(memo));
    }
    final output = OutputInfo(address: wire.to!, cryptoAmount: amount,
        sendAll: false, isParsedAddress: false, memo: memo);
    final outputs = List<OutputInfo>.unmodifiable([output]);
    final Object credentials;
    if (PegarouteCapabilityGate.utxo.contains(record.source)) {
      credentials = bitcoin!.createBitcoinTransactionCredentials([_BoundDepositOutput(output)],
          priority: priority ?? bitcoin!.getMediumTransactionPriority(),
          coinTypeToSpendFrom: UnspentCoinType.nonMweb, payjoinUri: null);
    } else if (record.source == 'XMR') {
      credentials = monero!.createMoneroTransactionCreationCredentialsRaw(outputs: outputs,
          priority: priority ?? monero!.getDefaultTransactionPriority());
    } else if (record.source == 'SOL') {
      credentials = solana!.createSolanaTransactionCredentialsRaw(outputs, currency: captured.from!);
    } else if (record.source == 'TRON') {
      credentials = tron!.createTronTransactionCredentials([_BoundDepositOutput(output)], currency: native);
    } else {
      // ZEC's exact-balance path deducts fees from the recipient even without send-all.
      final available = wallet.balance[CryptoCurrency.zec]?.available;
      if (available == null || amount.amount >= available.amount) {
        throw StateError('ZEC deposit needs additional balance for fees');
      }
      credentials = zcash!.createZcashTransactionCredentialsRaw(outputs, currency: native, feeRate: 0);
    }
    pending = await wallet.createTransaction(credentials);
  }
  validate();
  PegarouteTradeStore.eligible(await provider.store.latest(current));
  validate();
  if (pending.shouldCommitUR()) throw StateError('External signing is not supported');
  if (wire.family == 'evm') {
    final evidence = inspectPegarouteEvm(pending.hex,
        chainId: captured.chainId!, sender: captured.fromWalletAddress!);
    if (evidence.to.toLowerCase() != expectedTarget!.toLowerCase() ||
        evidence.valueBaseUnits != expectedValue.toString() ||
        (evidence.data ?? '0x').toLowerCase() != (expectedData ?? '0x').toLowerCase() ||
        (suppliedGas != null && BigInt.parse(evidence.gasLimit) < BigInt.from(suppliedGas))) {
      throw StateError('Signed EVM transaction differs from bound instructions');
    }
  } else if (pending.amount.amount != amount.amount) {
    throw StateError('Prepared deposit amount changed');
  }
  return PegaroutePendingDeposit._(current, provider, pending,
      approval == null ? amount : pending.amount, validate,
      approvalStep: approval?.step, approvalDescription: approval?.description,
      approvalTarget: approval?.to);
}

String? _identity(PendingTransaction pending, Trade trade, PegarouteTradeRecord record) {
  if (record.execution.family == 'evm') {
    return inspectPegarouteEvm(pending.hex, chainId: trade.chainId!,
        sender: trade.fromWalletAddress!).transactionHash;
  }
  if (record.source == 'SOL') {
    final transaction = SolanaTransaction.deserialize(Base58Decoder.decode(pending.hex));
    final signature = transaction.signatures.first;
    if (signature.length != 64 || signature.every((byte) => byte == 0)) {
      throw StateError('Unsigned Solana transaction');
    }
    return Base58Encoder.encode(signature);
  }
  if (record.source == 'ZEC' && pending.id.isEmpty) return null;
  PegaRouteExchangeProvider.validateHash(pending.id, record.source);
  return pending.id;
}

class PegaroutePendingDeposit with PendingTransaction {
  PegaroutePendingDeposit._(this._trade, this._provider, this._pending, this.amount, this._validate,
      {this.approvalStep, this.approvalDescription, this.approvalTarget})
      : hex = _pending.hex, _innerAmount = _pending.amount, _innerFee = _pending.fee {
    _id = _identity(_pending, _trade, PegarouteTradeRecord.read(_trade));
    if (hex.isEmpty && PegarouteTradeRecord.read(_trade).source != 'ZEC') {
      throw StateError('Missing prepared transaction bytes');
    }
  }
  final Trade _trade;
  final PegaRouteExchangeProvider _provider;
  final PendingTransaction _pending;
  final void Function() _validate;
  final Money _innerAmount;
  final Money _innerFee;
  final String? approvalStep;
  final String? approvalDescription;
  final String? approvalTarget;
  bool get isApproval => approvalStep != null;
  bool get started => _started;
  bool _started = false;
  String? _id;
  Object? bookkeepingError;
  CryptoCurrency get sourceCurrency => _trade.from!;
  String? get sourceTokenAddress {
    final asset = PegarouteTradeRecord.read(_trade).sourceAsset;
    return asset.token == asset.nativeToken ? null : asset.token.split('-').last;
  }
  @override
  String get id => _id ?? '';
  @override
  final String hex;
  @override
  final Money amount;
  @override
  Money get fee => _innerFee;
  @override
  Money? get additionalCost => _pending.additionalCost;
  @override
  PendingChange? get change => _pending.change;
  @override
  set change(PendingChange? value) => _pending.change = value;
  @override
  String? get feeRate => _pending.feeRate;
  @override
  set feeRate(String? value) => _pending.feeRate = value;
  @override
  String get feeFormatted => _pending.feeFormatted;
  @override
  String get feeFormattedValue => _pending.feeFormattedValue;
  @override
  int? get outputCount => _pending.outputCount;
  @override
  String get amountFormatted => amount.toString();
  @override
  String? get evmTxHashFromRawHex =>
      PegarouteTradeRecord.read(_trade).execution.family == 'evm' ? _id : null;

  void _checkPrepared() {
    _validate();
    if (_pending.hex != hex || _pending.amount != _innerAmount || _pending.fee != _innerFee ||
        _identity(_pending, _trade, PegarouteTradeRecord.read(_trade)) != _id || _pending.shouldCommitUR()) {
      throw StateError('Prepared transaction identity changed');
    }
  }

  @override
  Future<void> commit() async {
    if (_started) throw StateError('Transaction commit already attempted');
    _checkPrepared();
    _started = true;
    final attempt = PegarouteTradeRecord.nonce();
    final claimed = isApproval
        ? await _provider.store.claimApproval(_trade, approvalStep!, attempt, id)
        : await _provider.store.claim(_trade, attempt, hash: _id);
    _checkPrepared();
    // Unknown submission consumes this claim, even if the native wallet returns no hash.
    try { await _pending.commit(); }
    catch (_) {
      // ZEC may return its network ID, then fail its history/balance refresh.
      final knownZec = PegarouteTradeRecord.read(_trade).source == 'ZEC' &&
          _id == null && RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(_pending.id);
      if (!knownZec) throw StateError(isApproval
          ? 'Approval submission is unconfirmed. Check this order again; do not resend approval.'
          : 'Funding submission is unconfirmed. Do not send another payment.');
    }
    try {
      final actual = _identity(_pending, _trade, PegarouteTradeRecord.read(_trade));
      if (actual == null || (_id != null && actual != _id) ||
          (_id != null && _pending.hex != hex)) {
        throw StateError('Committed transaction identity changed');
      }
      _id = actual;
      if (isApproval) {
        await _provider.store.approvalProgress(claimed, approvalStep!, attempt, id, 'submitted');
      } else {
        final saved = await _provider.store.submitted(claimed, attempt, id);
        await _provider.notifySourceHash(saved, id);
      }
    } catch (error) {
      // Neither a DB/notification error nor completion bookkeeping authorizes a retry.
      bookkeepingError = error;
    }
  }

  @override
  Future<Map<String, String>> commitUR() async => throw StateError('External signing not supported');
}

/// Immutable bridge for existing facades that accept UI Output, not OutputInfo.
/// No screen state or Output autorun is constructed or shared.
final class _BoundDepositOutput implements Output {
  const _BoundDepositOutput(this.info);
  final OutputInfo info;
  @override
  Money get cryptoAmountMoney => info.cryptoAmount;
  @override
  String get address => info.address;
  @override
  String get fiatAmount => '';
  @override
  String get note => '';
  @override
  String get memo => info.memo ?? '';
  @override
  bool get sendAll => false;
  @override
  bool get isParsedAddress => false;
  @override
  String get extractedAddress => '';
  @override
  Map<String, dynamic> get extra => const {};
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError('Immutable deposit output');
}
