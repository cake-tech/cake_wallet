import 'dart:async';
import 'dart:typed_data';

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
  final String? passphrase;
  final Uint8List? seedBytes;
  final String apiKey;
  final String lnurlDomain;
  final Network network;
  late BreezSdk sdk;

  LightningWallet({
    required this.mnemonic,
    this.passphrase,
    this.seedBytes,
    required this.apiKey,
    required this.lnurlDomain,
    this.network = Network.mainnet,
  });

  Future<bool> init(String appPath) async {
    try {
      if (_breezSdkSparkLibUninitialized) {
        await BreezSdkSparkLib.init();
        _breezSdkSparkLibUninitialized = false;
      }

      final seed = seedBytes != null
          ? Seed.entropy(seedBytes!)
          : Seed.mnemonic(mnemonic: mnemonic, passphrase: passphrase);
      final config = defaultConfig(network: Network.mainnet).copyWith(
          lnurlDomain: lnurlDomain,
          apiKey: apiKey,
          privateEnabledDefault: true,
          maxDepositClaimFee: MaxFee.rate(satPerVbyte: BigInt.from(5))
      );

      final connectRequest = ConnectRequest(
        config: config,
        seed: seed,
        storageDir: "$appPath/",
      );

      sdk = await connect(request: connectRequest);

      _eventStream ??= sdk.addEventListener().asBroadcastStream();

      return true;
    } catch (e) {
      printV(e);
      return false;
    }
  }

  Future<void> close() async {
    _eventSubscription?.cancel();
    await sdk.disconnect();
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
      return (inputType is InputType_Bolt11Invoice) ||
          (inputType is InputType_LightningAddress) ||
          (inputType is InputType_LnurlPay);
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
          amount: amountSats?.toInt() ??
              ((paymentMethod.invoiceDetails.amountMsat?.toInt() ?? 0) / 1000).round(),
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
          final res =
              await sdk.lnurlPay(request: LnurlPayRequest(prepareResponse: prepareResponse));
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

    final txHistory = <String, ElectrumTransactionInfo>{};
    for (final payment in payments) {
      txHistory[payment.id] = _getElectrumTransactionInfoFromPayment(payment);
    }

    return txHistory;
  }

  /// Return a list of UnclaimedDeposits including a possible reason why they where not auto-claimed
  /// A unclaimed deposit is a [Map] consisting of the following datatypes
  ///
  /// | ----------------- | --------- |--------------------------------------------------- |
  /// | key-name          | data-type | description                                        |
  /// | ----------------- | --------- |--------------------------------------------------- |
  /// | txId              | String    | The txId of the deposit transaction                |
  /// | vout              | int       | The output index of the deposit                    |
  /// | amount            | BigInt    | Amount of the deposit in sats.                     |
  /// | claimError        | String?   | The type of Claim error                            |
  /// | actualFee         | BigInt?   | The actualFee in case of a DepositClaimFeeExceeded |
  /// | claimErrorMessage | String?   | The claimErrorMessage in case of a Generic Error   |
  ///
  Future<List<Map<String, dynamic>>> getUnclaimedDeposits() async {
    final unclaimedDeposits = <Map<String, dynamic>>[];
    final response = await sdk.listUnclaimedDeposits(request: ListUnclaimedDepositsRequest());
    for (final deposit in response.deposits) {
      final unclaimedDeposit = {
        "txId": deposit.txid,
        "vout": deposit.vout,
        "amount": deposit.amountSats,
      };

      final claimError = deposit.claimError;
      if (claimError is DepositClaimError_MaxDepositClaimFeeExceeded) {
        unclaimedDeposit["claimError"] = "DepositClaimError_MaxDepositClaimFeeExceeded";
        unclaimedDeposit["actualFee"] = claimError.requiredFeeSats;
      } else if (claimError is DepositClaimError_MissingUtxo) {
        unclaimedDeposit["claimError"] = "MissingUtxo";
      } else if (claimError is DepositClaimError_Generic) {
        unclaimedDeposit["claimError"] = "Generic";
        unclaimedDeposit["claimErrorMessage"] = claimError.message;
      }
    }

    return unclaimedDeposits;
  }

  Future<ElectrumTransactionInfo> claimDeposit(String txId, int vout, BigInt newFee) async {
    final response = await sdk.claimDeposit(
      request: ClaimDepositRequest(
        txid: txId,
        vout: vout,
        maxFee: MaxFee.fixed(amount: newFee),
      ),
    );

    return _getElectrumTransactionInfoFromPayment(response.payment);
  }

  Future<String> refundDeposit(String txId, int vout, String destinationAddress,
      BigInt feeRate) async {
    final response = await sdk.refundDeposit(request: RefundDepositRequest(
      txid: txId,
      vout: vout,
      destinationAddress: destinationAddress,
      fee: Fee.rate(satPerVbyte: feeRate),
    ),);

    return response.txHex;
  }

  StreamSubscription<SdkEvent>? _eventSubscription;
  Stream<SdkEvent>? _eventStream;

  void setEventListener(
      {required Function(ElectrumTransactionInfo) onTransactionEvent, required Function onBalanceChangedEvent}) {
    _eventSubscription = _eventStream?.listen((sdkEvent) {
      if (sdkEvent is SdkEvent_PaymentSucceeded) {
        onTransactionEvent(_getElectrumTransactionInfoFromPayment(sdkEvent.payment));
      } else if (sdkEvent is SdkEvent_PaymentPending) {
        onTransactionEvent(_getElectrumTransactionInfoFromPayment(sdkEvent.payment));
      } else if (sdkEvent is SdkEvent_ClaimedDeposits) {
        onBalanceChangedEvent();
      }
    });
  }

  ElectrumTransactionInfo _getElectrumTransactionInfoFromPayment(Payment payment) {
    TransactionDirection direction = TransactionDirection.outgoing;

    if (payment.paymentType == PaymentType.receive) {
      direction = TransactionDirection.incoming;
    }
    if (payment.method == PaymentMethod.deposit) {
      direction = TransactionDirection.incoming;
    }

    return ElectrumTransactionInfo(
      WalletType.bitcoin,
      id: payment.id,
      amount: payment.amount.toInt(),
      direction: direction,
      isPending: payment.status == PaymentStatus.pending,
      fee: payment.fees.toInt(),
      date: DateTime.fromMillisecondsSinceEpoch(payment.timestamp.toInt() * 1000),
      confirmations: payment.status == PaymentStatus.pending ? 0 : 10,
      additionalInfo: {"isLightning": true},
    );
  }
}

extension _ConfigCopyWith on Config {
  Config copyWith({
    String? apiKey,
    String? lnurlDomain,
    Network? network,
    int? syncIntervalSecs,
    MaxFee? maxDepositClaimFee,
    bool? preferSparkOverLightning,
    bool? useDefaultExternalInputParsers,
    bool? privateEnabledDefault,
    OptimizationConfig? optimizationConfig,
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
        optimizationConfig: optimizationConfig ?? this.optimizationConfig,
      );
}
