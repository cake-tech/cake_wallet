import 'dart:convert';
import 'dart:math';
import 'package:blockchain_utils/blockchain_utils.dart' show Base58Decoder;
import 'package:crypto/crypto.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cw_core/crypto_currency.dart';
import 'pegaroute_api.dart';
import 'pegaroute_asset_identity.dart';
import 'pegaroute_capability_gate.dart';
import 'pegaroute_currency_mapper.dart';
import 'pegaroute_execution_terms.dart';

/// Provider-owned reviewed wire terms and one-shot evidence. Ordinary Trade
/// fields still own the order, addresses, principal, deadlines and actual hashes.
/// There is no reader for the unreleased native-only or generic-envelope formats.
class PegarouteTradeRecord {
  PegarouteTradeRecord._(this._value);
  final Map<String, dynamic> _value;
  static const _mapper = PegarouteCurrencyMapper();

  String get binding => _value['binding'] as String;
  Map<String, dynamic> get terms => _copy(_value['terms']);
  Map<String, dynamic> get route => _copy(terms['route']);
  PegarouteExecution get execution => PegarouteExecution.fromJson(terms['execution']);
  PegarouteAssetId get sourceAsset => _asset(terms['source']);
  PegarouteAssetId get destinationAsset => _asset(terms['destination']);
  String get source => sourceAsset.chain;
  String get destination => destinationAsset.chain;
  int get sourceDecimals => (terms['source'] as Map)['decimals'] as int;
  int get destinationDecimals => (terms['destination'] as Map)['decimals'] as int;
  String? get attempt => (_value['attempt'] as Map?)?['id'] as String?;
  String? get proposedHash => (_value['attempt'] as Map?)?['hash'] as String?;
  Map<String, dynamic> get approvals => _copy(_value['approvals']);
  Map<String, dynamic>? get refund => _value['refund'] == null ? null : _copy(_value['refund']);

  // Token raw enum IDs are deliberately not identities: Cake's shared reader
  // can resolve a token ticker to a static currency. Retained canonical tuples
  // and token metadata restore the contract/mint before binding validation.
  static const columns = [
    'id', 'providerRaw', 'providerId', 'providerName', 'walletId',
    'fromWalletAddress', 'chainId', 'fromTitle', 'fromTag', 'fromDecimals',
    'toTitle', 'toTag', 'toDecimals', 'amount', 'inputAddress', 'payoutAddress',
    'refundAddress', 'expiredAt', 'memo', 'extraId', 'toAddressExtraId', 'isSendAll',
  ];

  static String _digest(Trade trade, Map<String, dynamic> terms) => _digestRow(trade.toSqliteMap(), terms);

  static String _digestRow(Map<String, dynamic> row, Map<String, dynamic> terms) {
    return sha256.convert(utf8.encode(jsonEncode([
      [for (final key in columns) row[key]], terms,
    ]))).toString();
  }

