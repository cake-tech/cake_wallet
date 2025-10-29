import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:cw_bitcoin/lightning/pending_lightning_transaction.dart';
import 'package:cw_core/pending_transaction.dart';

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
    await BreezSdkSparkLib.init();

    final seed = Seed.mnemonic(mnemonic: mnemonic, passphrase: null);
    final config = defaultConfig(network: Network.mainnet).copyWith(
      lnurlDomain: lnurlDomain,
      apiKey: apiKey,
    );

    final connectRequest = ConnectRequest(
      config: config,
      seed: seed,
      storageDir: "$appPath/",
    );

    sdk = await connect(request: connectRequest);
  }

  Future<String?> getAddress() async => (await sdk.getLightningAddress())?.lightningAddress;

  Future<BigInt> getBalance() async =>
      (await sdk.getInfo(request: GetInfoRequest(ensureSynced: true))).balanceSats;

  Future<String> registerAddress(String username) async => (await sdk.registerLightningAddress(
          request: RegisterLightningAddressRequest(username: username)))
      .lightningAddress;

  Future<bool> isCompatible(String input) async {
    try {
      final inputType = await sdk.parse(input: input);
      return (inputType is InputType_Bolt11Invoice) || (inputType is InputType_LightningAddress);
    } catch (_) {
      return false;
    }
  }

  Future<PendingTransaction> createTransaction(String address, BigInt? amountSats) async {
    final inputType = await sdk.parse(input: address);

    if (inputType is InputType_Bolt11Invoice) {
      final request = PrepareSendPaymentRequest(
          paymentRequest: inputType.field0.invoice.bolt11, amount: amountSats);
      final prepareResponse = await sdk.prepareSendPayment(request: request);

      final paymentMethod = prepareResponse.paymentMethod;
      if (paymentMethod is SendPaymentMethod_Bolt11Invoice) {
        // Fees to pay via Lightning
        final lightningFeeSats = paymentMethod.lightningFeeSats;
        // Or fees to pay (if available) via a Spark transfer
        final sparkTransferFeeSats = paymentMethod.sparkTransferFeeSats;

        return PendingLightningTransaction(
          id: paymentMethod.invoiceDetails.paymentHash,
          amount: paymentMethod.invoiceDetails.amountMsat?.toInt() ?? 0,
          fee: lightningFeeSats.toInt() + (sparkTransferFeeSats?.toInt() ?? 0),
          commitOverride: () =>
              sdk.sendPayment(request: SendPaymentRequest(prepareResponse: prepareResponse)),
        );
      }
    } else if (inputType is InputType_LightningAddress) {
      final optionalValidateSuccessActionUrl = true;

      final request = PrepareLnurlPayRequest(
        amountSats: amountSats!,
        payRequest: inputType.field0.payRequest,
        validateSuccessActionUrl: optionalValidateSuccessActionUrl,
      );
      final prepareResponse = await sdk.prepareLnurlPay(request: request);

      final feeSats = prepareResponse.feeSats;

      return PendingLightningTransaction(
        id: prepareResponse.invoiceDetails.paymentHash,
        amount: prepareResponse.invoiceDetails.amountMsat?.toInt() ?? 0,
        fee: feeSats.toInt(),
        commitOverride: () =>
            sdk.lnurlPay(request: LnurlPayRequest(prepareResponse: prepareResponse)),
      );
    }

    // If not returned earlier
    throw UnimplementedError();
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
      );
}
