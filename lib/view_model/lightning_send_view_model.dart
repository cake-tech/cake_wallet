import 'dart:async';
import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/bridge_generated.dart' as BZG;
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount_raw.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/lightning/lightning.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:collection/collection.dart';

part 'lightning_send_view_model.g.dart';

class LightningSendViewModel = LightningSendViewModelBase with _$LightningSendViewModel;

abstract class LightningSendViewModelBase with Store {
  LightningSendViewModelBase({
    required this.wallet,
    required this.settingsStore,
    required this.fiatConversionStore,
  }) {
    _sdk = BreezSDK();
  }

  final WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> wallet;
  final SettingsStore settingsStore;
  final FiatConversionStore fiatConversionStore;
  int satAmount = 0;

  late final BreezSDK _sdk;

  FiatCurrency get fiat => settingsStore.fiatCurrency;

  CryptoCurrency get currency => wallet.currency;

  @observable
  bool loading = false;

  @action
  void setLoading(bool value) {
    loading = value;
  }

  @computed
  int get customBitcoinFeeRate => settingsStore.customBitcoinFeeRate;

  void set customBitcoinFeeRate(int value) => settingsStore.customBitcoinFeeRate = value;

  @computed
  bool get isFiatDisabled => settingsStore.fiatApiMode == FiatApiMode.disabled;

  TransactionPriority get transactionPriority {
    final priority = settingsStore.priority[WalletType.bitcoin];

    if (priority == null) {
      throw Exception('Unexpected type ${WalletType.bitcoin}');
    }

    return priority;
  }

  int? getCustomPriorityIndex(List<TransactionPriority> priorities) {
    final customItem = priorities
        .firstWhereOrNull((element) => element == bitcoin!.getBitcoinTransactionPriorityCustom());

    return customItem != null ? priorities.indexOf(customItem) : null;
  }

  Future<int?> get maxCustomFeeRate async {
    await (wallet as ElectrumWallet).updateFeeRates();
    return bitcoin!.getMaxCustomFeeRate(wallet);
  }

  @action
  void setTransactionPriority(TransactionPriority priority) =>
      settingsStore.priority[WalletType.bitcoin] = priority;

  String displayFeeRate(dynamic priority, int? customValue) {
    final _priority = priority as TransactionPriority;

    final rate = bitcoin!.getFeeRate(wallet, _priority);
    return bitcoin!.bitcoinTransactionPriorityWithLabel(_priority, rate, customRate: customValue);
  }

  int get estimatedFeeSats {
    int formattedCryptoAmount = satAmount;
    int? fee =
        wallet.calculateEstimatedFee(settingsStore.priority[WalletType.bitcoin]!, formattedCryptoAmount);

    if (settingsStore.priority[WalletType.bitcoin] == bitcoin!.getBitcoinTransactionPriorityCustom()) {
      fee = bitcoin!.getEstimatedFeeWithFeeRate(
          wallet, settingsStore.customBitcoinFeeRate, formattedCryptoAmount);
    }

    return (bitcoin!.formatterBitcoinAmountToDouble(amount: fee) * 100000000).round();
  }

  @action
  void setCryptoAmount(int sats) {
    satAmount = sats;
  }

  String formattedFiatAmount(int sats) {
    String amount = calculateFiatAmountRaw(
      cryptoAmount: lightning!.formatterLightningAmountToDouble(amount: sats),
      price: fiatConversionStore.prices[CryptoCurrency.btcln],
    );
    return amount;
  }

  String get estimatedFeeFiatAmount {
    return formattedFiatAmount(estimatedFeeSats);
  }

  @action
  Future<void> sendInvoice(BZG.LNInvoice invoice, int satAmount) async {
    try {
      setLoading(true);
      late BZG.SendPaymentRequest req;

      if (invoice.amountMsat == null) {
        req = BZG.SendPaymentRequest(
          bolt11: invoice.bolt11,
          amountMsat: satAmount * 1000,
        );
      } else {
        req = BZG.SendPaymentRequest(bolt11: invoice.bolt11);
      }

      final response = await _sdk.sendPayment(req: req);
      if (response.payment.error != null) {
        throw Exception(response.payment.error);
      }

      if (response.payment.status == BZG.PaymentStatus.Failed) {
        throw Exception("Payment failed");
      }

      setLoading(false);
    } catch (e) {
      setLoading(false);
      rethrow;
    }
  }

  @action
  Future<void> sendBtc(String address, int satAmount) async {
    try {
      setLoading(true);

      BZG.PrepareOnchainPaymentRequest prep = BZG.PrepareOnchainPaymentRequest(
        amountSat: satAmount,
        amountType: BZG.SwapAmountType.Send,
        claimTxFeerate: 10,
      );
      BZG.PrepareOnchainPaymentResponse prepareRes = await _sdk.prepareOnchainPayment(req: prep);

      BZG.PayOnchainRequest req = BZG.PayOnchainRequest(
        recipientAddress: address,
        prepareRes: prepareRes,
      );
      BZG.PayOnchainResponse res = await _sdk.payOnchain(req: req);

      if (res.reverseSwapInfo.status == BZG.ReverseSwapStatus.Cancelled) {
        throw Exception("Payment cancelled / error");
      }

      setLoading(false);
    } catch (e) {
      setLoading(false);
      rethrow;
    }
  }

  @action
  Future<void> processInput(BuildContext context, String input) async {
    FocusScope.of(context).unfocus();

    late BZG.InputType inputType;

    try {
      inputType = await _sdk.parseInput(input: input);
    } catch (_) {
      throw Exception("Unknown input type");
    }

    if (inputType is BZG.InputType_Bolt11) {
      final bolt11 = await _sdk.parseInvoice(input);
      Navigator.of(context).pushNamed(Routes.lightningSendConfirm, arguments: {'invoice': bolt11});
    } else if (inputType is BZG.InputType_BitcoinAddress) {
      final address = inputType.address.address;
      Navigator.of(context)
          .pushNamed(Routes.lightningSendConfirm, arguments: {'btcAddress': address});
    } else if (inputType is BZG.InputType_LnUrlPay) {
      throw Exception("Unsupported input type");
    } else {
      throw Exception("Unknown input type");
    }
  }
}
