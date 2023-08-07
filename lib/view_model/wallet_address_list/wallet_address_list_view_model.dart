import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/yat/yat_store.dart';
import 'package:cw_core/currency.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/utils/list_item.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_account_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/haven/haven.dart';

part 'wallet_address_list_view_model.g.dart';

class WalletAddressListViewModel = WalletAddressListViewModelBase with _$WalletAddressListViewModel;

abstract class PaymentURI {
  PaymentURI({required this.amount, required this.address});

  final String amount;
  final String address;
}

class MoneroURI extends PaymentURI {
  MoneroURI({required String amount, required String address})
      : super(amount: amount, address: address);

  @override
  String toString() {
    var base = 'monero:' + address;

    if (amount.isNotEmpty) {
      base += '?tx_amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class HavenURI extends PaymentURI {
  HavenURI({required String amount, required String address})
      : super(amount: amount, address: address);

  @override
  String toString() {
    var base = 'haven:' + address;

    if (amount.isNotEmpty) {
      base += '?tx_amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class BitcoinURI extends PaymentURI {
  BitcoinURI({required String amount, required String address})
      : super(amount: amount, address: address);

  @override
  String toString() {
    var base = 'bitcoin:' + address;

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class LitecoinURI extends PaymentURI {
  LitecoinURI({required String amount, required String address})
      : super(amount: amount, address: address);

  @override
  String toString() {
    var base = 'litecoin:' + address;

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class EthereumURI extends PaymentURI {
  EthereumURI({required String amount, required String address})
      : super(amount: amount, address: address);

  @override
  String toString() {
    var base = 'ethereum:' + address;

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

abstract class WalletAddressListViewModelBase with Store {
  WalletAddressListViewModelBase({
    required AppStore appStore,
    required this.yatStore,
    required this.fiatConversionStore,
  })  : _appStore = appStore,
        _baseItems = <ListItem>[],
        _wallet = appStore.wallet!,
        selectedCurrency = walletTypeToCryptoCurrency(appStore.wallet!.type),
        _cryptoNumberFormat = NumberFormat(_cryptoNumberPattern),
        hasAccounts =
            appStore.wallet!.type == WalletType.monero || appStore.wallet!.type == WalletType.haven,
        amount = '' {
    _init();
  }

  static const String _cryptoNumberPattern = '0.00000000';

  final NumberFormat _cryptoNumberFormat;

  final FiatConversionStore fiatConversionStore;

  List<Currency> get currencies => [walletTypeToCryptoCurrency(_wallet.type), ...FiatCurrency.all];

  @observable
  Currency selectedCurrency;

  @computed
  int get selectedCurrencyIndex => currencies.indexOf(selectedCurrency);

  @observable
  String amount;

  @computed
  WalletType get type => _wallet.type;

  @computed
  WalletAddressListItem get address =>
      WalletAddressListItem(address: _wallet.walletAddresses.address, isPrimary: false);

  @computed
  PaymentURI get uri {
    if (_wallet.type == WalletType.monero) {
      return MoneroURI(amount: amount, address: address.address);
    }

    if (_wallet.type == WalletType.haven) {
      return HavenURI(amount: amount, address: address.address);
    }

    if (_wallet.type == WalletType.bitcoin) {
      return BitcoinURI(amount: amount, address: address.address);
    }

    if (_wallet.type == WalletType.litecoin) {
      return LitecoinURI(amount: amount, address: address.address);
    }

    if (_wallet.type == WalletType.ethereum) {
      return EthereumURI(amount: amount, address: address.address);
    }

    throw Exception('Unexpected type: ${type.toString()}');
  }

  @computed
  ObservableList<ListItem> get items => ObservableList<ListItem>()
    ..addAll(_baseItems)
    ..addAll(addressList);

  @computed
  ObservableList<ListItem> get addressList {
    final wallet = _wallet;
    final addressList = ObservableList<ListItem>();

    if (wallet.type == WalletType.monero) {
      final primaryAddress = monero!.getSubaddressList(wallet).subaddresses.first;
      final addressItems = monero!.getSubaddressList(wallet).subaddresses.map((subaddress) {
        final isPrimary = subaddress == primaryAddress;

        return WalletAddressListItem(
            id: subaddress.id,
            isPrimary: isPrimary,
            name: subaddress.label,
            address: subaddress.address);
      });
      addressList.addAll(addressItems);
    }

    if (wallet.type == WalletType.haven) {
      final primaryAddress = haven!.getSubaddressList(wallet).subaddresses.first;
      final addressItems = haven!.getSubaddressList(wallet).subaddresses.map((subaddress) {
        final isPrimary = subaddress == primaryAddress;

        return WalletAddressListItem(
            id: subaddress.id,
            isPrimary: isPrimary,
            name: subaddress.label,
            address: subaddress.address);
      });
      addressList.addAll(addressItems);
    }

    if (wallet.type == WalletType.bitcoin) {
      final primaryAddress = bitcoin!.getAddress(wallet);
      final bitcoinAddresses = bitcoin!.getAddresses(wallet).map((addr) {
        final isPrimary = addr == primaryAddress;

        return WalletAddressListItem(isPrimary: isPrimary, name: null, address: addr);
      });
      addressList.addAll(bitcoinAddresses);
    }

    if (wallet.type == WalletType.ethereum) {
      final primaryAddress = ethereum!.getAddress(wallet);

      addressList.add(WalletAddressListItem(isPrimary: true, name: null, address: primaryAddress));
    }

    return addressList;
  }

  @observable
  bool hasAccounts;

  @computed
  String get accountLabel {
    final wallet = _wallet;

    if (wallet.type == WalletType.monero) {
      return monero!.getCurrentAccount(wallet).label;
    }

    if (wallet.type == WalletType.haven) {
      return haven!.getCurrentAccount(wallet).label;
    }

    return '';
  }

  @computed
  bool get hasAddressList => _wallet.type == WalletType.monero || _wallet.type == WalletType.haven;

  @computed
  bool get showElectrumAddressDisclaimer =>
      _wallet.type == WalletType.bitcoin || _wallet.type == WalletType.litecoin;

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> _wallet;

  List<ListItem> _baseItems;

  AppStore _appStore;

  final YatStore yatStore;

  @action
  void setAddress(WalletAddressListItem address) =>
      _wallet.walletAddresses.address = address.address;

  void _init() {
    _baseItems = [];

    if (_wallet.type == WalletType.monero || _wallet.type == WalletType.haven) {
      _baseItems.add(WalletAccountListHeader());
    }

    _baseItems.add(WalletAddressListHeader());
  }

  @action
  void selectCurrency(Currency currency) {
    selectedCurrency = currency;
  }

  @action
  void changeAmount(String amount) {
    this.amount = amount;
    if (selectedCurrency is FiatCurrency) {
      _convertAmountToCrypto();
    }
  }

  void _convertAmountToCrypto() {
    final cryptoCurrency = walletTypeToCryptoCurrency(_wallet.type);
    try {
      final crypto =
          double.parse(amount.replaceAll(',', '.')) / fiatConversionStore.prices[cryptoCurrency]!;
      final cryptoAmountTmp = _cryptoNumberFormat.format(crypto);
      if (amount != cryptoAmountTmp) {
        amount = cryptoAmountTmp;
      }
    } catch (e) {
      amount = '';
    }
  }
}
