import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/lightning/pending_lightning_transaction.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';

bool _breezSdkSparkLibUninitialized = true;
Stream<LogEntry>? _logStream;

class LightningWallet {
  final String mnemonic;
  final String? passphrase;
  final Uint8List? seedBytes;
  final String apiKey;
  final String lnurlDomain;
  final Network network;
  BreezSdk? _sdk;

  String? cachedAddress;

  static int MAX_RETRIES = 10;

  LightningWallet({
    required this.mnemonic,
    this.passphrase,
    this.seedBytes,
    required this.apiKey,
    required this.lnurlDomain,
    this.network = Network.mainnet,
    this.cachedAddress,
  });

  static bool get isAvailable => Platform.isIOS || Platform.isAndroid || Platform.isMacOS;

  Currency get currency => CryptoCurrency.btcln;

  BreezSdk get sdk => _sdk!;

  StreamSubscription<SdkEvent>? _eventSubscription;
  Stream<SdkEvent>? _eventStream;

  StreamSubscription<LogEntry>? _logSubscription;

  bool get isInitialized => _eventStream != null;

  void _subscribeToLogStream(File logFile) {
    _logSubscription = _logStream?.listen((logEntry) {
      try {
        // Check if file exists before writing (optional, but safer)
        if (!logFile.existsSync()) {
          logFile.createSync(recursive: true);
        }
        logFile.writeAsStringSync("[${logEntry.level}] ${logEntry.line}\n", mode: FileMode.append);
      } catch (e) {
        // Silently fail or use printV(e) so it doesn't crash the app
        printV("Failed to write to log: $e");
      }
    }, onError: (e) {
      try {
        if (!logFile.existsSync()) {
          logFile.createSync(recursive: true);
        }
        logFile.writeAsStringSync("[ERROR] $e\n", mode: FileMode.append);
      } catch (err) {
        printV("Failed to write error to log: $err");
      }
    });
  }

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
          maxDepositClaimFee: MaxFee.rate(satPerVbyte: BigInt.from(5)));

      final connectRequest = ConnectRequest(
        config: config,
        seed: seed,
        storageDir: "$appPath/.breez/",
      );

      _sdk = await connect(request: connectRequest);

      _eventStream ??= sdk.addEventListener().asBroadcastStream();
      _logStream ??= initLogging().asBroadcastStream();

      try {
        final logFile = File("$appPath/lightning.log")..createSync();
        _subscribeToLogStream(logFile);
      } catch (e) {
        printV(e);
      }

      await sdk.syncWallet(request: SyncWalletRequest());

      return true;
    } catch (e) {
      printV(e);
      return false;
    }
  }

  Future<void> close() async {
    _eventSubscription?.cancel();
    try {
      await _sdk?.disconnect();
    } catch (_) {}
    _logSubscription?.cancel();
  }

  Future<String?> getAddress() async {
    var retries = 0;
    while (retries < MAX_RETRIES) {
      try {
        final address = (await sdk.getLightningAddress())?.lightningAddress;

        if (address != null) {
          cachedAddress = address;
          return address;
        }
      } catch (_) {} // No need to log here since it should be in the lightning log
      retries++;
      await Future.delayed(Duration(milliseconds: 500));
    }

    return cachedAddress;
  }

  Future<String> getDepositAddress() async => (await sdk.receivePayment(
          request: ReceivePaymentRequest(paymentMethod: ReceivePaymentMethod.bitcoinAddress())))
      .paymentRequest;

  Future<Money> getBalance() async {
    try {
      return Money((await sdk.getInfo(request: GetInfoRequest(ensureSynced: true))).balanceSats,
          CryptoCurrency.btcln);
    } on SdkError_Generic catch (_) {
    } on SdkError_NetworkError catch (_) {}

    return Money.zero(CryptoCurrency.btcln);
  }

  Future<String> registerAddress(String username) async {
    return (await sdk.registerLightningAddress(
            request: RegisterLightningAddressRequest(username: username)))
        .lightningAddress;
  }

  Future<String?> getBolt11Invoice(BigInt? amount, String description) async {
    try {
      final response = await sdk.receivePayment(
        request: ReceivePaymentRequest(
          paymentMethod: ReceivePaymentMethod.bolt11Invoice(
            description: description,
            amountSats: amount,
          ),
        ),
      );

      return response.paymentRequest;
    } on SdkError_NetworkError catch (_) {
      return null;
    } on SdkError_SparkError catch (e) {
      if (!e.field0.contains("dns") && !e.field0.contains("TimedOut")) rethrow;
      return null;
    }
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

  Future<PendingLightningTransaction> createTransaction(String address, BigInt? amountSats,
      BitcoinTransactionPriority? priority, bool feesIncluded) async {
    final inputType = await sdk.parse(input: address);

    final feePolicy = feesIncluded ? FeePolicy.feesIncluded : FeePolicy.feesExcluded;

    if (inputType is InputType_Bolt11Invoice) {
      final request = PrepareSendPaymentRequest(
          paymentRequest: inputType.field0.invoice.bolt11,
          amount: amountSats,
          feePolicy: feePolicy);
      final prepareResponse = await sdk.prepareSendPayment(request: request);

      final paymentMethod = prepareResponse.paymentMethod;
      if (paymentMethod is SendPaymentMethod_Bolt11Invoice) {
        final lightningFeeSats = paymentMethod.lightningFeeSats;
        final sparkTransferFeeSats = paymentMethod.sparkTransferFeeSats;

        final baseAmount = request.amount ?? amountSats;
        final amount = baseAmount != null
            ? Money(baseAmount, currency)
            : Money(paymentMethod.invoiceDetails.amountMsat ?? BigInt.zero, currency) /
                BigInt.from(1000);

        return PendingLightningTransaction(
          id: paymentMethod.invoiceDetails.paymentHash,
          amount: amount,
          fee: Money(lightningFeeSats + (sparkTransferFeeSats ?? BigInt.zero), currency),
          commitOverride: () async {
            try {
              final res = await sdk.sendPayment(
                  request: SendPaymentRequest(prepareResponse: prepareResponse));
              printV(res.payment.status.name);
              return res.payment.id;
            } on SdkError_SparkError catch (e) {
              if (e.field0.contains("AlreadyExists")) {
                throw Exception("Invoice already paid");
              }
              rethrow;
            }
          },
        );
      }
    } else if (inputType is InputType_LightningAddress || inputType is InputType_LnurlPay) {
      final optionalValidateSuccessActionUrl = true;

      PrepareLnurlPayRequest request;
      if (inputType is InputType_LightningAddress) {
        request = PrepareLnurlPayRequest(
          amount: amountSats!,
          payRequest: inputType.field0.payRequest,
          validateSuccessActionUrl: optionalValidateSuccessActionUrl,
          feePolicy: feePolicy,
        );
      } else {
        request = PrepareLnurlPayRequest(
          amount: amountSats!,
          payRequest: (inputType as InputType_LnurlPay).field0,
          validateSuccessActionUrl: optionalValidateSuccessActionUrl,
          feePolicy: feePolicy,
        );
      }

      final prepareResponse = await sdk.prepareLnurlPay(request: request);

      return PendingLightningTransaction(
        id: prepareResponse.invoiceDetails.paymentHash,
        amount: Money(prepareResponse.amountSats, currency),
        fee: Money(prepareResponse.feeSats, currency),
        commitOverride: () async {
          final res =
              await sdk.lnurlPay(request: LnurlPayRequest(prepareResponse: prepareResponse));
          printV(res.payment.status.name);
          return res.payment.id;
        },
      );
    } else if (inputType is InputType_BitcoinAddress) {
      final request = PrepareSendPaymentRequest(
        paymentRequest: inputType.field0.address,
        amount: amountSats,
        feePolicy: feePolicy,
      );
      final prepareResponse = await sdk.prepareSendPayment(request: request);

      final paymentMethod = prepareResponse.paymentMethod;
      if (paymentMethod is SendPaymentMethod_BitcoinAddress) {
        final feeQuote = paymentMethod.feeQuote;

        OnchainConfirmationSpeed onchainConfirmationSpeed;
        BigInt fee;
        switch (priority) {
          case BitcoinTransactionPriority.fast:
            fee = feeQuote.speedFast.userFeeSat + feeQuote.speedFast.l1BroadcastFeeSat;
            onchainConfirmationSpeed = OnchainConfirmationSpeed.fast;
            break;
          case BitcoinTransactionPriority.medium:
            fee = feeQuote.speedMedium.userFeeSat + feeQuote.speedMedium.l1BroadcastFeeSat;
            onchainConfirmationSpeed = OnchainConfirmationSpeed.medium;
            break;
          case BitcoinTransactionPriority.slow:
          default:
            fee = feeQuote.speedSlow.userFeeSat + feeQuote.speedSlow.l1BroadcastFeeSat;
            onchainConfirmationSpeed = OnchainConfirmationSpeed.slow;
        }

        return PendingLightningTransaction(
          id: "", // ToDo: Find out where to get it
          amount: Money(prepareResponse.amount, currency),
          fee: Money(fee, currency),
          commitOverride: () async {
            final options =
                SendPaymentOptions.bitcoinAddress(confirmationSpeed: onchainConfirmationSpeed);
            final res = await sdk.sendPayment(
                request: SendPaymentRequest(prepareResponse: prepareResponse, options: options));
            return res.payment.id;
          },
        );
      }
    }

    // If not returned earlier
    throw UnimplementedError();
  }

  Future<Map<String, ElectrumTransactionInfo>> getTransactionHistory({DateTime? fromDate}) async {
    final request = ListPaymentsRequest(
      typeFilter: [PaymentType.send, PaymentType.receive],
      // statusFilter: [PaymentStatus.completed],
      fromTimestamp:
          fromDate != null ? BigInt.from((fromDate.millisecondsSinceEpoch / 1000).round()) : null,
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

  Future<String> refundDeposit(
      String txId, int vout, String destinationAddress, BigInt feeRate) async {
    final response = await sdk.refundDeposit(
      request: RefundDepositRequest(
        txid: txId,
        vout: vout,
        destinationAddress: destinationAddress,
        fee: Fee.rate(satPerVbyte: feeRate),
      ),
    );

    return response.txHex;
  }

  void setEventListener({
    required Function(ElectrumTransactionInfo) onTransactionEvent,
    required Function onBalanceChangedEvent,
    required Function(Map<String, ElectrumTransactionInfo>) onCreateDepositTransactionEvent,
    required Function(List<ElectrumTransactionInfo>) onUpdateDepositTransactionEvent,
  }) {
    _eventSubscription = _eventStream?.listen((sdkEvent) {
      if (sdkEvent is SdkEvent_PaymentSucceeded) {
        onTransactionEvent(_getElectrumTransactionInfoFromPayment(sdkEvent.payment));
      } else if (sdkEvent is SdkEvent_PaymentPending) {
        onTransactionEvent(_getElectrumTransactionInfoFromPayment(sdkEvent.payment));
      } else if (sdkEvent is SdkEvent_ClaimedDeposits) {
        onBalanceChangedEvent();
        onUpdateDepositTransactionEvent(
            sdkEvent.claimedDeposits.map(_getElectrumTransactionInfoFromDepositInfo).toList());
      } else if (sdkEvent is SdkEvent_UnclaimedDeposits) {
        final unclaimedDeposits = <String, ElectrumTransactionInfo>{};

        for (final deposit in sdkEvent.unclaimedDeposits) {
          unclaimedDeposits[deposit.txid] = _getElectrumTransactionInfoFromDepositInfo(deposit);
        }

        onCreateDepositTransactionEvent(unclaimedDeposits);
      }
    });
  }

  ElectrumTransactionInfo _getElectrumTransactionInfoFromPayment(Payment payment) {
    var direction = TransactionDirection.outgoing;

    if (payment.paymentType == PaymentType.receive) {
      direction = TransactionDirection.incoming;
    }
    if (payment.method == PaymentMethod.deposit) {
      direction = TransactionDirection.incoming;
    }

    String? preimage;
    if (payment.details != null && payment.details is PaymentDetails_Lightning) {
      preimage = (payment.details as PaymentDetails_Lightning).htlcDetails.preimage;
    }

    return ElectrumTransactionInfo(
      WalletType.bitcoin,
      id: payment.id,
      amount: Money(payment.amount, currency),
      direction: direction,
      isPending: payment.status == PaymentStatus.pending,
      fee: Money(payment.fees, currency),
      date: DateTime.fromMillisecondsSinceEpoch(payment.timestamp.toInt() * 1000),
      confirmations: payment.status == PaymentStatus.pending ? 0 : 10,
      additionalInfo: {
        "isLightning": true,
        if (preimage != null) "preimage": preimage,
      },
    );
  }

  ElectrumTransactionInfo _getElectrumTransactionInfoFromDepositInfo(DepositInfo deposit) {
    return ElectrumTransactionInfo(
      WalletType.bitcoin,
      id: deposit.txid,
      amount: Money(deposit.amountSats, currency),
      direction: TransactionDirection.incoming,
      isPending: true,
      fee: Money.zero(currency),
      date: DateTime.now(),
      confirmations: 0,
      additionalInfo: {"isLightning": true, "isSparkDeposit": true},
    );
  }
}
