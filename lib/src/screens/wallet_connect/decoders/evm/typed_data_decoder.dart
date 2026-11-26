import "dart:convert";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/universal_router_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:eth_sig_util/eth_sig_util.dart";
import "package:eth_sig_util/model/typed_data.dart";

class TypedDataDecoder {
  TypedDataDecoder(this.tokenResolver);

  final Erc20TokenResolver tokenResolver;

  static const _uniswapXReactors = {
    "0x00000011f84b9aa48e5f8aa8b9897600006289be",
    "0x00000006021a6bce796be7ba509bbba71e956e37",
    "0x6000da47483062a0d734ba3dc7576ce6a0b645c4",
    "0xbd7f9d0239f81c94b728d827a87b9864972661ec",
    "0xe80bf394d190851e215d5f67b67f8f5a52783f1e",
    "0xb274d5f4b833b61b340b654d600a864fb604a87c",
    "0x000000008a8330b5d1f43a62bf4c673a49f27ba0",
    "0x0000000015757c461808ea25eb309638b62681cf",
    "0x00000000bab6e234db8ad638b6a6395b7c499bc4",
    "0x00000000a55e50c71b70db3c8b58749cd1e18eb2",
    "0x000000007a1c8e570011eedf86a2a35593013cba",
    "0x000000001ec5656dcdb24d90dfa42742738de729",
    "0x1bd1aadc9e230626c44a139d7e70d842749351eb",
  };

  static const _timestampFieldNames = {
    "deadline",
    "sigdeadline",
    "expiration",
    "expiry",
    "expiretime",
    "expirationtime",
    "validuntil",
    "validafter",
    "validbefore",
  };

  static const _riskPrimaryTypes = {
    "Permit",
    "PermitSingle",
    "PermitBatch",
    "PermitTransferFrom",
    "PermitBatchTransferFrom",
    "PermitWitnessTransferFrom",
    "Order",
    "OrderComponents",
    "BulkOrder",
    "TransferWithAuthorization",
    "ReceiveWithAuthorization",
    "MetaTransaction",
    "HyperliquidTransaction:UsdSend",
    "HyperliquidTransaction:SpotSend",
    "HyperliquidTransaction:SendAsset",
    "HyperliquidTransaction:Withdraw",
    "HyperliquidTransaction:SendMultiSig",
    "HyperliquidTransaction:ConvertToMultiSigUser",
  };

  static const _maxListedTokens = 16;

  static const _maxGenericRows = 200;

  static const _maxNestingDepth = 32;

  static const _maxIntegerLength = 80;

  static const _eip2612Permit =
      "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)";
  static const _daiPermit =
      "Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)";

  static const _permitDetails =
      "PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)";
  static const _permitSingle =
      "PermitSingle(PermitDetails details,address spender,uint256 sigDeadline)$_permitDetails";
  static const _permitBatch =
      "PermitBatch(PermitDetails[] details,address spender,uint256 sigDeadline)$_permitDetails";
  static const _tokenPermissions = "TokenPermissions(address token,uint256 amount)";
  static const _permitTransferFrom =
      "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,"
      "uint256 deadline)$_tokenPermissions";
  static const _permitBatchTransferFrom =
      "PermitBatchTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,"
      "uint256 deadline)$_tokenPermissions";
  static const _permitWitnessTransferFrom =
      "PermitWitnessTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,"
      "uint256 deadline,";

