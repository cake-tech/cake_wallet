import 'dart:async';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/lightning/pending_lightning_transaction.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';

bool _breezSdkSparkLibUninitialized = true;

class LightningWallet {
  final String mnemonic;
  final String apiKey;
  final String lnurlDomain;
  final Network network;
  late BreezSdk sdk;

  LightningWallet({
    required this.mnemonic,
    required this.apiKey,
    required this.lnurlDomain,
    this.network = Network.mainnet,
  });

  Future<void> init(String appPath) async {
    if (_breezSdkSparkLibUninitialized) {
      await BreezSdkSparkLib.init();
      _breezSdkSparkLibUninitialized = false;
    }

    final seed = Seed.mnemonic(mnemonic: mnemonic, passphrase: null);
    final config = defaultConfig(network: Network.mainnet).copyWith(
      lnurlDomain: lnurlDomain,
      apiKey: apiKey,
      privateEnabledDefault: true,
    );

    final connectRequest = ConnectRequest(
      config: config,
      seed: seed,
      storageDir: "$appPath/",
    );

    sdk = await connect(request: connectRequest);
  }

  Future<String?> getAddress() async => (await sdk.getLightningAddress())?.lightningAddress;

  Future<String?> getLNURL() async => (await sdk.getLightningAddress())?.lnurl;

  Future<String> getDepositAddress() async => (await sdk.receivePayment(
          request: ReceivePaymentRequest(paymentMethod: ReceivePaymentMethod.bitcoinAddress())))
      .paymentRequest;

  Future<BigInt> getBalance() async =>
      (await sdk.getInfo(request: GetInfoRequest(ensureSynced: true))).balanceSats;

  Future<String> registerAddress(String username) async {
    return (await sdk.registerLightningAddress(
            request: RegisterLightningAddressRequest(username: username)))
        .lightningAddress;
  }

  Future<String> getBolt11Invoice(BigInt? amount, String description) async {
    final response = await sdk.receivePayment(
      request: ReceivePaymentRequest(
        paymentMethod: ReceivePaymentMethod.bolt11Invoice(
          description: description,
          amountSats: amount,
        ),
      ),
    );

    return response.paymentRequest;
  }

  Future<bool> isCompatible(String input) async {
    try {
      final inputType = await sdk.parse(input: input);
      return (inputType is InputType_Bolt11Invoice) || (inputType is InputType_LightningAddress) || (inputType is InputType_LnurlPay);
    } catch (_) {
      return false;
    }
  }

