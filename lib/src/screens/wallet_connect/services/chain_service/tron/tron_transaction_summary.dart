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
    final lines = <String>[];
    final rows = <WCConnectionModel>[];
    String? ownerAddress;

    if (value is TransferContract) {
      ownerAddress = value.ownerAddress.toAddress();
      lines.add("${S.current.value}: ${_trx(value.amount)}");
      lines.add("${S.current.from}: $ownerAddress");
      lines.add("${S.current.to}: ${value.toAddress.toAddress()}");
    } else if (value is TriggerSmartContract) {
      ownerAddress = value.ownerAddress.toAddress();
      final contractAddress = value.contractAddress.toAddress();
      final token = tokensByContract[contractAddress];
      final call = _Trc20Call.tryDecode(value.data);

      if (call != null) {
        lines.add("${S.current.value}: ${_tokenAmount(call.amount, token, call.isApprove)}");
        lines.add("${S.current.from}: $ownerAddress");
        lines.add("${call.isApprove ? S.current.wc_spender : S.current.to}: ${call.address}");
      } else {
        lines.add("${S.current.from}: $ownerAddress");
        lines.add("${S.current.to}: $contractAddress");

        final callData = BytesUtils.toHexString(value.data ?? const [], prefix: "0x");
        lines.add("${S.current.wc_call_data}: $callData");
      }

      final callValue = value.callValue ?? BigInt.zero;
      if (callValue > BigInt.zero) {
        lines.add("${S.current.value}: ${_trx(callValue)}");
      }

      final callTokenValue = value.callTokenValue ?? BigInt.zero;
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

    final feeLimit = rawTransaction.feeLimit;
    if (feeLimit != null) {
      rows.add(WCConnectionModel(title: S.current.wc_max_network_fee, text: _trx(feeLimit)));
    }

    final memo = rawTransaction.data;
    if (memo != null && memo.isNotEmpty) {
      rows.add(
        WCConnectionModel(title: S.current.memo, text: utf8.decode(memo, allowMalformed: true)),
      );
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
  const _Trc20Call({required this.isApprove, required this.address, required this.amount});

  final bool isApprove;
  final String address;
  final BigInt amount;

  static const _transferSelector = "a9059cbb";
  static const _approveSelector = "095ea7b3";

  static _Trc20Call? tryDecode(List<int>? data) {
    if (data == null || data.length != 68) {
      return null;
    }

    final selector = BytesUtils.toHexString(data.sublist(0, 4));
    if (selector != _transferSelector && selector != _approveSelector) {
      return null;
    }

    if (data.sublist(4, 16).any((byte) => byte != 0)) {
      return null;
    }

    return _Trc20Call(
      isApprove: selector == _approveSelector,
      address: TronAddress.fromEthAddress(data.sublist(16, 36)).toAddress(),
      amount: BigintUtils.fromBytes(data.sublist(36, 68)),
    );
  }
}
