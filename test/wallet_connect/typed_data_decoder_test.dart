import "dart:convert";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/typed_data_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:convert/convert.dart";
import "package:cw_core/erc20_token.dart";
import "package:eth_sig_util/eth_sig_util.dart";
import "package:eth_sig_util/model/typed_data.dart";
import "package:flutter_test/flutter_test.dart";

import "stubs.dart";

const walletKey = "0000000000000000000000000000000000000000000000000000000000000001";
const wallet = "0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf";
const spender = "0x4444444444444444444444444444444444444444";
const stranger = "0x9999999999999999999999999999999999999999";
const feeRecipient = "0x7777777777777777777777777777777777777777";
const cosigner = "0x4449Cd34d1eB1FEDCF02A1Be3834FfDe8E6A6180";
const zeroAddress = "0x0000000000000000000000000000000000000000";

const usdc = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const dai = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const weth = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const usdt = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
const unlistedToken = "0x5555555555555555555555555555555555555555";

const permit2 = "0x000000000022D473030F116dDEE9F6B43aC78BA3";
const exclusiveDutchReactor = "0x6000da47483062A0D734Ba3dc7576Ce6A0B645C4";
const v2DutchReactor = "0x00000011F84B9aa48e5f8aA8B9897600006289Be";
const v3DutchReactor = "0xB274d5F4b833b61B340b654d600A864fB604a87c";
const priorityReactor = "0x000000008a8330b5d1f43a62bf4c673a49f27ba0";

const polygonUsdc = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
const polygonChainId = 137;
const hyperliquidAgent = "0x1111111111111111111111111111111111111111";
const hyperliquidDestination = "0x2222222222222222222222222222222222222222";

const sessionChainId = 1;

const tokenDomainFields = {
  "name": "string",
  "version": "string",
  "chainId": "uint256",
  "verifyingContract": "address",
};
const permit2DomainFields = {
  "name": "string",
  "chainId": "uint256",
  "verifyingContract": "address",
};

const eip2612Fields = {
  "owner": "address",
  "spender": "address",
  "value": "uint256",
  "nonce": "uint256",
  "deadline": "uint256",
};
const daiPermitFields = {
  "holder": "address",
  "spender": "address",
  "nonce": "uint256",
  "expiry": "uint256",
  "allowed": "bool",
};
const permitDetailsFields = {
  "token": "address",
  "amount": "uint160",
  "expiration": "uint48",
  "nonce": "uint48",
};
const tokenPermissionsFields = {"token": "address", "amount": "uint256"};
const orderInfoFields = {
  "reactor": "address",
  "swapper": "address",
  "nonce": "uint256",
  "deadline": "uint256",
  "additionalValidationContract": "address",
  "additionalValidationData": "bytes",
};
const dutchOutputFields = {
  "token": "address",
  "startAmount": "uint256",
  "endAmount": "uint256",
  "recipient": "address",
};

List<Map<String, String>> fields(Map<String, String> typeByName) => [
  for (final field in typeByName.entries) {"name": field.key, "type": field.value},
];

Map<String, dynamic> typedData({
  required String primaryType,
  required Map<String, Map<String, String>> structs,
  required Map<String, String> domainFields,
  required Map<String, dynamic> domain,
  required Map<String, dynamic> message,
}) => {
  "types": <String, dynamic>{
    "EIP712Domain": fields(domainFields),
    for (final struct in structs.entries) struct.key: fields(struct.value),
  },
  "primaryType": primaryType,
  "domain": domain,
  "message": message,
};

Map<String, dynamic> eip2612Permit({
  String value = "500000000",
  dynamic chainId = 1,
  String deadline = "1791460959",
}) => typedData(
  primaryType: "Permit",
  structs: {"Permit": eip2612Fields},
  domainFields: tokenDomainFields,
  domain: {"name": "USD Coin", "version": "2", "chainId": chainId, "verifyingContract": usdc},
  message: {
    "owner": wallet,
    "spender": spender,
    "value": value,
    "nonce": "7",
    "deadline": deadline,
  },
);

Map<String, dynamic> polygonPosPermit({required String salt, int? chainId}) => typedData(
  primaryType: "Permit",
  structs: {"Permit": eip2612Fields},
  domainFields: {
    "name": "string",
    "version": "string",
    if (chainId != null) "chainId": "uint256",
    "verifyingContract": "address",
    "salt": "bytes32",
  },
  domain: {
    "name": "USD Coin (PoS)",
    "version": "1",
    "chainId": ?chainId,
    "verifyingContract": polygonUsdc,
    "salt": salt,
  },
  message: eip2612Permit()["message"] as Map<String, dynamic>,
);

String saltWord(BigInt salt) => "0x${salt.toRadixString(16).padLeft(64, "0")}";

Map<String, dynamic> hyperliquidAction(
  String action,
  Map<String, String> actionFields,
  Map<String, dynamic> message, {
  Map<String, Map<String, String>> structs = const {},
}) => typedData(
  primaryType: "HyperliquidTransaction:$action",
  structs: {"HyperliquidTransaction:$action": actionFields, ...structs},
  domainFields: tokenDomainFields,
  domain: {
    "name": "HyperliquidSignTransaction",
    "version": "1",
    "chainId": 42161,
    "verifyingContract": zeroAddress,
  },
  message: message,
);

Map<String, dynamic> hyperliquidApproveAgent() => hyperliquidAction(
  "ApproveAgent",
  {
    "hyperliquidChain": "string",
    "agentAddress": "address",
    "agentName": "string",
    "nonce": "uint64",
  },
  {
    "hyperliquidChain": "Mainnet",
    "agentAddress": hyperliquidAgent,
    "agentName": "",
    "nonce": 1732600000000,
  },
);

const hyperliquidTransferFields = {
  "hyperliquidChain": "string",
  "destination": "string",
  "amount": "string",
  "time": "uint64",
};

Map<String, dynamic> hyperliquidTransfer(String action) =>
    hyperliquidAction(action, hyperliquidTransferFields, {
      "hyperliquidChain": "Mainnet",
      "destination": hyperliquidDestination,
      "amount": "12.5",
      "time": 1732600000001,
    });

Map<String, dynamic> daiPermit({dynamic allowed = true, String expiry = "0"}) => typedData(
  primaryType: "Permit",
  structs: {"Permit": daiPermitFields},
  domainFields: tokenDomainFields,
  domain: {"name": "Dai Stablecoin", "version": "1", "chainId": 1, "verifyingContract": dai},
  message: {
    "holder": wallet,
    "spender": spender,
    "nonce": "3",
    "expiry": expiry,
    "allowed": allowed,
  },
);

Map<String, dynamic> permit2Data({
  required String primaryType,
  required Map<String, Map<String, String>> structs,
  required Map<String, dynamic> message,
  String verifyingContract = permit2,
}) => typedData(
  primaryType: primaryType,
  structs: structs,
  domainFields: permit2DomainFields,
  domain: {"name": "Permit2", "chainId": 1, "verifyingContract": verifyingContract},
  message: message,
);

Map<String, dynamic> permitSingle({
  String amount = "250000000",
  String verifyingContract = permit2,
  String expiration = "1700000000",
  String sigDeadline = "1700003600",
}) => permit2Data(
  primaryType: "PermitSingle",
  structs: {
    "PermitSingle": {"details": "PermitDetails", "spender": "address", "sigDeadline": "uint256"},
    "PermitDetails": permitDetailsFields,
  },
  verifyingContract: verifyingContract,
  message: {
    "details": {"token": usdc, "amount": amount, "expiration": expiration, "nonce": "0"},
    "spender": spender,
    "sigDeadline": sigDeadline,
  },
);

Map<String, dynamic> permitBatch({required List<Map<String, dynamic>> details}) => permit2Data(
  primaryType: "PermitBatch",
  structs: {
    "PermitBatch": {"details": "PermitDetails[]", "spender": "address", "sigDeadline": "uint256"},
    "PermitDetails": permitDetailsFields,
  },
  message: {"details": details, "spender": spender, "sigDeadline": "1700003600"},
);

Map<String, dynamic> permitTransferFrom({required String amount}) => permit2Data(
  primaryType: "PermitTransferFrom",
  structs: {
    "PermitTransferFrom": {
      "permitted": "TokenPermissions",
      "spender": "address",
      "nonce": "uint256",
      "deadline": "uint256",
    },
    "TokenPermissions": tokenPermissionsFields,
  },
  message: {
    "permitted": {"token": weth, "amount": amount},
    "spender": spender,
    "nonce": "11",
    "deadline": "1791460959",
  },
);

Map<String, dynamic> permitBatchTransferFrom() => permit2Data(
  primaryType: "PermitBatchTransferFrom",
  structs: {
    "PermitBatchTransferFrom": {
      "permitted": "TokenPermissions[]",
      "spender": "address",
      "nonce": "uint256",
      "deadline": "uint256",
    },
    "TokenPermissions": tokenPermissionsFields,
  },
  message: {
    "permitted": [
      {"token": weth, "amount": "2000000000000000000"},
      {"token": usdt, "amount": "75000000"},
    ],
    "spender": spender,
    "nonce": "12",
    "deadline": "1791460959",
  },
);