  static const _orderInfo =
      "OrderInfo(address reactor,address swapper,uint256 nonce,uint256 deadline,"
      "address additionalValidationContract,bytes additionalValidationData)";
  static const _dutchOutput =
      "DutchOutput(address token,uint256 startAmount,uint256 endAmount,address recipient)";
  static const _exclusiveDutchOrder =
      "${_permitWitnessTransferFrom}ExclusiveDutchOrder witness)$_dutchOutput"
      "ExclusiveDutchOrder(OrderInfo info,uint256 decayStartTime,uint256 decayEndTime,"
      "address exclusiveFiller,uint256 exclusivityOverrideBps,address inputToken,"
      "uint256 inputStartAmount,uint256 inputEndAmount,DutchOutput[] outputs)"
      "$_orderInfo$_tokenPermissions";
  static const _v2DutchOrder =
      "${_permitWitnessTransferFrom}V2DutchOrder witness)$_dutchOutput$_orderInfo$_tokenPermissions"
      "V2DutchOrder(OrderInfo info,address cosigner,address baseInputToken,"
      "uint256 baseInputStartAmount,uint256 baseInputEndAmount,DutchOutput[] baseOutputs)";
  static const _v3DutchOrder =
      "${_permitWitnessTransferFrom}V3DutchOrder witness)"
      "NonlinearDutchDecay(uint256 relativeBlocks,int256[] relativeAmounts)"
      "$_orderInfo$_tokenPermissions"
      "V3DutchInput(address token,uint256 startAmount,NonlinearDutchDecay curve,"
      "uint256 maxAmount,uint256 adjustmentPerGweiBaseFee)"
      "V3DutchOrder(OrderInfo info,address cosigner,uint256 startingBaseFee,"
      "V3DutchInput baseInput,V3DutchOutput[] baseOutputs)"
      "V3DutchOutput(address token,uint256 startAmount,NonlinearDutchDecay curve,"
      "address recipient,uint256 minAmount,uint256 adjustmentPerGweiBaseFee)";
  static const _priorityOrder =
      "${_permitWitnessTransferFrom}PriorityOrder witness)$_orderInfo"
      "PriorityInput(address token,uint256 amount,uint256 mpsPerPriorityFeeWei)"
      "PriorityOrder(OrderInfo info,address cosigner,uint256 auctionStartBlock,"
      "uint256 baselinePriorityFeeWei,PriorityInput input,PriorityOutput[] outputs)"
      "PriorityOutput(address token,uint256 amount,uint256 mpsPerPriorityFeeWei,"
      "address recipient)$_tokenPermissions";
  static const _uniswapXOrders = {
    _exclusiveDutchOrder: _UniswapXOrder(outputsField: "outputs", lowestAmountField: "endAmount"),
    _v2DutchOrder: _UniswapXOrder(outputsField: "baseOutputs", lowestAmountField: "endAmount"),
    _v3DutchOrder: _UniswapXOrder(outputsField: "baseOutputs", lowestAmountField: "minAmount"),
    _priorityOrder: _UniswapXOrder(outputsField: "outputs", lowestAmountField: "amount"),
  };

  static const _domainFieldTypes = {
    "name": "string",
    "version": "string",
    "chainId": "uint256",
    "verifyingContract": "address",
    "salt": "bytes32",
  };

  static final _fixedBytesLengths = {
    for (int length = 1; length <= 32; length++) "bytes$length": length,
  };
  static final _uintBits = {
    "uint": 256,
    for (int bits = 8; bits <= 256; bits += 8) "uint$bits": bits,
  };
  static final _intBits = {"int": 256, for (int bits = 8; bits <= 256; bits += 8) "int$bits": bits};
  static final _atomicTypes = {
    "bool",
    "string",
    "address",
    "bytes",
    ..._fixedBytesLengths.keys,
    ..._uintBits.keys,
    ..._intBits.keys,
  };

  static final _structName = RegExp(r"^\w+(:\w+)?$");
  static final _fieldName = RegExp(r"^[\w$]+$");
  static final _typeName = RegExp(r"^(\w+)(\[\d*\])*$");
  static final _address = RegExp(r"^0x[0-9a-fA-F]{40}$");
  static final _hexBytes = RegExp(r"^0x([0-9a-fA-F]{2})*$");
  static final _hexInteger = RegExp(r"^0x[0-9a-fA-F]+$");
  static final _decimal = RegExp(r"^-?[0-9]+$");