  static String nonce() {
    final random = Random.secure();
    return List.generate(32, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  static Map<String, dynamic> _copy(Object? value) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

  static Map<String, dynamic> _identity(CryptoCurrency currency) {
    PegarouteAssetIdentity.validateMetadata(currency);
    final asset = _mapper.map(currency);
    return {'chain': asset.chain, 'token': asset.token, 'nativeToken': asset.nativeToken,
      'decimals': currency.decimals, 'identity': PegarouteAssetIdentity.encode(currency)};
  }

  static PegarouteAssetId _asset(Object? value) {
    if (value is! Map || value.length != 5 || value['decimals'] is! int ||
        (value['decimals'] as int) < 0 || (value['decimals'] as int) > 255 ||
        !value.containsKey('identity') ||
        (value['identity'] != null && value['identity'] is! String)) {
      throw const FormatException('Invalid retained Pegaroute asset');
    }
    return _mapper.validateCanonicalTuple(chain: value['chain'] as String,
        token: value['token'] as String, nativeToken: value['nativeToken'] as String);
  }

  static CryptoCurrency _restore(CryptoCurrency? currency, Object? value) {
    final asset = _asset(value);
    final map = value as Map;
    if (currency == null) throw const FormatException('Missing retained currency');
    final raw = map['identity'] as String?;
    if (raw != null) {
      final restored = PegarouteAssetIdentity.decode(raw);
      // Cake's shared decoder may replace a token with a ticker-matching static
      // currency, including a different tag/precision. The provider store checks
      // the actual SQL columns before accepting that lossy reconstruction.
      if (currency.title.toUpperCase() != restored.title.toUpperCase()) {
        throw const FormatException('Retained token metadata changed');
      }
      if (PegarouteAssetIdentity.encode(currency) != null &&
          (currency.decimals != restored.decimals || !_mapper.matchesCanonicalTuple(currency, asset))) {
        throw const FormatException('Retained token identity changed');
      }
      currency = restored;
    }
    PegarouteAssetIdentity.validateMetadata(currency);
    if (currency.decimals != map['decimals'] || !_mapper.matchesCanonicalTuple(currency, asset)) {
      throw const FormatException('Retained currency identity changed');
    }
    return currency;
  }

  // Native gas/deposit currencies by canonical chain, never token tickers.
  static CryptoCurrency currency(String chain) {
    final value = const {'ETH': CryptoCurrency.eth, 'BSC': CryptoCurrency.bnb,
      'BASE': CryptoCurrency.baseEth, 'ARBITRUM': CryptoCurrency.arbEth,
      'POLYGON': CryptoCurrency.maticpoly, 'BTC': CryptoCurrency.btc,
      'BCH': CryptoCurrency.bch, 'LTC': CryptoCurrency.ltc, 'DOGE': CryptoCurrency.doge,
      'XMR': CryptoCurrency.xmr, 'SOL': CryptoCurrency.sol, 'TRON': CryptoCurrency.trx,
      'ZEC': CryptoCurrency.zec}[chain];
    if (value == null) throw const FormatException('Unsupported source chain');
    return value;
  }

  static BigInt units(String amount, String chain) =>
      BigInt.parse(PegarouteExecutionTerms.toBaseUnits(amount, currency(chain).decimals));

  BigInt sourceUnits(String amount) =>
      BigInt.parse(PegarouteExecutionTerms.toBaseUnits(amount, sourceDecimals));

  bool matchesSource(CryptoCurrency currency) => currency.decimals == sourceDecimals &&
      _mapper.matchesCanonicalTuple(currency, sourceAsset);

  factory PegarouteTradeRecord.create(Trade trade,
      {required PegarouteExecution execution, required PegarouteRoute route}) {
    final terms = {'source': _identity(trade.from!), 'destination': _identity(trade.to!),
      'execution': execution.toJson(), 'route': PegarouteExecutionTerms.routeSnapshot(route)};
    final record = PegarouteTradeRecord._({'kind': 'pegaroute-1',
      'binding': _digest(trade, terms), 'terms': terms,
      'attempt': null, 'approvals': <String, dynamic>{}, 'refund': null});
    record.validate(trade);
    return record;
  }

  factory PegarouteTradeRecord.read(Trade trade) {
    final value = jsonDecode(trade.routerData ?? 'null');
    if (value is! Map<String, dynamic> || value.length != 6 ||
        value['kind'] != 'pegaroute-1' || value['binding'] is! String ||
        !value.containsKey('attempt') || !value.containsKey('refund') ||
        value['approvals'] is! Map || value['terms'] is! Map ||
        (value['terms'] as Map).length != 4) {
      throw const FormatException('Missing or corrupt Pegaroute order');
    }
    final record = PegarouteTradeRecord._(value);
    trade.from = _restore(trade.from, record.terms['source']);
    trade.to = _restore(trade.to, record.terms['destination']);
    record.validate(trade);
    return record;
  }

  static Trade fromSqliteRow(Map<String, dynamic> row) {
    final trade = Trade.fromSqliteRow(row);
    final record = PegarouteTradeRecord.read(trade);
    if (_digestRow(row, record.terms) != record.binding) {
      throw const FormatException('Persisted Pegaroute columns changed');
    }
    return trade;
  }

  String encode() => jsonEncode(_value);

  PegarouteTradeRecord _with(String key, Object? value) =>
      PegarouteTradeRecord._(_copy(_value)..[key] = value);

  PegarouteTradeRecord claimed(String id, {String? hash}) =>
      _with('attempt', {'id': id, 'hash': hash});

  PegarouteTradeRecord withApproval(String step, Map<String, dynamic> evidence) =>
      _with('approvals', approvals..[step] = _copy(evidence));

  PegarouteTradeRecord withRefund(Map<String, dynamic> observation) =>
      _with('refund', _copy(observation));

  void validate(Trade trade) {
    final from = sourceAsset;
    final to = destinationAsset;
    final wire = execution;
    final reviewed = route;
    if (binding != _digest(trade, terms) || trade.providerRaw != 17 ||
        from.chain == to.chain && from.token == to.token ||
        !_mapper.matchesCanonicalTuple(trade.from!, from) ||
        !_mapper.matchesCanonicalTuple(trade.to!, to) ||
        trade.from!.decimals != sourceDecimals || trade.to!.decimals != destinationDecimals ||
        sourceUnits(trade.amount) <= BigInt.zero || trade.isSendAll == true ||
        (trade.extraId ?? '').isNotEmpty || (trade.toAddressExtraId ?? '').isNotEmpty ||
        reviewed['provider'] != trade.providerName || reviewed['private'] != false ||
        !PegarouteCapabilityGate.execution(from, wire, trade.providerName!, trade.chainId) ||
        wire.to != trade.inputAddress || wire.memo != trade.memo) {
      throw const FormatException('Pegaroute execution binding changed');
    }
    for (final value in [trade.id, trade.walletId, trade.fromWalletAddress,
      trade.payoutAddress, trade.refundAddress, trade.providerName]) {
      if (value == null || value.isEmpty || value.trim() != value) {
        throw const FormatException('Incomplete Pegaroute intent');
      }
    }
    PegarouteExecutionTerms.validateExecution(execution: wire, sourceChain: source,
        sourceToken: from.token, nativeToken: from.nativeToken, walletChainId: trade.chainId,
        sourceAmount: trade.amount, sourceDecimals: sourceDecimals);
    PegarouteExecutionTerms.validateReviewedExecution(route: reviewed, execution: wire,
        sourceChain: source);
    final claim = _value['attempt'];
    if (claim != null && (claim is! Map || claim.length != 2 ||
        !claim.containsKey('hash') || !_nonce(claim['id']) ||
        (claim['hash'] != null && claim['hash'] is! String))) {
      throw const FormatException('Corrupt funding claim');
    }
    for (final entry in approvals.entries) {
      final evidence = entry.value;
      if (!const {'reset', 'approve'}.contains(entry.key) || wire.approval == null ||
          evidence is! Map || evidence.length != 3 || !_nonce(evidence['id']) ||
          evidence['hash'] is! String ||
          !RegExp(r'^0x[0-9a-fA-F]{64}$').hasMatch(evidence['hash'] as String) ||
          !const {'claimed', 'submitted', 'confirmed', 'failed'}.contains(evidence['state'])) {
        throw const FormatException('Corrupt approval evidence');
      }
    }
    for (final hash in [proposedHash, trade.txId]) {
      if (hash == null) continue;
      validateHash(hash, source);
      if (approvals.values.any((value) =>
          (value as Map)['hash'].toString().toLowerCase() == hash.toLowerCase())) {
        throw const FormatException('Approval is not funding evidence');
      }
    }
    if (proposedHash != null && trade.txId != null && proposedHash != trade.txId) {
      throw const FormatException('Funding hash changed');
    }
    if (trade.outputTransaction != null) validateHash(trade.outputTransaction!, destination);
    if (refund != null) {
      final observed = PegarouteRefund.fromJson(refund);
      if (observed.txHash != null) validateHash(observed.txHash!, source);
      for (final amount in [observed.amount, observed.originalAmount, observed.feeDeducted]) {
        if (amount.length > 512 || !RegExp(r'^(0|[1-9][0-9]*)(\.[0-9]+)?$').hasMatch(amount)) {
          throw const FormatException('Invalid refund amount');
        }
      }
      if (observed.chain != source || observed.refundAddress.trim().isEmpty ||
          observed.refundAddress.length > 512 || trade.isRefund != true) {
        throw const FormatException('Invalid refund observation');
      }
    }
  }

  static void validateHash(String hash, String chain) {
    if (chain == 'SOL') {
      if (hash.length <= 100 && Base58Decoder.decode(hash).length == 64) return;
    } else {
      final evm = PegarouteExecutionTerms.chainIdFor(chain) != null;
      if (RegExp(evm ? r'^0x[0-9a-fA-F]{64}$' : r'^[0-9a-fA-F]{64}$').hasMatch(hash)) return;
    }
    throw const FormatException('Invalid transaction hash');
  }

  static bool _nonce(Object? value) => value is String && RegExp(r'^[a-f0-9]{64}$').hasMatch(value);
}