Map<String, dynamic> orderInfo(String reactor) => {
  "reactor": reactor,
  "swapper": wallet,
  "nonce": "1993350",
  "deadline": "1791460000",
  "additionalValidationContract": zeroAddress,
  "additionalValidationData": "0x",
};

Map<String, dynamic> witnessOrder({
  required String witnessType,
  required Map<String, Map<String, String>> structs,
  required Map<String, dynamic> witness,
  required String spender,
  String verifyingContract = permit2,
}) => permit2Data(
  primaryType: "PermitWitnessTransferFrom",
  structs: {
    "PermitWitnessTransferFrom": {
      "permitted": "TokenPermissions",
      "spender": "address",
      "nonce": "uint256",
      "deadline": "uint256",
      "witness": witnessType,
    },
    "TokenPermissions": tokenPermissionsFields,
    "OrderInfo": orderInfoFields,
    ...structs,
  },
  verifyingContract: verifyingContract,
  message: {
    "permitted": {"token": weth, "amount": "40000000000000000000"},
    "spender": spender,
    "nonce": "1993351",
    "deadline": "1791460959",
    "witness": witness,
  },
);

Map<String, dynamic> dutchOutput({
  required String recipient,
  String token = usdt,
  String startAmount = "101430499832",
  String endAmount = "101329069331",
}) => {"token": token, "startAmount": startAmount, "endAmount": endAmount, "recipient": recipient};

Map<String, dynamic> feeOutput() =>
    dutchOutput(recipient: feeRecipient, startAmount: "254000000", endAmount: "253322673");

Map<String, dynamic> v2DutchOrder({
  required List<Map<String, dynamic>> outputs,
  String reactor = v2DutchReactor,
  String? spender,
  String verifyingContract = permit2,
}) => witnessOrder(
  witnessType: "V2DutchOrder",
  structs: {
    "V2DutchOrder": {
      "info": "OrderInfo",
      "cosigner": "address",
      "baseInputToken": "address",
      "baseInputStartAmount": "uint256",
      "baseInputEndAmount": "uint256",
      "baseOutputs": "DutchOutput[]",
    },
    "DutchOutput": dutchOutputFields,
  },
  spender: spender ?? reactor,
  verifyingContract: verifyingContract,
  witness: {
    "info": orderInfo(reactor),
    "cosigner": cosigner,
    "baseInputToken": weth,
    "baseInputStartAmount": "39000000000000000000",
    "baseInputEndAmount": "41000000000000000000",
    "baseOutputs": outputs,
  },
);

Map<String, dynamic> exclusiveDutchOrder({required List<Map<String, dynamic>> outputs}) =>
    witnessOrder(
      witnessType: "ExclusiveDutchOrder",
      structs: {
        "ExclusiveDutchOrder": {
          "info": "OrderInfo",
          "decayStartTime": "uint256",
          "decayEndTime": "uint256",
          "exclusiveFiller": "address",
          "exclusivityOverrideBps": "uint256",
          "inputToken": "address",
          "inputStartAmount": "uint256",
          "inputEndAmount": "uint256",
          "outputs": "DutchOutput[]",
        },
        "DutchOutput": dutchOutputFields,
      },
      spender: exclusiveDutchReactor,
      witness: {
        "info": orderInfo(exclusiveDutchReactor),
        "decayStartTime": "1791459000",
        "decayEndTime": "1791459060",
        "exclusiveFiller": zeroAddress,
        "exclusivityOverrideBps": "100",
        "inputToken": weth,
        "inputStartAmount": "39000000000000000000",
        "inputEndAmount": "41000000000000000000",
        "outputs": outputs,
      },
    );

Map<String, dynamic> v3DutchOrder() => witnessOrder(
  witnessType: "V3DutchOrder",
  structs: {
    "V3DutchOrder": {
      "info": "OrderInfo",
      "cosigner": "address",
      "startingBaseFee": "uint256",
      "baseInput": "V3DutchInput",
      "baseOutputs": "V3DutchOutput[]",
    },
    "V3DutchInput": {
      "token": "address",
      "startAmount": "uint256",
      "curve": "NonlinearDutchDecay",
      "maxAmount": "uint256",
      "adjustmentPerGweiBaseFee": "uint256",
    },
    "V3DutchOutput": {
      "token": "address",
      "startAmount": "uint256",
      "curve": "NonlinearDutchDecay",
      "recipient": "address",
      "minAmount": "uint256",
      "adjustmentPerGweiBaseFee": "uint256",
    },
    "NonlinearDutchDecay": {"relativeBlocks": "uint256", "relativeAmounts": "int256[]"},
  },
  spender: v3DutchReactor,
  witness: {
    "info": orderInfo(v3DutchReactor),
    "cosigner": cosigner,
    "startingBaseFee": "12000000000",
    "baseInput": {
      "token": weth,
      "startAmount": "39000000000000000000",
      "curve": {"relativeBlocks": "0", "relativeAmounts": <String>[]},
      "maxAmount": "41000000000000000000",
      "adjustmentPerGweiBaseFee": "0",
    },
    "baseOutputs": [
      {
        "token": usdt,
        "startAmount": "101430499832",
        "curve": {
          "relativeBlocks": "4",
          "relativeAmounts": ["-5000000", "7000000"],
        },
        "recipient": wallet,
        "minAmount": "100900000000",
        "adjustmentPerGweiBaseFee": "0",
      },
    ],
  },
);

Map<String, dynamic> priorityOrder() => witnessOrder(
  witnessType: "PriorityOrder",
  structs: {
    "PriorityOrder": {
      "info": "OrderInfo",
      "cosigner": "address",
      "auctionStartBlock": "uint256",
      "baselinePriorityFeeWei": "uint256",
      "input": "PriorityInput",
      "outputs": "PriorityOutput[]",
    },
    "PriorityInput": {"token": "address", "amount": "uint256", "mpsPerPriorityFeeWei": "uint256"},
    "PriorityOutput": {
      "token": "address",
      "amount": "uint256",
      "mpsPerPriorityFeeWei": "uint256",
      "recipient": "address",
    },
  },
  spender: priorityReactor,
  witness: {
    "info": orderInfo(priorityReactor),
    "cosigner": cosigner,
    "auctionStartBlock": "25600000",
    "baselinePriorityFeeWei": "0",
    "input": {"token": weth, "amount": "38000000000000000000", "mpsPerPriorityFeeWei": "0"},
    "outputs": [
      {"token": usdt, "amount": "100700000000", "mpsPerPriorityFeeWei": "1", "recipient": wallet},
    ],
  },
);

Map<String, dynamic> seaportLikeOrder() => typedData(
  primaryType: "Order",
  structs: {
    "Order": {"offerer": "address", "consideration": "Item[]", "terms": "Terms"},
    "Item": {"recipient": "address", "amount": "uint256"},
    "Terms": {"expiry": "uint256", "salt": "bytes32", "note": "string", "strict": "bool"},
  },
  domainFields: tokenDomainFields,
  domain: {"name": "Example dApp", "version": "1.5", "chainId": 1, "verifyingContract": spender},
  message: {
    "offerer": wallet,
    "consideration": [
      {"recipient": stranger, "amount": "12"},
      {"recipient": feeRecipient, "amount": "34"},
    ],
    "terms": {"expiry": 1700000000, "salt": "0x${"ab" * 32}", "note": "gm", "strict": false},
  },
);

Map<String, dynamic> singleField(
  String type,
  dynamic value, {
  Map<String, Map<String, String>> structs = const {},
  String primaryType = "Sample",
}) => typedData(
  primaryType: primaryType,
  structs: {
    primaryType: {"field": type},
    ...structs,
  },
  domainFields: tokenDomainFields,
  domain: {"name": "Sample dApp", "version": "1", "chainId": 1, "verifyingContract": spender},
  message: {"field": value},
);

String messageHash(Map<String, dynamic> payload) => hex.encode(
  TypedDataUtil.hashMessage(jsonData: jsonEncode(payload), version: TypedDataVersion.V4),
);