  static void validate(String data, TypedDataVersion version) {
    try {
      final payload = jsonDecode(data);
      if (version == TypedDataVersion.V1) {
        _legacyEntries(payload);
      } else {
        final typedData = _parseTypedData(payload);
        final hashedType = TypedDataUtil.encodeType(typedData.primaryType, {
          for (final struct in typedData.types.entries)
            struct.key: [
              for (final field in struct.value.entries)
                TypedDataField(name: field.key, type: field.value),
            ],
        });
        if (hashedType != typedData.typeString) {
          throw const FormatException("The primary type is not hashed as it is declared");
        }
      }

      TypedDataUtil.hashMessage(jsonData: data, version: version);
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException("Typed data cannot be signed: $e");
    }
  }

  static int? domainChainId(String data) {
    final payload = jsonDecode(data);
    if (payload is List) {
      return null;
    }

    return _signedChainId(_parseTypedData(payload).domain);
  }

  static int? _signedChainId(Map<String, dynamic> domain) {
    final chainId = domain["chainId"];
    if (chainId != null) {
      return _integer(chainId).toInt();
    }

    final salt = domain["salt"];
    final saltNumber = salt == null ? BigInt.zero : _integer(salt);
    return saltNumber > BigInt.zero && saltNumber.isValidInt ? saltNumber.toInt() : null;
  }

  Future<WCDecodedRequest> decode(
    String data, {
    required String walletAddress,
    required int? chainId,
    required String nativeSymbol,
  }) async {
    final payload = jsonDecode(data);
    if (payload is List) {
      return _decodeLegacyV1(payload);
    }

    final typedData = _parseTypedData(payload);
    final semantic = await _decodeSemantics(
      typedData,
      walletAddress: walletAddress,
      chainId: chainId,
      nativeSymbol: nativeSymbol,
    );
    return semantic ?? _decodeGeneric(typedData);
  }

  Future<WCDecodedRequest?> _decodeSemantics(
    _TypedData typedData, {
    required String walletAddress,
    required int? chainId,
    required String nativeSymbol,
  }) async {
    final typeString = typedData.typeString;
    final message = typedData.message;
    final verifyingContract = typedData.domain["verifyingContract"] as String?;
    if (verifyingContract == null) {
      return null;
    }

    if (typeString == _eip2612Permit) {
      return _buildTokenPermit(
        typedData,
        title: S.current.wc_action_permit,
        tokenAddress: verifyingContract,
        amount: _integer(message["value"]),
        validUntil: tokenResolver.formatExpiry(_integer(message["deadline"])),
        chainId: chainId,
      );
    }

    if (typeString == _daiPermit) {
      final isAllowed = message["allowed"] as bool;
      final expiry = _integer(message["expiry"]);
      final isRevoke = !isAllowed && tokenResolver.isKnown(verifyingContract, chainId: chainId);
      return _buildTokenPermit(
        typedData,
        title: isRevoke ? S.current.wc_action_revoke_approval : S.current.wc_action_permit,
        tokenAddress: verifyingContract,
        amount: isAllowed ? EvmCalldata.uint256Max : BigInt.zero,
        validUntil: expiry == BigInt.zero ? S.current.wc_never : tokenResolver.formatExpiry(expiry),
        chainId: chainId,
      );
    }

    if (verifyingContract.toLowerCase() != EvmSelectors.permit2Address) {
      return null;
    }

    if (typeString == _permitSingle || typeString == _permitBatch) {
      return _buildPermit2(
        typedData,
        permissions: message["details"],
        deadline: _integer(message["sigDeadline"]),
        chainId: chainId,
      );
    }

    if (typeString == _permitTransferFrom || typeString == _permitBatchTransferFrom) {
      return _buildPermit2(
        typedData,
        permissions: message["permitted"],
        deadline: _integer(message["deadline"]),
        chainId: chainId,
      );
    }

    final order = _uniswapXOrders[typeString];
    if (order == null) {
      return null;
    }

    return _buildUniswapXOrder(
      typedData,
      order,
      walletAddress: walletAddress,
      chainId: chainId,
      nativeSymbol: nativeSymbol,
    );
  }

