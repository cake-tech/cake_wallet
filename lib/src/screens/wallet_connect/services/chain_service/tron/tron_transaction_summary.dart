import "dart:convert";

import "package:blockchain_utils/blockchain_utils.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/models/wc_connection_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:on_chain/tron/tron.dart";

class TronTransactionSummary {
  const TronTransactionSummary({
    required this.text,
    required this.rows,
    required this.ownerAddress,
  });

  factory TronTransactionSummary.of(
    TransactionRaw rawTransaction,
    Map<String, CryptoCurrency> tokensByContract,
  ) {
    if (rawTransaction.contract.length != 1) {
      throw ArgumentError("transaction must carry exactly one contract");
    }

    final contract = rawTransaction.contract.first;
    final value = contract.parameter.value;
    if (contract.type != value.contractType) {
      throw ArgumentError("contract type tag does not match the contract");
    }

    final lines = <String>[];
    final rows = <WCConnectionModel>[];
    String? ownerAddress;
    String? callData;

    if (value is TransferContract) {
      ownerAddress = value.ownerAddress.toAddress();
      lines.add("${S.current.value}: ${_trx(value.amount)}");
      lines.add("${S.current.from}: $ownerAddress");
      lines.add("${S.current.to}: ${value.toAddress.toAddress()}");
    } else if (value is TriggerSmartContract) {
      ownerAddress = value.ownerAddress.toAddress();
      final contractAddress = value.contractAddress.toAddress();
      final token = tokensByContract[contractAddress];
      final callValue = value.callValue ?? BigInt.zero;
      final callTokenValue = value.callTokenValue ?? BigInt.zero;
      final call = callValue > BigInt.zero || callTokenValue > BigInt.zero
          ? null
          : _Trc20Call.tryDecode(value.data);

      if (call != null) {
        final String operation;
        if (call.isIncrease) {
          operation = S.current.wc_increase_allowance;
        } else if (call.isApprove) {
          operation = S.current.approve_tokens;
        } else {
          operation = S.current.send;
        }
        lines.add(operation);
        lines.add("${S.current.value}: ${_tokenAmount(call.amount, token, call.isApprove)}");
        lines.add("${S.current.from}: $ownerAddress");
        final counterparty = call.isApprove ? S.current.wc_approved_address : S.current.to;
        lines.add("$counterparty: ${call.address}");
      } else {
        lines.add("${S.current.from}: $ownerAddress");
        lines.add("${S.current.to}: $contractAddress");
        callData = BytesUtils.toHexString(value.data ?? const [], prefix: "0x");
      }

      if (callValue > BigInt.zero) {
        lines.add("${S.current.value}: ${_trx(callValue)}");
      }

      if (callTokenValue > BigInt.zero) {
        final tokenAmount = S.current.wc_raw_amount(callTokenValue.toString());
        lines.add("${S.current.token}: TRC10 ${value.tokenId ?? ""}, $tokenAmount");
      }

      if (token != null) {
        rows.add(WCConnectionModel(title: S.current.token, text: token.title));
      }
      rows.add(WCConnectionModel(title: S.current.contract_address, text: contractAddress));
    } else {
      final json = value.toJson()..removeWhere((_, field) => field == null);
      ownerAddress = json["owner_address"]?.toString();
      lines.add("${S.current.transaction}: ${contract.type.name}");
      lines.add(_prettyJson.convert(_withTrxAmounts(json)));
    }
    final feeLimit =
        rawTransaction.feeLimit ?? (value is TriggerSmartContract ? BigInt.zero : null);
    if (feeLimit != null) {
      rows.add(WCConnectionModel(title: S.current.wc_max_network_fee, text: _trx(feeLimit)));
    }

    final memo = rawTransaction.data;
    if (memo != null && memo.isNotEmpty) {
      rows.add(
        WCConnectionModel(title: S.current.memo, text: utf8.decode(memo, allowMalformed: true)),
      );
    }

    if (callData != null) {
      rows.add(WCConnectionModel(title: S.current.wc_call_data, text: callData));
    }

    return TronTransactionSummary(
      text: lines.join("\n"),
      rows: rows,
      ownerAddress: ownerAddress,
    );
  }

  final String text;
  final List<WCConnectionModel> rows;

  final String? ownerAddress;

  static final _unlimitedAllowance = (BigInt.one << 256) - BigInt.one;

  static const _sunFields = {"frozen_balance", "unfreeze_balance", "balance"};

  static Map<String, dynamic> _withTrxAmounts(Map<String, dynamic> json) => {
        for (final entry in json.entries)
          entry.key: _sunFields.contains(entry.key) ? _trxOrOriginal(entry.value) : entry.value,
      };

  static Object? _trxOrOriginal(Object? value) {
    final sun = value is String ? BigInt.tryParse(value) : null;

    return sun == null ? value : _trx(sun);
  }

  static final _prettyJson = JsonEncoder.withIndent("  ", (value) => value.toString());

  static String _trx(BigInt sun) => Money(sun, CryptoCurrency.trx).toStringWithSymbol();

  static String _tokenAmount(BigInt amount, CryptoCurrency? token, bool isAllowance) {
    if (isAllowance && amount == _unlimitedAllowance) {
      return token == null ? S.current.wc_unlimited : "${S.current.wc_unlimited} ${token.title}";
    }

    if (token == null) {
      return S.current.wc_raw_amount(amount.toString());
    }

    return Money(amount, token).toStringWithSymbol();
  }
}

class _Trc20Call {
  const _Trc20Call({
    required this.isApprove,
    required this.isIncrease,
    required this.address,
    required this.amount,
  });

  final bool isApprove;
  final bool isIncrease;
  final String address;
  final BigInt amount;

  static const _transferSelector = "a9059cbb";
  static const _approveSelector = "095ea7b3";
  static const _increaseApprovalSelector = "d73dd623";

  static _Trc20Call? tryDecode(List<int>? data) {
    if (data == null || data.length != 68) {
      return null;
    }

    final selector = BytesUtils.toHexString(data.sublist(0, 4));
    final isApprove = selector == _approveSelector || selector == _increaseApprovalSelector;
    if (!isApprove && selector != _transferSelector) {
      return null;
    }

    if (data.sublist(4, 16).any((byte) => byte != 0)) {
      return null;
    }

    return _Trc20Call(
      isApprove: isApprove,
      isIncrease: selector == _increaseApprovalSelector,
      address: TronAddress.fromEthAddress(data.sublist(16, 36)).toAddress(),
      amount: BigintUtils.fromBytes(data.sublist(36, 68)),
    );
  }
}
