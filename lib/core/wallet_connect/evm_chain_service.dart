import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:cake_wallet/core/wallet_connect/eth_transaction_model.dart';
import 'package:cake_wallet/core/wallet_connect/wc_bottom_sheet_service.dart';
import 'package:cake_wallet/core/wallet_connect/web3wallet_service.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/error_displapy_widget.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/src/screens/wallet_connect/models/chain_key_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/models/connection_model.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/connection_widget.dart';
import 'package:cake_wallet/src/screens/wallet_connect/widgets/modals/web3_request_modal.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/string_parsing.dart';
import 'package:convert/convert.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:http/http.dart' as http;
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/web3dart.dart';
import 'chain_service.dart';
import 'wallet_connect_key_service.dart';

enum EVMChainId {
  ethereum,
  polygon,
  goerli,
  mumbai,
  arbitrum,
}

extension EVMChainIdX on EVMChainId {
  String chain() {
    String name = '';

    switch (this) {
      case EVMChainId.ethereum:
        name = '1';
        break;
      case EVMChainId.polygon:
        name = '137';
        break;
      case EVMChainId.goerli:
        name = '5';
        break;
      case EVMChainId.arbitrum:
        name = '42161';
        break;
      case EVMChainId.mumbai:
        name = '80001';
        break;
    }

    return '${EvmChainServiceImpl.namespace}:$name';
  }
}

class EvmChainServiceImpl implements ChainService {
  final AppStore appStore;
  final BottomSheetService bottomSheetService;
  final Web3WalletService web3WalletService;
  final WalletConnectKeyService wcKeyService;

  static const namespace = 'eip155';
  static const pSign = 'personal_sign';
  static const eSign = 'eth_sign';
  static const eSignTransaction = 'eth_signTransaction';
  static const eSignTypedData = 'eth_signTypedData_v4';
  static const eSendTransaction = 'eth_sendTransaction';

  final EVMChainId reference;

  final Web3Client ethClient;

  EvmChainServiceImpl({
    required this.reference,
    required this.appStore,
    required this.wcKeyService,
    required this.bottomSheetService,
    required this.web3WalletService,
    Web3Client? ethClient,
  }) : ethClient = ethClient ??
            Web3Client(
              appStore.settingsStore.getCurrentNode(WalletType.ethereum).uri.toString(),
              http.Client(),
            ) {
    final Web3Wallet wallet = web3WalletService.getWeb3Wallet();
    for (final String event in getEvents()) {
      wallet.registerEventEmitter(chainId: getChainId(), event: event);
    }
    wallet.registerRequestHandler(
      chainId: getChainId(),
      method: pSign,
      handler: personalSign,
    );
    wallet.registerRequestHandler(
      chainId: getChainId(),
      method: eSign,
      handler: ethSign,
    );
    wallet.registerRequestHandler(
      chainId: getChainId(),
      method: eSignTransaction,
      handler: ethSignTransaction,
    );
    wallet.registerRequestHandler(
      chainId: getChainId(),
      method: eSendTransaction,
      handler: ethSignTransaction,
    );
    wallet.registerRequestHandler(
      chainId: getChainId(),
      method: eSignTypedData,
      handler: ethSignTypedData,
    );
  }

  @override
  String getNamespace() {
    return namespace;
  }

  @override
  String getChainId() {
    return reference.chain();
  }

  @override
  List<String> getEvents() {
    return ['chainChanged', 'accountsChanged'];
  }

  Future<String?> requestAuthorization(String? text) async {
    // Show the bottom sheet
    final bool? isApproved = await bottomSheetService.queueBottomSheet(
      widget: Web3RequestModal(
        child: ConnectionWidget(
          title: 'Sign Transaction',
          info: [
            ConnectionModel(
              text: text,
            ),
          ],
        ),
      ),
    ) as bool?;

    if (isApproved != null && isApproved == false) {
      return 'User rejected signature';
    }

    return null;
  }