  Future<WCDecodedRequest> _buildTokenPermit(
    _TypedData typedData, {
    required String title,
    required String tokenAddress,
    required BigInt amount,
    required String validUntil,
    required int? chainId,
  }) async => WCDecodedRequest(
    actionTitle: title,
    actionSubtitle: typedData.domain["name"] as String?,
    rows: [
      ...await _tokenAmountRows(tokenAddress, amount),
      WCDecodedRow(
        label: S.current.wc_approved_spender,
        value: typedData.message["spender"] as String,
        kind: WCDecodedRowKind.address,
      ),
      WCDecodedRow(label: S.current.wc_signature_valid_until, value: validUntil),
      ..._signingContextRows(typedData.domain, includeContract: false),
    ],
    warnings: [
      S.current.wc_warning_permit_review,
      if (tokenResolver.isUnlimitedAmount(amount)) S.current.wc_warning_unlimited_approval,
      if (!tokenResolver.isKnown(tokenAddress, chainId: chainId))
        S.current.wc_warning_unknown_token,
    ],
    rawFallback: typedData.signedJson,
  );

  Future<WCDecodedRequest?> _buildPermit2(
    _TypedData typedData, {
    required dynamic permissions,
    required BigInt deadline,
    required int? chainId,
  }) async {
    final tokens = [
      if (permissions is List) ...permissions else permissions,
    ].cast<Map<String, dynamic>>();
    if (tokens.length > _maxListedTokens) {
      return null;
    }

    final tokenRows = await Future.wait(
      tokens.map((token) async {
        final expiration = token["expiration"];
        return [
          ...await _tokenAmountRows(token["token"] as String, _integer(token["amount"])),
          if (expiration != null)
            WCDecodedRow(
              label: S.current.wc_expiration,
              value: tokenResolver.formatExpiry(_integer(expiration)),
            ),
        ];
      }),
    );

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_permit2,
      actionSubtitle: "Permit2",
      rows: [
        ...tokenRows.expand((rows) => rows),
        WCDecodedRow(
          label: S.current.wc_approved_spender,
          value: typedData.message["spender"] as String,
          kind: WCDecodedRowKind.address,
        ),
        WCDecodedRow(
          label: S.current.wc_signature_valid_until,
          value: tokenResolver.formatExpiry(deadline),
        ),
        ..._signingContextRows(typedData.domain),
      ],
      warnings: [
        S.current.wc_warning_permit_review,
        if (tokens.any((token) => tokenResolver.isUnlimitedAmount(_integer(token["amount"]))))
          S.current.wc_warning_unlimited_approval,
        if (tokens.any(
          (token) => !tokenResolver.isKnown(token["token"] as String, chainId: chainId),
        ))
          S.current.wc_warning_unknown_token,
      ],
      rawFallback: typedData.signedJson,
    );
  }

  Future<WCDecodedRequest?> _buildUniswapXOrder(
    _TypedData typedData,
    _UniswapXOrder order, {
    required String walletAddress,
    required int? chainId,
    required String nativeSymbol,
  }) async {
    final message = typedData.message;
    final permitted = message["permitted"] as Map<String, dynamic>;
    final witness = message["witness"] as Map<String, dynamic>;
    final info = witness["info"] as Map<String, dynamic>;
    final reactor = (info["reactor"] as String).toLowerCase();
    final outputs = (witness[order.outputsField] as List<dynamic>).cast<Map<String, dynamic>>();
    if (!_uniswapXReactors.contains(reactor) ||
        (message["spender"] as String).toLowerCase() != reactor ||
        outputs.isEmpty ||
        outputs.length > _maxListedTokens) {
      return null;
    }

    final payToken = permitted["token"] as String;
    final payAmount = _integer(permitted["amount"]);
    final tokenAddresses = {
      payToken.toLowerCase(),
      for (final output in outputs) (output["token"] as String).toLowerCase(),
    }..remove(SwapPlan.nativeToken);
    final resolved = Map.fromIterables(
      tokenAddresses,
      await Future.wait(tokenAddresses.map(tokenResolver.resolve)),
    );

    List<WCDecodedRow> amountRows(String label, String tokenAddress, BigInt amount) {
      final token = resolved[tokenAddress.toLowerCase()];
      return [
        WCDecodedRow(label: label, value: tokenResolver.amountText(amount, token, tokenAddress)),
        WCDecodedRow(
          label: S.current.wc_token,
          value: tokenAddress,
          kind: WCDecodedRowKind.address,
        ),
      ];
    }

    List<WCDecodedRow> outputRows(String label, String tokenAddress, BigInt amount) {
      if (tokenAddress.toLowerCase() != SwapPlan.nativeToken) {
        return amountRows(label, tokenAddress, amount);
      }

      return [
        WCDecodedRow(
          label: label,
          value: "${tokenResolver.formatNativeAmount(amount)} $nativeSymbol",
        ),
      ];
    }

    final walletOutputs = <WCDecodedRow>[];
    final otherOutputs = <WCDecodedRow>[];
    for (final output in outputs) {
      final token = output["token"] as String;
      final recipient = output["recipient"] as String;
      final lowestAmount = _integer(output[order.lowestAmountField]);

      if (recipient.toLowerCase() == walletAddress.toLowerCase()) {
        walletOutputs.addAll(outputRows(S.current.wc_swap_to_min, token, lowestAmount));
      } else {
        otherOutputs.addAll(outputRows(S.current.wc_amount, token, lowestAmount));
        otherOutputs.add(
          WCDecodedRow(
            label: S.current.wc_recipient,
            value: recipient,
            kind: WCDecodedRowKind.address,
          ),
        );
      }
    }

    return WCDecodedRequest(
      actionTitle: S.current.wc_action_swap,
      actionSubtitle: S.current.wc_via("UniswapX"),
      rows: [
        ...amountRows(S.current.wc_swap_from_max, payToken, payAmount),
        ...walletOutputs,
        ...otherOutputs,
        WCDecodedRow(
          label: S.current.wc_signature_valid_until,
          value: tokenResolver.formatExpiry(_integer(message["deadline"])),
        ),
      ],
      detailRows: [
        WCDecodedRow(
          label: S.current.wc_approved_spender,
          value: reactor,
          kind: WCDecodedRowKind.address,
        ),
        ..._signingContextRows(typedData.domain),
      ],
      warnings: [
        S.current.wc_warning_permit_review,
        if (tokenResolver.isUnlimitedAmount(payAmount)) S.current.wc_warning_unlimited_approval,
        if (walletOutputs.isEmpty) S.current.wc_warning_recipient_not_you,
        if (tokenAddresses.any((address) => !tokenResolver.isKnown(address, chainId: chainId)))
          S.current.wc_warning_unknown_token,
      ],
      rawFallback: typedData.signedJson,
    );
  }

  WCDecodedRequest _decodeGeneric(_TypedData typedData) {
    final primaryType = typedData.primaryType;
    final domainName = typedData.domain["name"] as String?;
    final isPermit = primaryType.toLowerCase().contains("permit");
    final isAuthorization = primaryType.endsWith("Authorization");
    final fieldRows = <WCDecodedRow>[];
    _flatten(primaryType, typedData.message, typedData.types, fieldRows, name: "", label: "");
    final hiddenRows =
        _rowCount(primaryType, typedData.message, typedData.types) - fieldRows.length;
    return WCDecodedRequest(
      actionTitle: isPermit ? S.current.wc_action_permit : S.current.wc_action_sign_typed_data,
      actionSubtitle: primaryType,
      rows: [
        if (domainName != null && domainName.isNotEmpty)
          WCDecodedRow(label: S.current.wc_domain, value: domainName),
        ..._signingContextRows(typedData.domain),
        WCDecodedRow(label: S.current.wc_primary_type, value: primaryType),
        ...fieldRows,
        if (hiddenRows > 0)
          WCDecodedRow(label: "…", value: S.current.wc_more_rows(hiddenRows.toString())),
      ],
      warnings: [
        if (isPermit || isAuthorization) S.current.wc_warning_permit_review,
        if (_riskPrimaryTypes.contains(primaryType)) S.current.wc_warning_typed_data_unrecognized,
      ],
      rawFallback: typedData.signedJson,
    );
  }

  WCDecodedRequest _decodeLegacyV1(List<dynamic> payload) => WCDecodedRequest(
    actionTitle: S.current.wc_action_sign_typed_data,
    rows: [
      for (final entry in _legacyEntries(payload))
        _leafRow(
          entry["type"] as String,
          entry["value"],
          name: entry["name"] as String,
          label: entry["name"] as String,
        ),
    ],
    rawFallback: const JsonEncoder.withIndent("  ").convert(payload),
  );

  Future<List<WCDecodedRow>> _tokenAmountRows(String tokenAddress, BigInt amount) async {
    final token = await tokenResolver.resolve(tokenAddress);
    final symbol = tokenResolver.symbolOrShort(token, tokenAddress);
    return [
      WCDecodedRow(label: S.current.wc_token, value: tokenResolver.displayName(token, symbol)),
      WCDecodedRow(
        label: S.current.wc_contract,
        value: tokenAddress,
        kind: WCDecodedRowKind.address,
      ),
      WCDecodedRow(
        label: S.current.wc_amount,
        value: tokenResolver.amountText(amount, token, tokenAddress),
        kind: WCDecodedRowKind.amount,
      ),
    ];
  }

  List<WCDecodedRow> _signingContextRows(
    Map<String, dynamic> domain, {
    bool includeContract = true,
  }) {
    final chainId = _signedChainId(domain);
    final salt = domain["salt"] as String?;
    final isSaltChainId = chainId != null && domain["chainId"] == null;
    final verifyingContract = domain["verifyingContract"] as String?;
    return [
      if (chainId != null) WCDecodedRow(label: S.current.chain_id, value: chainId.toString()),
      if (salt != null && !isSaltChainId) WCDecodedRow(label: "salt", value: salt),
      if (includeContract && verifyingContract != null)
        WCDecodedRow(
          label: S.current.wc_verifying_contract,
          value: verifyingContract,
          kind: WCDecodedRowKind.address,
        ),
    ];
  }

  void _flatten(
    String type,
    dynamic value,
    Map<String, Map<String, String>> types,
    List<WCDecodedRow> rows, {
    required String name,
    required String label,
  }) {
    final fields = types[type];
    if (fields != null && value is Map<String, dynamic>) {
      for (final field in fields.entries) {
        if (rows.length == _maxGenericRows) {
          return;
        }

        _flatten(
          field.value,
          value[field.key],
          types,
          rows,
          name: field.key,
          label: label.isEmpty ? field.key : "$label.${field.key}",
        );
      }
      return;
    }

    if (value is List) {
      final elementType = type.substring(0, type.lastIndexOf("["));
      rows.add(WCDecodedRow(label: label, value: "[${value.length}]"));
      for (int index = 0; index < value.length && rows.length < _maxGenericRows; index++) {
        _flatten(elementType, value[index], types, rows, name: name, label: "$label[$index]");
      }
      return;
    }

    rows.add(_leafRow(type, value, name: name, label: label));
  }

  static int _rowCount(String type, dynamic value, Map<String, Map<String, String>> types) {
    final fields = types[type];
    if (fields != null && value is Map<String, dynamic>) {
      int count = 0;
      for (final field in fields.entries) {
        count += _rowCount(field.value, value[field.key], types);
      }
      return count;
    }

    if (value is List) {
      final elementType = type.substring(0, type.lastIndexOf("["));
      int count = 1;
      for (final element in value) {
        count += _rowCount(elementType, element, types);
      }
      return count;
    }

    return 1;
  }

  WCDecodedRow _leafRow(String type, dynamic value, {required String name, required String label}) {
    final isTimestamp =
        _uintBits.containsKey(type) && _timestampFieldNames.contains(name.toLowerCase());
    final isAddress =
        type == "address" || (value is String && value.length == 42 && value.startsWith("0x"));
    return WCDecodedRow(
      label: label,
      value: isTimestamp ? tokenResolver.formatTimestamp(_integer(value)) : value.toString(),
      kind: isAddress ? WCDecodedRowKind.address : WCDecodedRowKind.text,
    );
  }

  static List<Map<String, dynamic>> _legacyEntries(dynamic payload) {
    if (payload is! List || payload.isEmpty) {
      throw const FormatException("Legacy typed data is not a list of entries");
    }

    final entries = <Map<String, dynamic>>[];
    for (final entry in payload) {
      if (entry is! Map<String, dynamic> || entry["name"] is! String || entry["type"] is! String) {
        throw const FormatException("A legacy typed data entry has no name or no type");
      }

      if (!_fitsAtomicType(entry["type"] as String, entry["value"])) {
        throw FormatException("A legacy value does not fit its type ${entry["type"]}");
      }

      entries.add(entry);
    }
    return entries;
  }

  static _TypedData _parseTypedData(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      throw const FormatException("Typed data is not an object");
    }

    final primaryType = payload["primaryType"];
    final types = _structTypes(payload["types"]);
    final domainFields = types["EIP712Domain"];
    final messageFields = types[primaryType];
    if (primaryType is! String || primaryType == "EIP712Domain" || messageFields == null) {
      throw const FormatException("The primary type is not a declared struct");
    }

    if (domainFields == null ||
        domainFields.entries.any((field) => _domainFieldTypes[field.key] != field.value)) {
      throw const FormatException("EIP712Domain is not declared or has a non-standard field");
    }

    final domain = _declaredStruct(domainFields, payload["domain"], types, 0);
    final chainId = domain["chainId"];
    if (chainId != null && !_integer(chainId).isValidInt) {
      throw const FormatException("The domain chain id is too large");
    }

    return _TypedData(
      types: types,
      primaryType: primaryType,
      domain: domain,
      message: _declaredStruct(messageFields, payload["message"], types, 0),
    );
  }

  static Map<String, Map<String, String>> _structTypes(dynamic declaredTypes) {
    if (declaredTypes is! Map<String, dynamic>) {
      throw const FormatException("Typed data has no types");
    }

    final types = <String, Map<String, String>>{};
    for (final struct in declaredTypes.entries) {
      final declaredFields = struct.value;
      if (declaredFields is! List || !_structName.hasMatch(struct.key)) {
        throw FormatException("${struct.key} is not a valid struct type");
      }

      final fields = <String, String>{};
      for (final field in declaredFields) {
        if (field is! Map<String, dynamic>) {
          throw FormatException("${struct.key} has a field that is not an object");
        }

        final name = field["name"];
        final type = field["type"];
        if (name is! String ||
            type is! String ||
            !_fieldName.hasMatch(name) ||
            fields.containsKey(name)) {
          throw FormatException("${struct.key} has a malformed or repeated field");
        }

        fields[name] = type;
      }
      types[struct.key] = fields;
    }

    for (final type in types.values.expand((fields) => fields.values)) {
      final baseType = _typeName.firstMatch(type)?.group(1);
      if (!types.containsKey(baseType) && !_atomicTypes.contains(baseType)) {
        throw FormatException("$type is not a declared or atomic type");
      }
    }
    return types;
  }

  static Map<String, dynamic> _declaredStruct(
    Map<String, String> fields,
    dynamic value,
    Map<String, Map<String, String>> types,
    int depth,
  ) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException("A struct value is not an object");
    }

    return {
      for (final field in fields.entries)
        field.key: _declaredValue(field.value, value[field.key], types, depth + 1),
    };
  }

  static dynamic _declaredValue(
    String type,
    dynamic value,
    Map<String, Map<String, String>> types,
    int depth,
  ) {
    if (value == null) {
      throw FormatException("A declared $type field has no value");
    }

    if (depth > _maxNestingDepth) {
      throw const FormatException("Typed data is nested too deeply");
    }

    if (type.endsWith("]")) {
      final sizeStart = type.lastIndexOf("[") + 1;
      final size = int.tryParse(type.substring(sizeStart, type.length - 1));
      if (value is! List || (size != null && value.length != size)) {
        throw FormatException("A value does not fit its declared type $type");
      }

      final elementType = type.substring(0, sizeStart - 1);
      return [for (final element in value) _declaredValue(elementType, element, types, depth + 1)];
    }

    final fields = types[type];
    if (fields != null) {
      return _declaredStruct(fields, value, types, depth);
    }

    if (!_fitsAtomicType(type, value)) {
      throw FormatException("A value does not fit its declared type $type");
    }
    return value;
  }

  static bool _fitsAtomicType(String type, dynamic value) {
    if (type == "bool") {
      return value is bool;
    }

    if (type == "string") {
      return value is String;
    }

    if (type == "address") {
      return value is String && _address.hasMatch(value);
    }

    if (type == "bytes") {
      return value is String && _hexBytes.hasMatch(value);
    }

    final byteLength = _fixedBytesLengths[type];
    if (byteLength != null) {
      return value is String && _hexBytes.hasMatch(value) && value.length == 2 + byteLength * 2;
    }

    final uintBits = _uintBits[type];
    if (uintBits != null) {
      final number = _integer(value);
      return !number.isNegative && number.bitLength <= uintBits;
    }

    final intBits = _intBits[type];
    return intBits != null && _integer(value).bitLength < intBits;
  }

  static BigInt _integer(dynamic value) {
    if (value is int) {
      return BigInt.from(value);
    }

    if (value is String && value.length <= _maxIntegerLength) {
      if (_decimal.hasMatch(value)) {
        return BigInt.parse(value);
      }

      if (_hexInteger.hasMatch(value)) {
        return BigInt.parse(value.substring(2), radix: 16);
      }
    }

    throw const FormatException("A value is not an integer");
  }
}