void main() {
  setUpAll(() {
    S.current = const S();
  });

  final tokens = {
    usdc.toLowerCase(): Erc20Token(
      name: "USD Coin",
      symbol: "USDC",
      contractAddress: usdc,
      decimal: 6,
    ),
    dai.toLowerCase(): Erc20Token(
      name: "Dai Stablecoin",
      symbol: "DAI",
      contractAddress: dai,
      decimal: 18,
    ),
    weth.toLowerCase(): Erc20Token(
      name: "Wrapped Ether",
      symbol: "WETH",
      contractAddress: weth,
      decimal: 18,
    ),
    usdt.toLowerCase(): Erc20Token(
      name: "Tether USD",
      symbol: "USDT",
      contractAddress: usdt,
      decimal: 6,
    ),
  };
  final resolver = StubErc20Resolver(tokens);
  final decoder = TypedDataDecoder(resolver);
  final uint160Max = "${(BigInt.one << 160) - BigInt.one}";
  final uint256Max = "${(BigInt.one << 256) - BigInt.one}";

  Future<WCDecodedRequest> decode(Map<String, dynamic> payload, {TypedDataDecoder? using}) =>
      (using ?? decoder).decode(
        jsonEncode(payload),
        walletAddress: wallet.toLowerCase(),
        chainId: sessionChainId,
        nativeSymbol: "ETH",
      );

  String at(int seconds) => resolver.formatTimestamp(BigInt.from(seconds));

  final normalOrder = v2DutchOrder(
    outputs: [
      dutchOutput(recipient: wallet),
      feeOutput(),
    ],
  );
  final legacyMessage = [
    {"type": "string", "name": "greeting", "value": "Hello from a legacy dApp"},
    {"type": "uint32", "name": "deadline", "value": "1700000000"},
  ];

  group("validate", () {
    final signable = <String, Map<String, dynamic>>{
      "EIP-2612 permit": eip2612Permit(),
      "DAI permit": daiPermit(),
      "PermitSingle": permitSingle(),
      "PermitTransferFrom": permitTransferFrom(amount: uint256Max),
      "EIP-2612 permit with the chain id as a hex quantity": eip2612Permit(chainId: "0x1"),
      "Polygon PoS permit, the chain id signed as the salt": polygonPosPermit(
        salt: saltWord(BigInt.from(polygonChainId)),
      ),
      "Hyperliquid ApproveAgent": hyperliquidApproveAgent(),
      "Hyperliquid UsdSend": hyperliquidTransfer("UsdSend"),
      "Hyperliquid Withdraw": hyperliquidTransfer("Withdraw"),
      "typed data with hex, int, negative and alias-typed values": singleField(
        "Numbers",
        {
          "hex": "0x01f4",
          "plain": 500,
          "negative": "-128",
          "selector": "0x095ea7b3",
          "alias": "7",
          "signedAlias": -7,
          r"price$usd": "3",
        },
        structs: {
          "Numbers": {
            "hex": "uint256",
            "plain": "uint16",
            "negative": "int8",
            "selector": "bytes4",
            "alias": "uint",
            "signedAlias": "int",
            r"price$usd": "uint256",
          },
        },
      ),
    };
    final signableWithArrays = <String, Map<String, dynamic>>{
      "PermitBatch": permitBatch(
        details: [
          {"token": usdc, "amount": "1000000", "expiration": "1700000000", "nonce": "0"},
        ],
      ),
      "PermitBatchTransferFrom": permitBatchTransferFrom(),
      "ExclusiveDutchOrder": exclusiveDutchOrder(outputs: [dutchOutput(recipient: wallet)]),
      "V2DutchOrder": normalOrder,
      "V3DutchOrder": v3DutchOrder(),
      "PriorityOrder": priorityOrder(),
      "nested structs and arrays": seaportLikeOrder(),
      "fixed-size and nested arrays": singleField("uint8[2][]", [
        [1, 2],
        [3, 4],
      ]),
    };

    void expectSignedByWallet(String label, String json, TypedDataVersion version) {
      TypedDataDecoder.validate(json, version);
      final signature = EthSigUtil.signTypedData(
        privateKey: walletKey,
        jsonData: json,
        version: version,
      );
      final signer = EthSigUtil.recoverSignature(
        signature: signature,
        message: TypedDataUtil.hashMessage(jsonData: json, version: version),
      );
      expect(signer, wallet.toLowerCase(), reason: "$label, ${version.name}");
    }

    test("passes every legitimate payload and eth_sig_util signs it as the wallet", () {
      for (final payload in signable.entries) {
        expectSignedByWallet(payload.key, jsonEncode(payload.value), TypedDataVersion.V3);
        expectSignedByWallet(payload.key, jsonEncode(payload.value), TypedDataVersion.V4);
      }
      for (final payload in signableWithArrays.entries) {
        expectSignedByWallet(payload.key, jsonEncode(payload.value), TypedDataVersion.V4);
      }
      expectSignedByWallet("legacy message", jsonEncode(legacyMessage), TypedDataVersion.V1);
    });

    test("refuses arrays under V3, where eth_sig_util cannot hash them", () {
      for (final payload in signableWithArrays.entries) {
        expect(
          () => TypedDataDecoder.validate(jsonEncode(payload.value), TypedDataVersion.V3),
          throwsFormatException,
          reason: payload.key,
        );
      }
    });

    test("refuses what eth_sig_util would sign as something other than what is shown", () {
      void expectSignedButRefused(
        Map<String, Map<String, dynamic>> payloads,
        List<TypedDataVersion> versions,
      ) {
        for (final payload in payloads.entries) {
          final json = jsonEncode(payload.value);
          for (final version in versions) {
            final reason = "${payload.key}, ${version.name}";
            expect(
              () => TypedDataUtil.hashMessage(jsonData: json, version: version),
              returnsNormally,
              reason: "eth_sig_util signs: $reason",
            );
            expect(
              () => TypedDataDecoder.validate(json, version),
              throwsFormatException,
              reason: reason,
            );
          }
        }
      }

      final repeatedField = eip2612Permit();
      ((repeatedField["types"] as Map)["Permit"] as List).add({"name": "value", "type": "uint256"});

      final domainAsPrimaryType = eip2612Permit();
      domainAsPrimaryType["primaryType"] = "EIP712Domain";
      domainAsPrimaryType["message"] = domainAsPrimaryType["domain"];

      const permitInOneName = "owner,address spender,uint256 value,uint256 nonce,uint256 deadline";
      final permitInOneFieldName = eip2612Permit();
      (permitInOneFieldName["types"] as Map)["Permit"] = fields({permitInOneName: "address"});
      permitInOneFieldName["message"] = {permitInOneName: wallet};

      const permitSingleInOneName =
          "PermitSingle(PermitDetails details,address spender,uint256 sigDeadline)PermitDetails";
      final permitSingleInOneStructName = permit2Data(
        primaryType: permitSingleInOneName,
        structs: {permitSingleInOneName: permitDetailsFields},
        message: {"token": usdc, "amount": "250000000", "expiration": "1700000000", "nonce": "0"},
      );

      final inner = {"Inner": tokenPermissionsFields};
      expectSignedButRefused(
        {
          "colon primary type with a struct field, hashed without the struct": hyperliquidAction(
            "Send",
            {"permitted": "Inner"},
            {
              "permitted": {"token": usdc, "amount": 1},
            },
            structs: inner,
          ),
          "colon primary type hashed with the struct named like its prefix": hyperliquidAction(
            "UsdSend",
            hyperliquidTransferFields,
            hyperliquidTransfer("UsdSend")["message"] as Map<String, dynamic>,
            structs: {"HyperliquidTransaction": tokenPermissionsFields},
          ),
          "field name spelling out the EIP-2612 fields": permitInOneFieldName,
          "struct name spelling out PermitSingle": permitSingleInOneStructName,
          "bool as the string false": daiPermit(allowed: "false"),
          "bool as the string 0": daiPermit(allowed: "0"),
          "bool as the string true": daiPermit(allowed: "true"),
          "bool as a number": daiPermit(allowed: 2),
          "address in decimal digits": singleField(
            "address",
            "1234567890123456789012345678901234567890",
          ),
          "address shorter than 20 bytes": singleField("address", "0x1234"),
          "integer padded with spaces": singleField("uint256", " 12 "),
          "integer as empty hex": singleField("uint256", "0x"),
          "int8 above its range": singleField("int8", 255),
          "int8 below its range": singleField("int8", "-129"),
          "bytes4 holding 32 bytes": singleField("bytes4", "0x${"ab" * 32}"),
          "bytes32 holding 40 bytes": singleField("bytes32", "0x${"ab" * 40}"),
          "bytes32 as text": singleField("bytes32", "hello"),
          "bytes as text": singleField("bytes", "hello"),
          "type that only looks like bytesN": singleField("bytesfoo", "0xab"),
          "struct left null": singleField("Inner", null, structs: inner),
          "repeated field": repeatedField,
          "EIP712Domain as the primary type": domainAsPrimaryType,
        },
        [TypedDataVersion.V3, TypedDataVersion.V4],
      );

      final withoutNonce = daiPermit();
      (withoutNonce["message"] as Map).remove("nonce");

      final chainIdAsBytes32 = typedData(
        primaryType: "Permit",
        structs: {"Permit": eip2612Fields},
        domainFields: {"name": "string", "chainId": "bytes32", "verifyingContract": "address"},
        domain: {"name": "USD Coin", "chainId": "0x${"00" * 31}01", "verifyingContract": usdc},
        message: eip2612Permit()["message"] as Map<String, dynamic>,
      );
      expectSignedButRefused(
        {
          "field left out": withoutNonce,
          "chain id too large for eth_sig_util": eip2612Permit(
            chainId: "123456789012345678901234567890",
          ),
          "chain id declared as bytes32": chainIdAsBytes32,
        },
        [TypedDataVersion.V3],
      );

      expectSignedButRefused(
        {
          "fixed-size array with an extra element": singleField("Inner[2]", [
            {"token": usdc, "amount": 1},
            {"token": usdt, "amount": 2},
            {"token": weth, "amount": 3},
          ], structs: inner),
          "empty array of an undeclared struct": singleField("Missing[]", <dynamic>[]),
          "null inside a struct array": singleField("Inner[]", [null], structs: inner),
        },
        [TypedDataVersion.V4],
      );
    });

    test("a string bool signs as true and a decimal address as that number", () {
      expect(messageHash(daiPermit(allowed: "false")), messageHash(daiPermit()));
      expect(messageHash(daiPermit(allowed: "0")), messageHash(daiPermit()));
      expect(messageHash(daiPermit(allowed: false)), isNot(messageHash(daiPermit())));
      expect(
        messageHash(singleField("address", "1234567890123456789012345678901234567890")),
        messageHash(singleField("address", "0x00000003a0c92075c0dbf3b8acbc5f96ce3f0ad2")),
      );
    });

    test("a Hyperliquid action signs the EIP-712 digest of its colon type name", () {
      expect(
        messageHash(hyperliquidApproveAgent()),
        "24126a4ea304cadc75931e088afca7151d81184843705684818f30c3982c1158",
      );
    });

    test("a struct name takes one colon between two words and is never a field type", () {
      final malformedNames = ["A:B:C", ":Send", "Send:", "A::B", "A:B "];
      for (final name in malformedNames) {
        expect(
          () => TypedDataDecoder.validate(
            jsonEncode(singleField("uint64", 1, primaryType: name)),
            TypedDataVersion.V4,
          ),
          throwsFormatException,
          reason: name,
        );
      }

      expect(
        () => TypedDataDecoder.validate(
          jsonEncode(
            singleField(
              "Hl:Inner",
              {"token": usdc, "amount": 1},
              structs: {"Hl:Inner": tokenPermissionsFields},
            ),
          ),
          TypedDataVersion.V4,
        ),
        throwsFormatException,
      );
    });

    test("refuses what would take the sheet seconds to build", () {
      dynamic nested(int levels) => levels == 0 ? 7 : [nested(levels - 1)];
      Map<String, dynamic> nestedArrays(int levels) =>
          singleField("uint8${"[]" * levels}", nested(levels));
      void validate(Map<String, dynamic> payload) =>
          TypedDataDecoder.validate(jsonEncode(payload), TypedDataVersion.V4);

      expect(() => validate(nestedArrays(31)), returnsNormally);
      expect(() => validate(nestedArrays(32)), throwsFormatException);
      expect(() => validate(nestedArrays(6000)), throwsFormatException);

      expect(() => validate(singleField("uint256", "5".padLeft(80, "0"))), returnsNormally);
      expect(() => validate(singleField("uint256", "5".padLeft(81, "0"))), throwsFormatException);
      expect(() => validate(singleField("uint256", uint256Max)), returnsNormally);
      expect(() => validate(singleField("int256", "${-(BigInt.one << 255)}")), returnsNormally);
    });

    test("refuses payloads that cannot be signed at all", () {
      final withoutNonce = daiPermit();
      (withoutNonce["message"] as Map).remove("nonce");

      final withoutDomainType = eip2612Permit();
      (withoutDomainType["types"] as Map).remove("EIP712Domain");

      final withoutDomain = eip2612Permit();
      withoutDomain.remove("domain");

      final withoutTypes = eip2612Permit();
      withoutTypes.remove("types");

      final undeclaredPrimaryType = eip2612Permit();
      undeclaredPrimaryType["primaryType"] = "Order";

      final extraDomainField = eip2612Permit();
      ((extraDomainField["types"] as Map)["EIP712Domain"] as List).add({
        "name": "owner",
        "type": "address",
      });
      (extraDomainField["domain"] as Map)["owner"] = wallet;

      final undeclaredSalt = eip2612Permit();
      (undeclaredSalt["domain"] as Map)["salt"] = 5;

      final fieldAsText = eip2612Permit();
      (fieldAsText["types"] as Map)["Permit"] = ["owner"];

      final unsignable = <String, Map<String, dynamic>>{
        "integer as odd-length hex": singleField("uint256", "0x1"),
        "integer as a fraction": singleField("uint256", 1.5),
        "uint8 above its range": singleField("uint8", 256),
        "uint256 above its range": singleField("uint256", "${BigInt.one << 256}"),
        "negative uint": singleField("uint8", "-1"),
        "address without 0x": singleField("address", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
        "bytes as odd-length hex": singleField("bytes", "0x123"),
        "string as a number": singleField("string", 5),
        "struct as a string": singleField(
          "Inner",
          "0x",
          structs: {"Inner": tokenPermissionsFields},
        ),
        "array as an object": singleField("uint256[]", {"0": 1}),
        "undeclared struct type": singleField("Missing", {"token": usdc}),
        "field left out": withoutNonce,
        "EIP712Domain not declared": withoutDomainType,
        "domain left out": withoutDomain,
        "types left out": withoutTypes,
        "primary type not declared": undeclaredPrimaryType,
        "domain field eth_sig_util does not know": extraDomainField,
        "undeclared domain key eth_sig_util still reads": undeclaredSalt,
        "declared field that is not an object": fieldAsText,
      };

      for (final payload in unsignable.entries) {
        expect(
          () => TypedDataDecoder.validate(jsonEncode(payload.value), TypedDataVersion.V4),
          throwsFormatException,
          reason: payload.key,
        );
      }

      for (final data in ["not json at all", "[]", "\"text\"", jsonEncode(legacyMessage)]) {
        expect(
          () => TypedDataDecoder.validate(data, TypedDataVersion.V4),
          throwsFormatException,
          reason: data,
        );
      }
    });

    test("refuses legacy V1 entries eth_sig_util misreads or cannot sign", () {
      final misread = {
        "negative uint": {"type": "uint8", "name": "amount", "value": -1},
        "int8 above its range": {"type": "int8", "name": "amount", "value": 255},
        "empty array": {"type": "uint256[]", "name": "amounts", "value": <dynamic>[]},
      };
      for (final entry in misread.entries) {
        final json = jsonEncode([entry.value]);
        expect(
          () => TypedDataUtil.hashMessage(jsonData: json, version: TypedDataVersion.V1),
          returnsNormally,
          reason: "eth_sig_util signs: ${entry.key}",
        );
        expect(
          () => TypedDataDecoder.validate(json, TypedDataVersion.V1),
          throwsFormatException,
          reason: entry.key,
        );
      }

      final unsignable = {
        "address": {"type": "address", "name": "wallet", "value": wallet},
        "bool": {"type": "bool", "name": "accepted", "value": true},
        "string as a number": {"type": "string", "name": "greeting", "value": 5},
        "entry without a name": {"type": "string", "value": "gm"},
      };
      for (final entry in unsignable.entries) {
        expect(
          () => TypedDataDecoder.validate(jsonEncode([entry.value]), TypedDataVersion.V1),
          throwsFormatException,
          reason: entry.key,
        );
      }

      expect(() => TypedDataDecoder.validate("[]", TypedDataVersion.V1), throwsFormatException);
      expect(
        () => TypedDataDecoder.validate(jsonEncode(eip2612Permit()), TypedDataVersion.V1),
        throwsFormatException,
      );
    });
  });

  group("domainChainId", () {
    test("reads a number, a decimal string and a hex string as eth_sig_util signs them", () {
      final asRead = {8453: 8453, "137": 137, "0xa4b1": 42161, "0x1": 1};
      for (final chainId in asRead.entries) {
        final permit = eip2612Permit(chainId: chainId.key);
        expect(TypedDataDecoder.domainChainId(jsonEncode(permit)), chainId.value);
        expect(messageHash(permit), messageHash(eip2612Permit(chainId: chainId.value)));
      }
    });

    test("the Polygon PoS fixture is the domain bridged USDC verifies on chain", () {
      final permit = TypedMessage.fromJson(
        polygonPosPermit(salt: saltWord(BigInt.from(polygonChainId))),
      );
      expect(
        hex.encode(TypedDataUtil.hashStruct("EIP712Domain", permit.domain, permit.types, "V4")),
        "294369e003769a2d4d625e8a9ebebffa09ff70dd7c708497d8b56d2c2d199a19",
      );
    });

    test("reads the salt as the chain id when the domain declares no chainId", () {
      int? signedChainId(Map<String, dynamic> payload) =>
          TypedDataDecoder.domainChainId(jsonEncode(payload));
      final polygonSalt = saltWord(BigInt.from(polygonChainId));
      final largestChainId = (BigInt.one << 63) - BigInt.one;

      expect(signedChainId(polygonPosPermit(salt: polygonSalt)), polygonChainId);
      expect(
        signedChainId(polygonPosPermit(salt: saltWord(largestChainId))),
        largestChainId.toInt(),
      );
      expect(signedChainId(polygonPosPermit(salt: polygonSalt, chainId: 8453)), 8453);

      final undeclaredChainId = polygonPosPermit(salt: polygonSalt);
      (undeclaredChainId["domain"] as Map)["chainId"] = 56;
      expect(signedChainId(undeclaredChainId), polygonChainId);
    });

    test("is null when the domain signs no chain id", () {
      final notChainIds = {
        "zero salt": saltWord(BigInt.zero),
        "salt one above the largest chain id": saltWord(BigInt.one << 63),
        "random salt": "0x${"ab" * 32}",
      };
      for (final salt in notChainIds.entries) {
        expect(
          TypedDataDecoder.domainChainId(jsonEncode(polygonPosPermit(salt: salt.value))),
          isNull,
          reason: salt.key,
        );
      }

      final withoutChainId = eip2612Permit();
      ((withoutChainId["types"] as Map)["EIP712Domain"] as List).removeWhere(
        (field) => (field as Map)["name"] == "chainId",
      );
      expect(TypedDataDecoder.domainChainId(jsonEncode(withoutChainId)), isNull);
      expect(TypedDataDecoder.domainChainId(jsonEncode(legacyMessage)), isNull);
    });
  });

  group("token permits", () {
    test("the fixtures declare the Permit types the tokens verify on chain", () {
      String typeHash(Map<String, String> permitFields) => hex.encode(
        TypedDataUtil.hashType("Permit", {
          "Permit": [
            for (final field in permitFields.entries)
              TypedDataField(name: field.key, type: field.value),
          ],
        }),
      );

      expect(
        typeHash(eip2612Fields),
        "6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9",
      );
      expect(
        typeHash(daiPermitFields),
        "ea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb",
      );
    });

    test("an EIP-2612 permit shows the token, its contract, the amount and the spender", () async {
      final decoded = await decode(eip2612Permit());
      expect(decoded.actionTitle, S.current.wc_action_permit);
      expect(decoded.actionSubtitle, "USD Coin");
      expect(rowLines(decoded.rows), [
        "${S.current.wc_token}: USD Coin (USDC)",
        "${S.current.wc_contract}: $usdc",
        "${S.current.wc_amount}: 500 USDC",
        "${S.current.wc_approved_spender}: $spender",
        "${S.current.wc_signature_valid_until}: ${at(1791460959)}",
        "${S.current.chain_id}: 1",
      ]);
      expect(decoded.rows[1].kind, WCDecodedRowKind.address);
      expect(decoded.warnings, [S.current.wc_warning_permit_review]);
    });

    test("an EIP-2612 permit for the whole uint256 range warns that it is unlimited", () async {
      final decoded = await decode(eip2612Permit(value: uint256Max));
      expect(
        rowLines(decoded.rows),
        contains("${S.current.wc_amount}: ${S.current.wc_unlimited} USDC"),
      );
      expect(decoded.warnings, [
        S.current.wc_warning_permit_review,
        S.current.wc_warning_unlimited_approval,
      ]);
    });

    test("an EIP-2612 permit for a token outside the wallet warns about the token", () async {
      final permit = eip2612Permit();
      (permit["domain"] as Map)["verifyingContract"] = unlistedToken;

      final decoded = await decode(permit);
      expect(rowLines(decoded.rows), contains("${S.current.wc_contract}: $unlistedToken"));
      expect(decoded.warnings, [
        S.current.wc_warning_permit_review,
        S.current.wc_warning_unknown_token,
      ]);
    });

    test("a deadline past the year 9999 reads as never", () async {
      const lastSecondOf9999 = 253402300799;
      String validUntil(WCDecodedRequest decoded) =>
          decoded.rows.firstWhere((row) => row.label == S.current.wc_signature_valid_until).value;

      expect(validUntil(await decode(eip2612Permit(deadline: uint256Max))), S.current.wc_never);
      expect(
        validUntil(await decode(eip2612Permit(deadline: "${lastSecondOf9999 + 1}"))),
        S.current.wc_never,
      );
      expect(
        validUntil(await decode(eip2612Permit(deadline: "$lastSecondOf9999"))),
        at(lastSecondOf9999),
      );
      expect(validUntil(await decode(daiPermit(expiry: uint256Max))), S.current.wc_never);
    });

    test("a Polygon PoS permit shows the chain its salt signs, not the salt", () async {
      final decoded = await decode(polygonPosPermit(salt: saltWord(BigInt.from(polygonChainId))));
      expect(decoded.actionTitle, S.current.wc_action_permit);
      expect(decoded.actionSubtitle, "USD Coin (PoS)");
      expect(rowLines(decoded.rows), [
        "${S.current.wc_token}: ${shortAddress(polygonUsdc)}",
        "${S.current.wc_contract}: $polygonUsdc",
        "${S.current.wc_amount}: 500000000 ${shortAddress(polygonUsdc)}",
        "${S.current.wc_approved_spender}: $spender",
        "${S.current.wc_signature_valid_until}: ${at(1791460959)}",
        "${S.current.chain_id}: $polygonChainId",
      ]);
    });

    test("a salt that is not the chain id is shown as the salt", () async {
      final randomSalt = "0x${"ab" * 32}";
      final withoutChain = await decode(polygonPosPermit(salt: randomSalt));
      expect(rowLines(withoutChain.rows).last, "salt: $randomSalt");
      expect(withoutChain.rows.any((row) => row.label == S.current.chain_id), isFalse);

      final polygonSalt = saltWord(BigInt.from(polygonChainId));
      final withChainId = await decode(polygonPosPermit(salt: polygonSalt, chainId: 8453));
      expect(rowLines(withChainId.rows).skip(5), [
        "${S.current.chain_id}: 8453",
        "salt: $polygonSalt",
      ]);
    });

    test("a DAI permit with allowed true is unlimited and expiry 0 never expires", () async {
      final decoded = await decode(daiPermit());
      expect(decoded.actionTitle, S.current.wc_action_permit);
      expect(decoded.actionSubtitle, "Dai Stablecoin");
      expect(rowLines(decoded.rows), [
        "${S.current.wc_token}: Dai Stablecoin (DAI)",
        "${S.current.wc_contract}: $dai",
        "${S.current.wc_amount}: ${S.current.wc_unlimited} DAI",
        "${S.current.wc_approved_spender}: $spender",
        "${S.current.wc_signature_valid_until}: ${S.current.wc_never}",
        "${S.current.chain_id}: 1",
      ]);
      expect(decoded.warnings, [
        S.current.wc_warning_permit_review,
        S.current.wc_warning_unlimited_approval,
      ]);
    });

    test("a DAI permit with allowed false is a revoke that expires when it says", () async {
      final decoded = await decode(daiPermit(allowed: false, expiry: "1791460959"));
      expect(decoded.actionTitle, S.current.wc_action_revoke_approval);
      expect(rowLines(decoded.rows), [
        "${S.current.wc_token}: Dai Stablecoin (DAI)",
        "${S.current.wc_contract}: $dai",
        "${S.current.wc_amount}: 0 DAI",
        "${S.current.wc_approved_spender}: $spender",
        "${S.current.wc_signature_valid_until}: ${at(1791460959)}",
        "${S.current.chain_id}: 1",
      ]);
      expect(decoded.warnings, [S.current.wc_warning_permit_review]);
    });

    test("allowed false on a contract that is not a listed token is not called a revoke", () async {
      final unlisted = TypedDataDecoder(
        StubErc20Resolver(tokens, known: tokens.keys.toSet()..remove(dai.toLowerCase())),
      );

      final decoded = await decode(daiPermit(allowed: false), using: unlisted);
      expect(decoded.actionTitle, S.current.wc_action_permit);
      expect(rowValue(decoded.rows, S.current.wc_amount), "0 DAI");
      expect(decoded.warnings, [
        S.current.wc_warning_permit_review,
        S.current.wc_warning_unknown_token,
      ]);

      final granted = await decode(daiPermit(), using: unlisted);
      expect(granted.actionTitle, S.current.wc_action_permit);
    });

    test(
      "a DAI permit carrying an undeclared value and deadline still reads as unlimited",
      () async {
        final attack = daiPermit();
        (attack["message"] as Map)["value"] = "1";
        (attack["message"] as Map)["deadline"] = "1794614400";
        expect(messageHash(attack), messageHash(daiPermit()));

        final decoded = await decode(attack);
        expect(rowLines(decoded.rows), rowLines((await decode(daiPermit())).rows));
        expect(
          rowLines(decoded.rows),
          contains("${S.current.wc_amount}: ${S.current.wc_unlimited} DAI"),
        );
        expect(
          rowLines(decoded.rows),
          contains("${S.current.wc_signature_valid_until}: ${S.current.wc_never}"),
        );
        expect(decoded.warnings, contains(S.current.wc_warning_unlimited_approval));
        expect(decoded.rawFallback, isNot(contains("1794614400")));
      },
    );

    test("a Permit struct that is neither EIP-2612 nor DAI gets the generic view", () async {
      final permit = eip2612Permit();
      ((permit["types"] as Map)["Permit"] as List).removeLast();

      final decoded = await decode(permit);
      expect(decoded.actionTitle, S.current.wc_action_permit);
      expect(decoded.actionSubtitle, "Permit");
      expect(rowLines(decoded.rows), [
        "${S.current.wc_domain}: USD Coin",
        "${S.current.chain_id}: 1",
        "${S.current.wc_verifying_contract}: $usdc",
        "${S.current.wc_primary_type}: Permit",
        "owner: $wallet",
        "spender: $spender",
        "value: 500000000",
        "nonce: 7",
      ]);
      expect(decoded.warnings, [
        S.current.wc_warning_permit_review,
        S.current.wc_warning_typed_data_unrecognized,
      ]);
    });
  });

  group("Permit2", () {
    test("PermitSingle shows the token, its contract, both deadlines and the spender", () async {
      final decoded = await decode(permitSingle());
      expect(decoded.actionTitle, S.current.wc_action_permit2);
      expect(decoded.actionSubtitle, "Permit2");
      expect(rowLines(decoded.rows), [
        "${S.current.wc_token}: USD Coin (USDC)",
        "${S.current.wc_contract}: $usdc",
        "${S.current.wc_amount}: 250 USDC",
        "${S.current.wc_expiration}: ${at(1700000000)}",
        "${S.current.wc_approved_spender}: $spender",
        "${S.current.wc_signature_valid_until}: ${at(1700003600)}",
        "${S.current.chain_id}: 1",
        "${S.current.wc_verifying_contract}: $permit2",
      ]);
      expect(decoded.warnings, [S.current.wc_warning_permit_review]);
    });

    test("PermitSingle with the largest expiration and deadline never expires", () async {
      final uint48Max = "${(BigInt.one << 48) - BigInt.one}";
      final decoded = await decode(permitSingle(expiration: uint48Max, sigDeadline: uint256Max));
      expect(
        rowLines(decoded.rows),
        containsAllInOrder([
          "${S.current.wc_expiration}: ${S.current.wc_never}",
          "${S.current.wc_signature_valid_until}: ${S.current.wc_never}",
        ]),
      );
    });

    test("PermitSingle for the uint160 maximum warns that it is unlimited", () async {
      final decoded = await decode(permitSingle(amount: uint160Max));
      expect(
        rowLines(decoded.rows),
        contains("${S.current.wc_amount}: ${S.current.wc_unlimited} USDC"),
      );
      expect(decoded.warnings, [
        S.current.wc_warning_permit_review,
        S.current.wc_warning_unlimited_approval,
      ]);
    });

    test("PermitSingle signed for another contract is not presented as Permit2", () async {
      final decoded = await decode(permitSingle(verifyingContract: stranger));
      expect(decoded.actionTitle, S.current.wc_action_permit);
      expect(decoded.actionSubtitle, "PermitSingle");
      expect(rowLines(decoded.rows), contains("${S.current.wc_verifying_contract}: $stranger"));
      expect(rowLines(decoded.rows), contains("details.amount: 250000000"));
      expect(decoded.warnings, [
        S.current.wc_warning_permit_review,
        S.current.wc_warning_typed_data_unrecognized,
      ]);
    });

    test("PermitBatch lists every token and warns about the one outside the wallet", () async {
      final decoded = await decode(
        permitBatch(
          details: [
            {"token": usdc, "amount": "1000000", "expiration": "1700000000", "nonce": "0"},
            {"token": unlistedToken, "amount": "42", "expiration": "1700090000", "nonce": "1"},
          ],
        ),
      );
      expect(decoded.actionTitle, S.current.wc_action_permit2);
      expect(rowLines(decoded.rows), [
        "${S.current.wc_token}: USD Coin (USDC)",
        "${S.current.wc_contract}: $usdc",
        "${S.current.wc_amount}: 1 USDC",
        "${S.current.wc_expiration}: ${at(1700000000)}",
        "${S.current.wc_token}: ${shortAddress(unlistedToken)}",
        "${S.current.wc_contract}: $unlistedToken",
        "${S.current.wc_amount}: 42 ${shortAddress(unlistedToken)}",
        "${S.current.wc_expiration}: ${at(1700090000)}",
        "${S.current.wc_approved_spender}: $spender",
        "${S.current.wc_signature_valid_until}: ${at(1700003600)}",
        "${S.current.chain_id}: 1",
        "${S.current.wc_verifying_contract}: $permit2",
      ]);
      expect(decoded.warnings, [
        S.current.wc_warning_permit_review,
        S.current.wc_warning_unknown_token,
      ]);
    });

    test("PermitBatch with more tokens than the sheet lists gets the generic view", () async {
      final decoded = await decode(
        permitBatch(
          details: [
            for (int nonce = 0; nonce < 17; nonce++)
              {"token": usdc, "amount": "1000000", "expiration": "1700000000", "nonce": nonce},
          ],
        ),
      );
      expect(decoded.actionTitle, S.current.wc_action_permit);
      expect(decoded.warnings, contains(S.current.wc_warning_typed_data_unrecognized));
    });

    test("PermitTransferFrom for the whole uint256 range reads as unlimited", () async {
      final decoded = await decode(permitTransferFrom(amount: uint256Max));
      expect(decoded.actionTitle, S.current.wc_action_permit2);
      expect(decoded.actionSubtitle, "Permit2");
      expect(rowLines(decoded.rows), [
        "${S.current.wc_token}: Wrapped Ether (WETH)",
        "${S.current.wc_contract}: $weth",
        "${S.current.wc_amount}: ${S.current.wc_unlimited} WETH",
        "${S.current.wc_approved_spender}: $spender",
        "${S.current.wc_signature_valid_until}: ${at(1791460959)}",
        "${S.current.chain_id}: 1",
        "${S.current.wc_verifying_contract}: $permit2",
      ]);
      expect(decoded.warnings, [
        S.current.wc_warning_permit_review,
        S.current.wc_warning_unlimited_approval,
      ]);
    });

    test("PermitBatchTransferFrom lists every token with its amount", () async {
      final decoded = await decode(permitBatchTransferFrom());
      expect(decoded.actionTitle, S.current.wc_action_permit2);
      expect(rowLines(decoded.rows), [
        "${S.current.wc_token}: Wrapped Ether (WETH)",
        "${S.current.wc_contract}: $weth",
        "${S.current.wc_amount}: 2 WETH",
        "${S.current.wc_token}: Tether USD (USDT)",
        "${S.current.wc_contract}: $usdt",
        "${S.current.wc_amount}: 75 USDT",
        "${S.current.wc_approved_spender}: $spender",
        "${S.current.wc_signature_valid_until}: ${at(1791460959)}",
        "${S.current.chain_id}: 1",
        "${S.current.wc_verifying_contract}: $permit2",
      ]);
      expect(decoded.warnings, [S.current.wc_warning_permit_review]);
    });
  });

  group("UniswapX", () {
    test("an order with a fee output reads as a swap and carries no extra warning", () async {
      final decoded = await decode(normalOrder);
      expect(decoded.actionTitle, S.current.wc_action_swap);
      expect(decoded.actionSubtitle, S.current.wc_via("UniswapX"));
      expect(rowLines(decoded.rows), [
        "${S.current.wc_swap_from_max}: 40 WETH",
        "${S.current.wc_token}: $weth",
        "${S.current.wc_swap_to_min}: 101329.069331 USDT",
        "${S.current.wc_token}: $usdt",
        "${S.current.wc_amount}: 253.322673 USDT",
        "${S.current.wc_token}: $usdt",
        "${S.current.wc_recipient}: $feeRecipient",
        "${S.current.wc_signature_valid_until}: ${at(1791460959)}",
      ]);
      expect(decoded.rows[1].kind, WCDecodedRowKind.address);
      expect(
        [for (final row in decoded.detailRows) "${row.label}: ${row.value}"],
        [
          "${S.current.wc_approved_spender}: ${v2DutchReactor.toLowerCase()}",
          "${S.current.chain_id}: 1",
          "${S.current.wc_verifying_contract}: $permit2",
        ],
      );
      expect(decoded.warnings, [S.current.wc_warning_permit_review]);
    });

    test("an order through any reactor of the chains Cake serves reads as a swap", () async {
      const sdkReactors = {
        "Dutch_V3 on mainnet": "0x0000000015757c461808EA25Eb309638B62681cf",
        "Dutch_V3 on Polygon": "0x00000000bAB6E234db8AD638B6A6395b7c499Bc4",
        "Dutch_V3 on BSC": "0x00000000a55e50C71b70Db3C8B58749cd1E18eB2",
        "Dutch_V3 on Robinhood Chain": "0x000000007A1C8e570011EeDF86A2A35593013cBA",
        "Priority on Base": "0x000000001Ec5656dcdB24D90DFa42742738De729",
        "Dutch_V2 on Arbitrum": "0x1bd1aAdc9E230626C44a139d7E70d842749351eb",
      };
      for (final reactor in sdkReactors.entries) {
        final decoded = await decode(
          v2DutchOrder(
            outputs: [dutchOutput(recipient: wallet)],
            reactor: reactor.value,
          ),
        );
        expect(decoded.actionTitle, S.current.wc_action_swap, reason: reactor.key);
        expect(decoded.warnings, [S.current.wc_warning_permit_review], reason: reactor.key);
      }
    });

    test("an order with the largest deadline never expires", () async {
      final order = v2DutchOrder(outputs: [dutchOutput(recipient: wallet)]);
      (order["message"] as Map)["deadline"] = uint256Max;

      final decoded = await decode(order);
      expect(decoded.actionTitle, S.current.wc_action_swap);
      expect(
        rowLines(decoded.rows).last,
        "${S.current.wc_signature_valid_until}: ${S.current.wc_never}",
      );
    });

    test("a native output reads as the chain's coin, not an unknown token", () async {
      final decoded = await decode(
        v2DutchOrder(
          outputs: [
            dutchOutput(
              recipient: wallet,
              token: "0x0000000000000000000000000000000000000000",
              endAmount: "1500000000000000000",
            ),
          ],
        ),
      );
      expect(rowLines(decoded.rows), [
        "${S.current.wc_swap_from_max}: 40 WETH",
        "${S.current.wc_token}: $weth",
        "${S.current.wc_swap_to_min}: 1.5 ETH",
        "${S.current.wc_signature_valid_until}: ${at(1791460959)}",
      ]);
      expect(decoded.warnings, [S.current.wc_warning_permit_review]);
    });

    test("an order paying only a third party warns that the funds go elsewhere", () async {
      final decoded = await decode(v2DutchOrder(outputs: [dutchOutput(recipient: stranger)]));
      expect(decoded.actionTitle, S.current.wc_action_swap);
      expect(rowLines(decoded.rows), [
        "${S.current.wc_swap_from_max}: 40 WETH",
        "${S.current.wc_token}: $weth",
        "${S.current.wc_amount}: 101329.069331 USDT",
        "${S.current.wc_token}: $usdt",
        "${S.current.wc_recipient}: $stranger",
        "${S.current.wc_signature_valid_until}: ${at(1791460959)}",
      ]);
      expect(decoded.warnings, [
        S.current.wc_warning_permit_review,
        S.current.wc_warning_recipient_not_you,
      ]);
    });

    test("an order paying dust to the wallet still shows the rest going elsewhere", () async {
      final decoded = await decode(
        v2DutchOrder(
          outputs: [
            dutchOutput(recipient: wallet, endAmount: "1"),
            dutchOutput(recipient: stranger, endAmount: "101329069330"),
          ],
        ),
      );
      expect(rowLines(decoded.rows), [
        "${S.current.wc_swap_from_max}: 40 WETH",
        "${S.current.wc_token}: $weth",
        "${S.current.wc_swap_to_min}: 0.000001 USDT",
        "${S.current.wc_token}: $usdt",
        "${S.current.wc_amount}: 101329.06933 USDT",
        "${S.current.wc_token}: $usdt",
        "${S.current.wc_recipient}: $stranger",
        "${S.current.wc_signature_valid_until}: ${at(1791460959)}",
      ]);
      expect(decoded.warnings, [S.current.wc_warning_permit_review]);
    });

    test("an ExclusiveDutchOrder with undeclared baseOutputs shows the outputs it signs", () async {
      final signedOrder = exclusiveDutchOrder(
        outputs: [dutchOutput(recipient: stranger, endAmount: "1")],
      );
      final attack = exclusiveDutchOrder(
        outputs: [dutchOutput(recipient: stranger, endAmount: "1")],
      );
      ((attack["message"] as Map)["witness"] as Map)["baseOutputs"] = [
        dutchOutput(recipient: wallet, token: weth, endAmount: "5000000000000000000"),
      ];
      expect(messageHash(attack), messageHash(signedOrder));

      final decoded = await decode(attack);
      expect(rowLines(decoded.rows), [
        "${S.current.wc_swap_from_max}: 40 WETH",
        "${S.current.wc_token}: $weth",
        "${S.current.wc_amount}: 0.000001 USDT",
        "${S.current.wc_token}: $usdt",
        "${S.current.wc_recipient}: $stranger",
        "${S.current.wc_signature_valid_until}: ${at(1791460959)}",
      ]);
      expect(decoded.warnings, contains(S.current.wc_warning_recipient_not_you));
      expect(decoded.rawFallback, isNot(contains("5000000000000000000")));
    });

    test(
      "a V2DutchOrder output with an undeclared minAmount shows the endAmount it signs",
      () async {
        final attack = v2DutchOrder(
          outputs: [dutchOutput(recipient: wallet, endAmount: "1")],
        );
        final outputs = ((attack["message"] as Map)["witness"] as Map)["baseOutputs"] as List;
        (outputs.single as Map)["minAmount"] = "101329069331";
        expect(
          messageHash(attack),
          messageHash(
            v2DutchOrder(
              outputs: [dutchOutput(recipient: wallet, endAmount: "1")],
            ),
          ),
        );

        final decoded = await decode(attack);
        expect(rowLines(decoded.rows), contains("${S.current.wc_swap_to_min}: 0.000001 USDT"));
        expect(decoded.rawFallback, isNot(contains("101329069331")));
      },
    );

    test("an output token outside the wallet warns and shows the token contract", () async {
      final decoded = await decode(
        v2DutchOrder(
          outputs: [dutchOutput(recipient: wallet, token: unlistedToken)],
        ),
      );
      expect(rowLines(decoded.rows), [
        "${S.current.wc_swap_from_max}: 40 WETH",
        "${S.current.wc_token}: $weth",
        "${S.current.wc_swap_to_min}: 101329069331 ${shortAddress(unlistedToken)}",
        "${S.current.wc_token}: $unlistedToken",
        "${S.current.wc_signature_valid_until}: ${at(1791460959)}",
      ]);
      expect(decoded.warnings, [
        S.current.wc_warning_permit_review,
        S.current.wc_warning_unknown_token,
      ]);
    });

    test(
      "a token that only reports a familiar symbol still warns and shows its contract",
      () async {
        final lookalike = TypedDataDecoder(
          StubErc20Resolver({
            ...tokens,
            unlistedToken: Erc20Token(
              name: "Tether USD",
              symbol: "USDT",
              contractAddress: unlistedToken,
              decimal: 6,
            ),
          }, known: tokens.keys.toSet()),
        );

        final decoded = await decode(
          v2DutchOrder(
            outputs: [dutchOutput(recipient: wallet, token: unlistedToken)],
          ),
          using: lookalike,
        );
        expect(
          rowLines(decoded.rows),
          containsAllInOrder([
            "${S.current.wc_swap_to_min}: 101329.069331 USDT",
            "${S.current.wc_token}: $unlistedToken",
          ]),
        );
        expect(decoded.warnings, contains(S.current.wc_warning_unknown_token));
      },
    );

    test("a V3DutchOrder reads its lowest output from minAmount", () async {
      final decoded = await decode(v3DutchOrder());
      expect(decoded.actionTitle, S.current.wc_action_swap);
      expect(rowLines(decoded.rows), [
        "${S.current.wc_swap_from_max}: 40 WETH",
        "${S.current.wc_token}: $weth",
        "${S.current.wc_swap_to_min}: 100900 USDT",
        "${S.current.wc_token}: $usdt",
        "${S.current.wc_signature_valid_until}: ${at(1791460959)}",
      ]);
      expect(decoded.warnings, [S.current.wc_warning_permit_review]);
    });

    test("a PriorityOrder reads its lowest output from amount", () async {
      final decoded = await decode(priorityOrder());
      expect(decoded.actionTitle, S.current.wc_action_swap);
      expect(rowLines(decoded.rows), [
        "${S.current.wc_swap_from_max}: 40 WETH",
        "${S.current.wc_token}: $weth",
        "${S.current.wc_swap_to_min}: 100700 USDT",
        "${S.current.wc_token}: $usdt",
        "${S.current.wc_signature_valid_until}: ${at(1791460959)}",
      ]);
      expect(decoded.warnings, [S.current.wc_warning_permit_review]);
    });

    test(
      "an order is not shown as a swap unless Permit2 and a known reactor are behind it",
      () async {
        final notSwaps = {
          "verifying contract is not Permit2": v2DutchOrder(
            outputs: [dutchOutput(recipient: wallet)],
            verifyingContract: stranger,
          ),
          "reactor is not a UniswapX reactor": v2DutchOrder(
            outputs: [dutchOutput(recipient: wallet)],
            reactor: stranger,
          ),
          "spender differs from the reactor": v2DutchOrder(
            outputs: [dutchOutput(recipient: wallet)],
            spender: stranger,
          ),
          "order has no outputs": v2DutchOrder(outputs: []),
        };

        for (final order in notSwaps.entries) {
          final decoded = await decode(order.value);
          expect(decoded.actionTitle, S.current.wc_action_permit, reason: order.key);
          expect(
            decoded.warnings,
            contains(S.current.wc_warning_typed_data_unrecognized),
            reason: order.key,
          );
          expect(
            decoded.rows.any((row) => row.label == S.current.wc_swap_to_min),
            isFalse,
            reason: order.key,
          );
        }
      },
    );
  });

  group("typed data with no view of its own", () {
    test("warns only for the primary types that put funds at risk", () async {
      const riskTypes = [
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
      ];
      for (final primaryType in riskTypes) {
        final decoded = await decode(singleField("uint8", 5, primaryType: primaryType));
        expect(
          decoded.warnings,
          contains(S.current.wc_warning_typed_data_unrecognized),
          reason: primaryType,
        );
      }

      const otherTypes = [
        "Mail",
        "Orders",
        "order",
        "HyperliquidTransaction:ApproveAgent",
        "HyperliquidTransaction:ApproveBuilderFee",
        "HyperliquidTransaction:UserSetAbstraction",
        "HyperliquidTransaction:UsdClassTransfer",
      ];
      for (final primaryType in otherTypes) {
        final decoded = await decode(singleField("uint8", 5, primaryType: primaryType));
        expect(decoded.actionTitle, S.current.wc_action_sign_typed_data, reason: primaryType);
        expect(decoded.warnings, isEmpty, reason: primaryType);
      }
    });

    test("a Hyperliquid action shows its fields and carries no warning", () async {
      final decoded = await decode(hyperliquidApproveAgent());
      expect(decoded.actionTitle, S.current.wc_action_sign_typed_data);
      expect(decoded.actionSubtitle, "HyperliquidTransaction:ApproveAgent");
      expect(rowLines(decoded.rows), [
        "${S.current.wc_domain}: HyperliquidSignTransaction",
        "${S.current.chain_id}: 42161",
        "${S.current.wc_verifying_contract}: $zeroAddress",
        "${S.current.wc_primary_type}: HyperliquidTransaction:ApproveAgent",
        "hyperliquidChain: Mainnet",
        "agentAddress: $hyperliquidAgent",
        "agentName: ",
        "nonce: 1732600000000",
      ]);
      expect(decoded.warnings, isEmpty);
    });

    test("a Hyperliquid transfer or withdrawal shows its fields under the warning", () async {
      for (final action in ["UsdSend", "Withdraw"]) {
        final decoded = await decode(hyperliquidTransfer(action));
        expect(decoded.actionTitle, S.current.wc_action_sign_typed_data, reason: action);
        expect(rowLines(decoded.rows).skip(3), [
          "${S.current.wc_primary_type}: HyperliquidTransaction:$action",
          "hyperliquidChain: Mainnet",
          "destination: $hyperliquidDestination",
          "amount: 12.5",
          "time: 1732600000001",
        ], reason: action);
        expect(decoded.warnings, [S.current.wc_warning_typed_data_unrecognized], reason: action);
      }
    });

    test("an EIP-3009 transfer shows when it stops being valid and warns like a permit", () async {
      const authorizationFields = {
        "from": "address",
        "to": "address",
        "value": "uint256",
        "validAfter": "uint256",
        "validBefore": "uint256",
        "nonce": "bytes32",
      };
      expect(
        hex.encode(
          TypedDataUtil.hashType("TransferWithAuthorization", {
            "TransferWithAuthorization": [
              for (final field in authorizationFields.entries)
                TypedDataField(name: field.key, type: field.value),
            ],
          }),
        ),
        "7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267",
      );

      final nonce = "0x${"cd" * 32}";
      Map<String, dynamic> authorization(String primaryType) => typedData(
        primaryType: primaryType,
        structs: {primaryType: authorizationFields},
        domainFields: tokenDomainFields,
        domain: {"name": "USD Coin", "version": "2", "chainId": 1, "verifyingContract": usdc},
        message: {
          "from": wallet,
          "to": stranger,
          "value": "25000000000",
          "validAfter": "1732600000",
          "validBefore": "1791460959",
          "nonce": nonce,
        },
      );

      final transfer = await decode(authorization("TransferWithAuthorization"));
      expect(transfer.actionTitle, S.current.wc_action_sign_typed_data);
      expect(rowLines(transfer.rows), [
        "${S.current.wc_domain}: USD Coin",
        "${S.current.chain_id}: 1",
        "${S.current.wc_verifying_contract}: $usdc",
        "${S.current.wc_primary_type}: TransferWithAuthorization",
        "from: $wallet",
        "to: $stranger",
        "value: 25000000000",
        "validAfter: ${at(1732600000)}",
        "validBefore: ${at(1791460959)}",
        "nonce: $nonce",
      ]);
      expect(transfer.warnings, [
        S.current.wc_warning_permit_review,
        S.current.wc_warning_typed_data_unrecognized,
      ]);

      final cancel = await decode(authorization("CancelAuthorization"));
      expect(cancel.warnings, [S.current.wc_warning_permit_review]);
    });

    test("lists 200 fields and says how many more the raw data holds", () async {
      Map<String, dynamic> amounts(int count) =>
          singleField("uint256[]", [for (int i = 0; i < count; i++) 1000 + i]);
      const contextRows = 4;

      final fits = await decode(amounts(199));
      expect(fits.rows.length, contextRows + 200);
      expect(rowLines(fits.rows).last, "field[198]: 1198");

      final overflows = await decode(amounts(250));
      expect(overflows.rows.length, contextRows + 201);
      expect(rowLines(overflows.rows).skip(contextRows + 199), [
        "field[198]: 1198",
        "…: ${S.current.wc_more_rows("51")}",
      ]);
      expect(overflows.rawFallback, contains("1249"));

      final nestedOverflow = await decode(
        singleField(
          "Item[]",
          [
            for (int i = 0; i < 150; i++) {"recipient": stranger, "amount": 1000 + i},
          ],
          structs: {
            "Item": {"recipient": "address", "amount": "uint256"},
          },
        ),
      );
      expect(nestedOverflow.rows.length, contextRows + 201);
      expect(rowLines(nestedOverflow.rows).skip(contextRows + 199), [
        "field[99].recipient: $stranger",
        "…: ${S.current.wc_more_rows("101")}",
      ]);
    });

    test("a field that only reads like an expiry keeps the number it signs", () async {
      final decoded = await decode(
        singleField(
          "Terms",
          {"expiry": uint256Max},
          structs: {
            "Terms": {"expiry": "uint256"},
          },
        ),
      );
      expect(rowLines(decoded.rows).last, "field.expiry: $uint256Max");
    });

    test("is flattened with dotted labels, readable timestamps and a warning", () async {
      final decoded = await decode(seaportLikeOrder());
      expect(decoded.actionTitle, S.current.wc_action_sign_typed_data);
      expect(decoded.actionSubtitle, "Order");
      expect(rowLines(decoded.rows), [
        "${S.current.wc_domain}: Example dApp",
        "${S.current.chain_id}: 1",
        "${S.current.wc_verifying_contract}: $spender",
        "${S.current.wc_primary_type}: Order",
        "offerer: $wallet",
        "consideration: [2]",
        "consideration[0].recipient: $stranger",
        "consideration[0].amount: 12",
        "consideration[1].recipient: $feeRecipient",
        "consideration[1].amount: 34",
        "terms.expiry: ${at(1700000000)}",
        "terms.salt: 0x${"ab" * 32}",
        "terms.note: gm",
        "terms.strict: false",
      ]);
      expect(decoded.warnings, [S.current.wc_warning_typed_data_unrecognized]);
    });

    test("shows no message or domain key the types do not declare", () async {
      final metaTransaction = typedData(
        primaryType: "MetaTransaction",
        structs: {
          "MetaTransaction": {"nonce": "uint256", "from": "address", "functionSignature": "bytes"},
        },
        domainFields: {
          "name": "string",
          "version": "string",
          "verifyingContract": "address",
          "salt": "bytes32",
        },
        domain: {
          "name": "USD Coin (PoS)",
          "version": "1",
          "verifyingContract": usdc,
          "salt": "0x${"00" * 31}89",
        },
        message: {"nonce": 0, "from": wallet, "functionSignature": "0x095ea7b3"},
      );
      final attack = jsonDecode(jsonEncode(metaTransaction)) as Map<String, dynamic>;
      (attack["domain"] as Map)["chainId"] = 1;
      (attack["message"] as Map)["memo"] = "harmless login";
      expect(messageHash(attack), messageHash(metaTransaction));

      final decoded = await decode(attack);
      expect(rowLines(decoded.rows), [
        "${S.current.wc_domain}: USD Coin (PoS)",
        "${S.current.chain_id}: $polygonChainId",
        "${S.current.wc_verifying_contract}: $usdc",
        "${S.current.wc_primary_type}: MetaTransaction",
        "nonce: 0",
        "from: $wallet",
        "functionSignature: 0x095ea7b3",
      ]);
      expect(decoded.warnings, [S.current.wc_warning_typed_data_unrecognized]);
      expect(decoded.rawFallback, isNot(contains("harmless login")));
      expect(TypedDataDecoder.domainChainId(jsonEncode(attack)), polygonChainId);
    });

    test("shows nothing from the message when the primary type declares no fields", () async {
      final emptyStruct = typedData(
        primaryType: "Order",
        structs: {"Order": {}},
        domainFields: tokenDomainFields,
        domain: {"name": "Example dApp", "version": "1", "chainId": 1, "verifyingContract": usdc},
        message: {"note": "harmless login", "amount": 1},
      );
      expect(
        messageHash(emptyStruct),
        messageHash({...emptyStruct, "message": <String, dynamic>{}}),
      );

      final decoded = await decode(emptyStruct);
      expect(rowLines(decoded.rows), [
        "${S.current.wc_domain}: Example dApp",
        "${S.current.chain_id}: 1",
        "${S.current.wc_verifying_contract}: $usdc",
        "${S.current.wc_primary_type}: Order",
      ]);
      expect(decoded.warnings, [S.current.wc_warning_typed_data_unrecognized]);
    });
  });

  group("payload forms", () {
    test("legacy V1 entries render as rows", () async {
      final decoded = await decoder.decode(
        jsonEncode(legacyMessage),
        walletAddress: wallet,
        chainId: sessionChainId,
        nativeSymbol: "ETH",
      );
      expect(decoded.actionTitle, S.current.wc_action_sign_typed_data);
      expect(rowLines(decoded.rows), [
        "greeting: Hello from a legacy dApp",
        "deadline: ${at(1700000000)}",
      ]);
      expect(decoded.warnings, isEmpty);
      expect(decoded.rawFallback, contains("Hello from a legacy dApp"));
    });
  });
}