  Future<String> personalSign(String topic, dynamic parameters) async {
    log('received personal sign request: $parameters');

    final String message;
    if (parameters[0] == null) {
      message = '';
    } else {
      message = parameters[0].toString().utf8Message;
    }

    final String? authError = await requestAuthorization(message);

    if (authError != null) {
      return authError;
    }

    try {
      // Load the private key
      final List<ChainKeyModel> keys = wcKeyService.getKeysForChain(getChainId());

      final Credentials credentials = EthPrivateKey.fromHex(keys[0].privateKey);

      final String signature = hex.encode(
        credentials.signPersonalMessageToUint8List(
          Uint8List.fromList(
            utf8.encode(message),
          ),
        ),
      );

      return '0x$signature';
    } catch (e) {
      log(e.toString());
      bottomSheetService.queueBottomSheet(
        isModalDismissible: true,
        widget: ErrorWidgetDisplay(
          errorText: 'Failed: Error while getting credentials ${e.toString()}',
        ),
      );
      return 'Failed: Error while getting credentials';
    }
  }

  Future<String> ethSign(String topic, dynamic parameters) async {
    log('received eth sign request: $parameters');

    final String message;
    if (parameters[1] == null) {
      message = '';
    } else {
      message = parameters[1].toString().utf8Message;
    }

    final String? authError = await requestAuthorization(message);
    if (authError != null) {
      return authError;
    }

    try {
      // Load the private key
      final List<ChainKeyModel> keys = wcKeyService.getKeysForChain(getChainId());

      final EthPrivateKey credentials = EthPrivateKey.fromHex(keys[0].privateKey);

      final String signature = hex.encode(
        credentials.signPersonalMessageToUint8List(
          Uint8List.fromList(utf8.encode(message)),
        ),
      );
      log(signature);

      return '0x$signature';
    } catch (e) {
      log('error: ${e.toString()}');
      bottomSheetService.queueBottomSheet(
        isModalDismissible: true,
        widget: ErrorWidgetDisplay(errorText: 'Error: ${e.toString()}'),
      );
      return 'Failed';
    }
  }

  Future<String> ethSignTransaction(String topic, dynamic parameters) async {
    log('received eth sign transaction request: $parameters');

    final bodyParam = jsonEncode(parameters[0]);

    final String? authError = await requestAuthorization(bodyParam);

    if (authError != null) {
      return authError;
    }

    // Load the private key
    final List<ChainKeyModel> keys = wcKeyService.getKeysForChain(getChainId());

    final Credentials credentials = EthPrivateKey.fromHex(keys[0].privateKey);

    WCEthereumTransactionModel ethTransaction =
        WCEthereumTransactionModel.fromJson(parameters[0] as Map<String, dynamic>);

    String hexValue = "0x00";
    String data = "0x";
    if ((parameters[0] as Map).containsKey("value")) {
      hexValue = ethTransaction.value;
    }
    if ((parameters[0] as Map).containsKey("data")) {
      data = ethTransaction.data ?? "";
    }

    BigInt? value = BigInt.tryParse(hexValue, radix: 16);

    // Construct a transaction from the EthereumTransactionModel object
    final transaction = Transaction(
      from: EthereumAddress.fromHex(ethTransaction.from),
      to: EthereumAddress.fromHex(ethTransaction.to),
      value: EtherAmount.fromBigInt(EtherUnit.wei, value ?? BigInt.zero),
      data: hexToBytes(data),
    );

    try {
      final result = await ethClient.sendTransaction(credentials, transaction);

      log('Result: $result');

      return result;
    } catch (e) {
      log('An error has occured while signing transaction: ${e.toString()}');
      bottomSheetService.queueBottomSheet(
        isModalDismissible: true,
        widget: ErrorWidgetDisplay(
          errorText: 'An error has occured while signing transaction: ${e.toString()}',
        ),
      );
      return 'Failed';
    }
  }

  Future<String> ethSignTypedData(String topic, dynamic parameters) async {
    log('received eth sign typed data request: $parameters');
    final String? data = parameters[1] as String?;

    final String? authError = await requestAuthorization(data);

    if (authError != null) {
      return authError;
    }

    final List<ChainKeyModel> keys = wcKeyService.getKeysForChain(getChainId());

    return EthSigUtil.signTypedData(
      privateKey: keys[0].privateKey,
      jsonData: data ?? '',
      version: TypedDataVersion.V4,
    );
  }
}