class _TypedData {
  const _TypedData({
    required this.types,
    required this.primaryType,
    required this.domain,
    required this.message,
  });

  final Map<String, Map<String, String>> types;
  final String primaryType;
  final Map<String, dynamic> domain;
  final Map<String, dynamic> message;

  String get typeString {
    final referenced = <String, Map<String, String>>{};
    _addReferencedStructs(primaryType, referenced);

    final dependencies = referenced.entries.skip(1).toList()
      ..sort((first, second) => first.key.compareTo(second.key));
    return [...referenced.entries.take(1), ...dependencies].map((struct) {
      final fields = struct.value.entries.map((field) => "${field.value} ${field.key}");
      return "${struct.key}(${fields.join(",")})";
    }).join();
  }

  String get signedJson => const JsonEncoder.withIndent("  ").convert({
    "types": {
      for (final struct in types.entries)
        struct.key: [
          for (final field in struct.value.entries) {"name": field.key, "type": field.value},
        ],
    },
    "primaryType": primaryType,
    "domain": domain,
    "message": message,
  });

  void _addReferencedStructs(String type, Map<String, Map<String, String>> referenced) {
    final structName = type.split("[").first;
    final fields = types[structName];
    if (fields == null || referenced.containsKey(structName)) {
      return;
    }

    referenced[structName] = fields;
    for (final fieldType in fields.values) {
      _addReferencedStructs(fieldType, referenced);
    }
  }
}

class _UniswapXOrder {
  const _UniswapXOrder({required this.outputsField, required this.lowestAmountField});

  final String outputsField;
  final String lowestAmountField;
}
