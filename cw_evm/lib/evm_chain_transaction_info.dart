// ignore_for_file: overridden_fields, annotate_overrides
import 'package:collection/collection.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/json_transaction_info.dart';
import 'package:cw_evm/evm_chain_registry.dart';
import 'package:cw_evm/utils/evm_chain_utils.dart';

class EVMChainTransactionInfo extends JsonTransactionInfo {
  EVMChainTransactionInfo({
    required super.id,
    required this.height,
    required super.amount,
    required Money super.fee,
    required this.tokenSymbol,
    this.exponent = 18,
    required super.direction,
    required this.isPending,
    required super.date,
    required this.confirmations,
    required super.to,
    required super.from,
    this.evmSignatureName,
    this.contractAddress,
    required this.chainId,
  });

  final int height;
  final int exponent;
  final bool isPending;
  final int confirmations;
  final String tokenSymbol;
  String? _fiatAmount;
  final String? evmSignatureName;
  final String? contractAddress;
  final int chainId;

  String get feeCurrency => EVMChainUtils.getFeeCurrency(chainId);

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) => _fiatAmount = formatAmount(amount);

  static CryptoCurrency amountCurrencyFor({
    required int chainId,
    required Iterable<Erc20Token> tokens,
    required String? contractAddress,
    required int decimals,
    required String tokenSymbol,
  }) {
    final native =
        EvmChainRegistry().getChainConfig(chainId)!.nativeCurrency;

    if (tokenSymbol == native.title) {
      return native;
    }

    final registered = tokens.firstWhereOrNull(
      (token) => contractAddress?.toLowerCase() == token.contractAddress.toLowerCase(),
    );

    return registered ??
        Erc20Token(
          name: "",
          contractAddress: contractAddress ?? "",
          decimal: decimals,
          symbol: tokenSymbol,
        );
  }

  factory EVMChainTransactionInfo.fromJson(
    Map<String, dynamic> data,
    int chainId, {
    Iterable<Erc20Token> tokens = const [],
  }) {
    final decimals = data['exponent'] as int? ?? 18;
    final tokenSymbol = data['tokenSymbol'] as String;
    final currency = amountCurrencyFor(
      chainId: chainId,
      tokens: tokens,
      contractAddress: data['contractAddress'] as String?,
      decimals: decimals,
      tokenSymbol: tokenSymbol,
    );

    final feeCurrency =
        EvmChainRegistry().getChainConfig(chainId)?.nativeCurrency ?? CryptoCurrency.eth;

    return EVMChainTransactionInfo(
      id: data['id'] as String,
      height: data['height'] as int,
      amount: Money(BigInt.parse(data['amount'] as String), currency),
      exponent: decimals,
      fee: Money(BigInt.parse(data['fee'] as String), feeCurrency),
      direction: TransactionDirection.values[data['direction'] as int],
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      isPending: data['isPending'] as bool? ?? false,
      confirmations: data['confirmations'] as int,
      tokenSymbol: tokenSymbol,
      to: data['to'] as String?,
      from: data['from'] as String?,
      evmSignatureName: data['evmSignatureName'] as String?,
      contractAddress: data['contractAddress'] as String?,
      chainId: chainId,
    );
  }

  @override
  String? get status {
    if(chainId == 1 && evmSignatureName == "approval") {
      return "(approval)";
    }

    return super.status;
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'height': height,
        'amount': amount.amount.toString(),
        'exponent': exponent,
        'fee': fee!.amount.toString(),
        'direction': direction.index,
        'date': date.millisecondsSinceEpoch,
        'isPending': isPending,
        'confirmations': confirmations,
        'tokenSymbol': tokenSymbol,
        'to': to,
        'from': from,
        'evmSignatureName': evmSignatureName,
        'contractAddress': contractAddress,
        'chainId': chainId,
      };
}