  Future<PendingLightningTransaction> createTransaction(
      String address, BigInt? amountSats, BitcoinTransactionPriority? priority) async {
    final inputType = await sdk.parse(input: address);

    if (inputType is InputType_Bolt11Invoice) {
      final request = PrepareSendPaymentRequest(
          paymentRequest: inputType.field0.invoice.bolt11, amount: amountSats);
      final prepareResponse = await sdk.prepareSendPayment(request: request);

      final paymentMethod = prepareResponse.paymentMethod;
      if (paymentMethod is SendPaymentMethod_Bolt11Invoice) {
        final lightningFeeSats = paymentMethod.lightningFeeSats;
        final sparkTransferFeeSats = paymentMethod.sparkTransferFeeSats;

        return PendingLightningTransaction(
          id: paymentMethod.invoiceDetails.paymentHash,
          amount: ((paymentMethod.invoiceDetails.amountMsat?.toInt() ?? 0) / 1000).round(),
          fee: lightningFeeSats.toInt() + (sparkTransferFeeSats?.toInt() ?? 0),
          commitOverride: () async {
            final res = await sdk.sendPayment(
                request: SendPaymentRequest(prepareResponse: prepareResponse));
            printV(res.payment.status.name);
          },
        );
      }
    } else if (inputType is InputType_LightningAddress || inputType is InputType_LnurlPay) {
      final optionalValidateSuccessActionUrl = true;

      PrepareLnurlPayRequest request;
      if (inputType is InputType_LightningAddress) {
        request = PrepareLnurlPayRequest(
          amountSats: amountSats!,
          payRequest: inputType.field0.payRequest,
          validateSuccessActionUrl: optionalValidateSuccessActionUrl,
        );
      } else {
        request = PrepareLnurlPayRequest(
          amountSats: amountSats!,
          payRequest: (inputType as InputType_LnurlPay).field0,
          validateSuccessActionUrl: optionalValidateSuccessActionUrl,
        );
      }

      final prepareResponse = await sdk.prepareLnurlPay(request: request);

      final feeSats = prepareResponse.feeSats;

      return PendingLightningTransaction(
        id: prepareResponse.invoiceDetails.paymentHash,
        amount: ((prepareResponse.invoiceDetails.amountMsat?.toInt() ?? 0) / 1000).round(),
        fee: feeSats.toInt(),
        commitOverride: () async {
          final res = await sdk.lnurlPay(request: LnurlPayRequest(prepareResponse: prepareResponse));
          printV(res.payment.status.name);
        },
      );
    } else if (inputType is InputType_BitcoinAddress) {
      final request =
          PrepareSendPaymentRequest(paymentRequest: inputType.field0.address, amount: amountSats);
      final prepareResponse = await sdk.prepareSendPayment(request: request);

      final paymentMethod = prepareResponse.paymentMethod;
      if (paymentMethod is SendPaymentMethod_BitcoinAddress) {
        final feeQuote = paymentMethod.feeQuote;

        OnchainConfirmationSpeed onchainConfirmationSpeed;
        int fee;
        switch (priority) {
          case BitcoinTransactionPriority.fast:
            fee = (feeQuote.speedFast.userFeeSat + feeQuote.speedFast.l1BroadcastFeeSat).toInt();
            onchainConfirmationSpeed = OnchainConfirmationSpeed.fast;
            break;
          case BitcoinTransactionPriority.medium:
            fee =
                (feeQuote.speedMedium.userFeeSat + feeQuote.speedMedium.l1BroadcastFeeSat).toInt();
            onchainConfirmationSpeed = OnchainConfirmationSpeed.medium;
            break;
          case BitcoinTransactionPriority.slow:
          default:
            fee = (feeQuote.speedSlow.userFeeSat + feeQuote.speedSlow.l1BroadcastFeeSat).toInt();
            onchainConfirmationSpeed = OnchainConfirmationSpeed.slow;
        }

        return PendingLightningTransaction(
          id: "", // ToDo: Find out where to get it
          amount: prepareResponse.amount.toInt(),
          fee: fee,
          commitOverride: () async {
            final options =
                SendPaymentOptions.bitcoinAddress(confirmationSpeed: onchainConfirmationSpeed);
            await sdk.sendPayment(
                request: SendPaymentRequest(prepareResponse: prepareResponse, options: options));
          },
        );
      }
    }

    // If not returned earlier
    throw UnimplementedError();
  }

  Future<Map<String, ElectrumTransactionInfo>> getTransactionHistory() async {
    final request = ListPaymentsRequest(
      typeFilter: [PaymentType.send, PaymentType.receive],
      // statusFilter: [PaymentStatus.completed],
      assetFilter: AssetFilter.bitcoin(),
      offset: 0,
      limit: 50,
      sortAscending: false, // Sort order (true = oldest first, false = newest first)
    );
    final response = await sdk.listPayments(request: request);
    final payments = response.payments;

    Map<String, ElectrumTransactionInfo> txHistory = {};
    for (final payment in payments) {
      TransactionDirection direction = TransactionDirection.outgoing;

      if (payment.paymentType == PaymentType.receive) {
        direction = TransactionDirection.incoming;
      }

      if (payment.method == PaymentMethod.deposit) {
        direction = TransactionDirection.incoming;
      }

      txHistory[payment.id] = ElectrumTransactionInfo(
        WalletType.bitcoin,
        id: payment.id,
        amount: payment.amount.toInt(),
        direction: direction,
        isPending: payment.status == PaymentStatus.pending,
        date: DateTime.fromMillisecondsSinceEpoch(payment.timestamp.toInt() * 1000),
        confirmations: payment.status == PaymentStatus.pending ? 0 : 10,
      );
    }

    return txHistory;
  }
}

extension _ConfigCopyWith on Config {
  Config copyWith({
    String? apiKey,
    String? lnurlDomain,
    Network? network,
    int? syncIntervalSecs,
    Fee? maxDepositClaimFee,
    bool? preferSparkOverLightning,
    bool? useDefaultExternalInputParsers,
    bool? privateEnabledDefault,
  }) =>
      Config(
        lnurlDomain: lnurlDomain ?? this.lnurlDomain,
        apiKey: apiKey ?? this.apiKey,
        network: network ?? this.network,
        syncIntervalSecs: syncIntervalSecs ?? this.syncIntervalSecs,
        maxDepositClaimFee: maxDepositClaimFee ?? this.maxDepositClaimFee,
        preferSparkOverLightning: preferSparkOverLightning ?? this.preferSparkOverLightning,
        useDefaultExternalInputParsers:
            useDefaultExternalInputParsers ?? this.useDefaultExternalInputParsers,
        privateEnabledDefault: privateEnabledDefault ?? this.privateEnabledDefault,
      );
}
