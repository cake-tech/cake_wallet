import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/domain/common/pending_transaction.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/monero/monero_transaction_creation_credentials.dart';
import 'package:cake_wallet/src/domain/monero/transaction_description.dart';
import 'package:cake_wallet/src/stores/price/price_store.dart';
import 'package:cake_wallet/src/stores/send/sending_state.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'send_store.g.dart';

class SendStore = SendStoreBase with _$SendStore;

abstract class SendStoreBase with Store {
  SendStoreBase(
      {@required this.walletService,
      this.settingsStore,
      this.transactionDescriptions,
      this.priceStore}) {
    state = SendingStateInitial();
    _pendingTransaction = null;
    _cryptoNumberFormat = NumberFormat()..maximumFractionDigits = 12;
    _fiatNumberFormat = NumberFormat()..maximumFractionDigits = 2;

    reaction((_) => this.state, (SendingState state) async {
      if (state is TransactionCreatedSuccessfully) {
        await commitTransaction();
      }
    });
  }

  WalletService walletService;
  SettingsStore settingsStore;
  PriceStore priceStore;
  Box<TransactionDescription> transactionDescriptions;

  @observable
  SendingState state;

  @observable
  String fiatAmount;

  @observable
  String cryptoAmount;

  @observable
  bool isValid;

  @observable
  String errorMessage;

  PendingTransaction get pendingTransaction => _pendingTransaction;
  PendingTransaction _pendingTransaction;
  NumberFormat _cryptoNumberFormat;
  NumberFormat _fiatNumberFormat;
  String _lastRecipientAddress;

  @action
  Future createTransaction(
      {String address, String paymentId, String amount}) async {
    state = CreatingTransaction();

    try {
      final _amount = amount != null
          ? amount
          : cryptoAmount == S.current.all
              ? null
              : cryptoAmount.replaceAll(',', '.');
      final credentials = MoneroTransactionCreationCredentials(
          address: address,
          paymentId: paymentId ?? '',
          amount: _amount,
          priority: settingsStore.transactionPriority);

      _pendingTransaction = await walletService.createTransaction(credentials);
      state = TransactionCreatedSuccessfully();
      _lastRecipientAddress = address;
    } catch (e) {
      state = SendingFailed(error: e.toString());
    }
  }

  @action
  Future commitTransaction() async {
    try {
      final transactionId = _pendingTransaction.hash;
      await _pendingTransaction.commit();

      if (settingsStore.shouldSaveRecipientAddress) {
        await transactionDescriptions.add(TransactionDescription(
            id: transactionId, recipientAddress: _lastRecipientAddress));
      }
    } catch (e) {
      state = SendingFailed(error: e.toString());
    }

    _pendingTransaction = null;
  }

  @action
  void setSendAll() {
    cryptoAmount = 'ALL';
    fiatAmount = '';
  }

  @action
  void changeCryptoAmount(String amount) {
    cryptoAmount = amount;

    if (cryptoAmount != null && cryptoAmount.isNotEmpty) {
      _calculateFiatAmount();
    } else {
      fiatAmount = '';
    }
  }

  @action
  void changeFiatAmount(String amount) {
    fiatAmount = amount;

    if (fiatAmount != null && fiatAmount.isNotEmpty) {
      _calculateCryptoAmount();
    } else {
      cryptoAmount = '';
    }
  }

  @action
  Future _calculateFiatAmount() async {
    final symbol = PriceStoreBase.generateSymbolForPair(
        fiat: settingsStore.fiatCurrency, crypto: CryptoCurrency.xmr);
    final price = priceStore.prices[symbol] ?? 0;

    try {
      final amount = double.parse(cryptoAmount) * price;
      fiatAmount = _fiatNumberFormat.format(amount);
    } catch (e) {
      fiatAmount = '0.00';
    }
  }

  @action
  Future _calculateCryptoAmount() async {
    final symbol = PriceStoreBase.generateSymbolForPair(
        fiat: settingsStore.fiatCurrency, crypto: CryptoCurrency.xmr);
    final price = priceStore.prices[symbol] ?? 0;

    try {
      final amount = double.parse(fiatAmount) / price;
      cryptoAmount = _cryptoNumberFormat.format(amount);
    } catch (e) {
      cryptoAmount = '0.00';
    }
  }

  void validateAddress(String value, {CryptoCurrency cryptoCurrency}) {
    // XMR (95), BTC (34, 42), ETH (42), LTC (34), BCH (42), DASH (34)
    const pattern = '^[0-9a-zA-Z]{95}\$|^[0-9a-zA-Z]{34}\$|^[0-9a-zA-Z]{42}\$';
    final regExp = RegExp(pattern);
    isValid = value == null ? false : regExp.hasMatch(value);

    if (isValid && cryptoCurrency != null) {
      switch (cryptoCurrency.toString()) {
        case 'XMR':
          isValid = (value.length == 95);
          break;
        case 'BTC':
          isValid = (value.length == 34)||(value.length == 42);
          break;
        case 'ETH':
          isValid = (value.length == 42);
          break;
        case 'LTC':
          isValid = (value.length == 34);
          break;
        case 'BCH':
          isValid = (value.length == 42);
          break;
        case 'DASH':
          isValid = (value.length == 34);
      }
    }

    errorMessage = isValid ? null : S.current.error_text_address;
  }

  void validatePaymentID(String value) {
    if (value.isEmpty) {
      isValid = true;
    } else {
      const pattern = '^[A-Fa-f0-9]{16,64}\$';
      final regExp = RegExp(pattern);
      isValid = regExp.hasMatch(value);
    }

    errorMessage = isValid ? null : S.current.error_text_payment_id;
  }

  void validateXMR(String value, String availableBalance) {
    const double maxValue = 18446744.073709551616;
    const pattern = '^([0-9]+([.][0-9]{0,12})?|[.][0-9]{1,12})\$|ALL';
    final regExp = RegExp(pattern);

    if (regExp.hasMatch(value)) {
      if (value == 'ALL') {
        isValid = true;
      } else {
        try {
          final dValue = double.parse(value);
          final maxAvailable = double.parse(availableBalance);
          isValid =
              (dValue <= maxAvailable && dValue <= maxValue && dValue > 0);
        } catch (e) {
          isValid = false;
        }
      }
    } else {
      isValid = false;
    }
    
    errorMessage = isValid ? null : S.current.error_text_xmr;
  }

  void validateFiat(String value, {double maxValue}) {
    const double minValue = 0.01;

    if (value.isEmpty && cryptoAmount == 'ALL') {
      isValid = true;
    } else {
      const pattern = '^([0-9]+([.][0-9]{0,2})?|[.][0-9]{1,2})\$';
      final regExp = RegExp(pattern);

      if (regExp.hasMatch(value)) {
        try {
          final dValue = double.parse(value);
          isValid = (dValue >= minValue && dValue <= maxValue);
        } catch (e) {
          isValid = false;
        }
      } else {
        isValid = false;
      }
    }

    errorMessage = isValid
        ? null
        : "Value of amount can't exceed available balance.\n"
            "The number of fraction digits must be less or equal to 2";
  }
}
