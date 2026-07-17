import "dart:core";

import "package:cake_wallet/core/address_resolver/yat/yat_store.dart";
import "package:cake_wallet/core/address_service.dart";
import "package:cake_wallet/core/address_types.dart";
import "package:cake_wallet/core/amount_parsing_proxy.dart";
import "package:cake_wallet/core/fiat_conversion_service.dart";
import "package:cake_wallet/core/wallet_change_listener_view_model.dart";
import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/reactions/wallet_utils.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/utils/list_item.dart";
import "package:cake_wallet/utils/qr_util.dart";
import "package:cake_wallet/view_model/wallet_address_list/wallet_account_list_header.dart";
import "package:cake_wallet/view_model/wallet_address_list/wallet_address_hidden_list_header.dart";
import "package:cake_wallet/view_model/wallet_address_list/wallet_address_list_header.dart";
import "package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/payment_uris.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_type.dart";
import "package:mobx/mobx.dart";

part "wallet_address_list_view_model.g.dart";

class WalletAddressListViewModel = WalletAddressListViewModelBase with _$WalletAddressListViewModel;

abstract class WalletAddressListViewModelBase extends WalletChangeListenerViewModel with Store {
  WalletAddressListViewModelBase({
    required AppStore appStore,
    required this.yatStore,
    required this.fiatConversionStore,
    required AddressService addressService,
  })  : _baseItems = <ListItem>[],
        selectedCurrency = appStore.wallet!.currency,
        hasAccounts = [WalletType.monero, WalletType.wownero].contains(appStore.wallet!.type),
        _appStore = appStore,
        _addressService = addressService,
        receivePageOption = appStore.wallet!.walletAddresses.walletInfo.addressPageType ?? "",
        super(appStore: appStore) {
    _init();
  }

  final AddressService _addressService;

  @computed
  int? get selectedChainId => wallet.chainId;

  @override
  void onWalletChange(wallet) {
    _init();

    selectedCurrency = wallet.currency;
    hasAccounts = [WalletType.monero, WalletType.wownero, WalletType.haven].contains(wallet.type);
  }

  final FiatConversionStore fiatConversionStore;
  final AppStore _appStore;

  double? _fiatRate;

  List<Currency> get currencies => [tokenCurrency ?? wallet.currency, ...FiatCurrency.all];

  List<Currency> get tokenCurrencies => wallet.balance.keys.toList();

  @observable
  CryptoCurrency? tokenCurrency;

  @computed
  String get cryptoCurrencySymbol =>
      _appStore.amountParsingProxy.getCryptoSymbol(tokenCurrency ?? wallet.currency);

  void setTokenCurrency(Currency curr) {
    if (curr == wallet.currency || curr == CryptoCurrency.btcln) {
      tokenCurrency = null;
      selectedCurrency = wallet.currency;
      return;
    }

    tokenCurrency = curr as CryptoCurrency;
    if (selectedCurrency is CryptoCurrency) {
      selectedCurrency = curr;
    }
  }

  String get buttonTitle {
    if (isElectrumWallet) {
      return S.current.addresses;
    }

    return hasAccounts ? S.current.accounts_subaddresses : S.current.addresses;
  }

  @observable
  Currency selectedCurrency;

  @computed
  String get selectedCurrencySymbol => selectedCurrency is CryptoCurrency
      ? _appStore.amountParsingProxy.getCryptoSymbol(selectedCurrency as CryptoCurrency)
      : selectedCurrency.name.toUpperCase();

  @computed
  int get selectedCurrencyDecimals => useSatoshi ? 0 : selectedCurrency.decimals;

  @computed
  bool get useSatoshi =>
      selectedCurrency is CryptoCurrency &&
      _appStore.amountParsingProxy.useSatoshi(selectedCurrency as CryptoCurrency);

  @observable
  String searchText = "";

  @computed
  int get selectedCurrencyIndex => currencies.indexOf(selectedCurrency);

  @computed
  int get tokenCurrencyIndex => tokenCurrency == null ? 0 : tokenCurrencies.indexOf(tokenCurrency!);

  @observable
  String _amount = "";

  @computed
  String get displayAmount => _appStore.amountParsingProxy
      .getDisplayCryptoAmount(_amount, tokenCurrency ?? wallet.currency);

  // NOT PRECISE! just for display purposes.
  @computed
  String get fiatAmount {
    if (_amount.isEmpty) return "";
    var cryptoCurrency = tokenCurrency ?? wallet.currency;
    if (cryptoCurrency == CryptoCurrency.btcln) cryptoCurrency = CryptoCurrency.btc;
    if (selectedCurrency is FiatCurrency && _fiatRate != null) {
      return selectedCurrencyFiatAmount;
    }

    if (!fiatConversionStore.prices.containsKey(cryptoCurrency)) return "";
    final amount = double.tryParse(_amount) ?? 0;
    return (amount * fiatConversionStore.prices[cryptoCurrency]!).toStringAsFixed(2);
  }

  @computed
  String get selectedCurrencyFiatAmount {
    if (_fiatRate == null) return "";
    final amount = double.tryParse(_amount) ?? 0;
    return (amount * _fiatRate!).toStringAsFixed(2);
  }

  @action
  Future<void> dismissInfobox() => _addressService.dismissInfobox();

  // payjoinEndpoint getter is broken, but uri works
  bool get hasPayjoin =>
      wallet.type == WalletType.bitcoin &&
      !isLightning &&
      !isSilentPayments &&
      uri.toString().contains("payjo.in");

  AmountParsingProxy get amountParsingProxy => _appStore.amountParsingProxy;

  @computed
  FiatCurrency get fiatCurrency => _appStore.settingsStore.fiatCurrency;

  @computed
  bool get isFiatDisabled => _appStore.settingsStore.fiatApiMode == FiatApiMode.disabled;

  @computed
  WalletType get type => wallet.type;

  @computed
  WalletAddressListItem get address =>
      WalletAddressListItem(address: wallet.walletAddresses.address, isPrimary: false);

  @computed
  String get payjoinEndpoint => _addressService.payjoinEndpoint;

  @computed
  bool get isPayjoinUnavailable => _addressService.isPayjoinUnavailable;

  @observable
  PaymentURI? _lnPaymentRequest;

  @computed
  PaymentURI get uri {
    if (isLightning && _lnPaymentRequest != null) return _lnPaymentRequest!;
    return _addressService.buildPaymentUri(rawAmount: _amount, token: tokenCurrency);
  }

  bool get isPayjoinAvailable => !isPayjoinUnavailable && !isSilentPayments && !isLightning;

  @computed
  ObservableList<ListItem> get items => ObservableList<ListItem>()
    ..addAll(_baseItems)
    ..addAll(addressList);

  ObservableList<ListItem> _computeAddressList() {
    final addressList = ObservableList<ListItem>();

    for (final group in _addressService.computeAddressList()) {
      if (group.header is SilentPaymentsReceivedHeader) {
        addressList.add(WalletAddressListHeader(title: S.current.received));
      }
      addressList.addAll(group.entries.map(_toListItem));
    }

    if (searchText.isNotEmpty) {
      final searchTerm = searchText.toLowerCase();
      return ObservableList.of(addressList.where((item) {
        if (item is WalletAddressListItem) {
          return item.address.toLowerCase().contains(searchTerm);
        }
        return false;
      }));
    }

    return addressList;
  }

  WalletAddressListItem _toListItem(AddressEntry e) => WalletAddressListItem(
        id: e.id,
        address: e.address,
        name: e.label,
        isPrimary: e.isPrimary,
        isChange: e.isChange,
        isHidden: e.isHidden,
        isManual: e.isManual,
        isLegacyDerivation: e.isLegacyDerivation,
        isOneTimeReceiveAddress: e.isOneTimeReceiveAddress,
        derivationPath: e.derivationPath,
        txCount: e.txCount,
        balance: e.balance,
      );

  @computed
  ObservableList<ListItem> get addressList {
    return _computeAddressList();
  }

  List<ListItem> get forceRecomputeItems {
    // necessary because the addressList contains non-observable items
    List<ListItem> recomputed = [];
    recomputed.addAll(_baseItems);
    recomputed.addAll(_computeAddressList());
    return recomputed;
  }

  Future<void> toggleHideAddress(WalletAddressListItem item) async {
    item.isHidden = !item.isHidden;
    await _addressService.setHidden(item.address, hidden: item.isHidden);
  }

  @observable
  bool hasAccounts;

  @computed
  String get accountLabel => _addressService.currentAccount?.label ?? "";

  @computed
  bool get hasTokensList => hasTokens(type);

  @computed
  String get walletTypeName => walletTypeToString(type);

  @computed
  bool get hasAddressList =>
      [
        WalletType.monero,
        WalletType.wownero,
        WalletType.haven,
        WalletType.bitcoinCash,
        WalletType.bitcoin,
        WalletType.litecoin,
        WalletType.decred,
        WalletType.dogecoin,
        WalletType.zcash
      ].contains(wallet.type) &&
      !isLightning &&
      isZCashTransparent;

  @computed
  bool get hasAddressRotation => hasAddressList && wallet.type != WalletType.zcash;

  @computed
  bool get isElectrumWallet => [
        WalletType.bitcoin,
        WalletType.litecoin,
        WalletType.bitcoinCash,
        WalletType.dogecoin
      ].contains(wallet.type);

  List<String> getWalletImages(int? chainId) {
    if (chainId != null) {
      switch (chainId) {
        case 1:
          return [
            "assets/new-ui/crypto_full_icons/ethereum.svg",
            "assets/images/usdc_icon.svg",
            "assets/images/usdt_wallet_icon.svg",
            "assets/images/deuro_icon.svg",
            "assets/images/more_tokens.svg",
          ];
        case 137:
          return [
            "assets/new-ui/crypto_full_icons/polygon.svg",
            "assets/images/eth_pol_icon.svg",
            "assets/images/usdc_icon.svg",
            "assets/images/usdt_wallet_icon.svg",
            "assets/images/more_tokens.svg",
          ];
        case 8453:
          return [
            "assets/new-ui/crypto_full_icons/ethereum.svg",
            "assets/images/usdc_icon.svg",
            "assets/images/more_tokens.svg",
          ];
        case 42161:
          return [
            "assets/new-ui/crypto_full_icons/arbitrum.svg",
            "assets/images/usdc_icon.svg",
            "assets/images/more_tokens.svg",
          ];
        case 56:
          return [
            "assets/new-ui/crypto_full_icons/bnb.svg",
            "assets/images/usdc_icon.svg",
            "assets/images/usdt_wallet_icon.svg",
            "assets/images/more_tokens.svg",
          ];
        default:
          return [
            "assets/new-ui/crypto_full_icons/ethereum.svg",
            "assets/images/usdc_icon.svg",
            "assets/images/usdt_wallet_icon.svg",
          ];
      }
    }

    switch (wallet.type) {
      case WalletType.solana:
        return [
          "assets/images/sol_icon.svg",
          "assets/images/usdc_icon.svg",
          "assets/images/usdt_wallet_icon.svg",
          "assets/images/more_tokens.svg",
        ];
      case WalletType.tron:
        return [
          "assets/images/trx_icon.svg",
          "assets/images/usdc_icon.svg",
          "assets/images/usdt_wallet_icon.svg",
          "assets/images/more_tokens.svg",
        ];
      case WalletType.zano:
        return [
          "assets/images/zano_icon.svg",
          "assets/images/more_tokens.svg",
        ];
      default:
        return [];
    }
  }

  @computed
  String get qrImage {
    if (isLightning) return "assets/images/btc_chain_qr_lightning.svg";
    return getQrImage(type);
  }

  @computed
  String get monoImage => getChainMonoImage(type);

  @computed
  bool get isBalanceAvailable => isElectrumWallet;

  @computed
  bool get isReceivedAvailable => [WalletType.monero, WalletType.wownero].contains(wallet.type);

  @computed
  bool get isSilentPayments => _addressService.isSilentPayments;

  @computed
  bool get isLightning =>
      wallet.type == WalletType.bitcoin &&
      (wallet.walletAddresses.getPaymentUri(_amount) is LightningPaymentRequest);

  @computed
  bool get isZCashTransparent {
    receivePageOption;
    return _addressService.isZCashTransparent;
  }

  @observable
  String receivePageOption;

  @computed
  bool get isBitcoinViewOnly => _addressService.isBitcoinViewOnly;

  @computed
  bool get isAutoGenerateSubaddressEnabled => _addressService.isAutoGenerateSubaddressEnabled;

  @computed
  bool get showAddManualAddresses =>
      !isAutoGenerateSubaddressEnabled ||
      [WalletType.monero, WalletType.wownero].contains(wallet.type);

  List<ListItem> _baseItems;

  final YatStore yatStore;

  @action
  void setAddress(WalletAddressListItem address) =>
      wallet.walletAddresses.address = address.address;

  @observable
  bool isRotatingAddress = false;

  @action
  Future<void> rotateAddress() async {
    if (isRotatingAddress) {
      return;
    }
    try {
      isRotatingAddress = true;
      await _addressService.rotateAddress();
    } finally {
      isRotatingAddress = false;
    }
  }

  @action
  Future<void> setAddressType(dynamic option) async {
    receivePageOption = option.toString();
    await _addressService.setAddressTypeRaw(option);
  }

  void _init() {
    _baseItems = [];

    if (wallet.walletAddresses.hiddenAddresses.isNotEmpty) {
      _baseItems.add(WalletAddressHiddenListHeader());
    }

    if ([
      WalletType.monero,
      WalletType.wownero,
      WalletType.haven,
    ].contains(wallet.type)) {
      _baseItems.add(WalletAccountListHeader());
    }

    if (![WalletType.nano, WalletType.banano].contains(wallet.type)) {
      _baseItems.add(WalletAddressListHeader());
    }
    if (wallet.isEnabledAutoGenerateSubaddress) {
      wallet.walletAddresses.address = wallet.walletAddresses.latestAddress;
    }
  }

  @action
  void selectCurrency(Currency currency) {
    selectedCurrency = currency;

    if (currency is FiatCurrency && _appStore.settingsStore.fiatCurrency != currency) {
      final cryptoCurrency = wallet.currency;

      FiatConversionService.fetchPrice(
        crypto: cryptoCurrency,
        fiat: currency,
        torOnly: _appStore.settingsStore.fiatApiMode == FiatApiMode.torOnly,
      ).then((value) {
        _fiatRate = value;
        _convertAmountToCrypto();
      });
    }
  }

  @action
  void changeAmount(String amount) {
    if (selectedCurrency is FiatCurrency) {
      this._amount = amount;
      _convertAmountToCrypto();
    } else if (selectedCurrency is CryptoCurrency) {
      this._amount = _appStore.amountParsingProxy
          .getCanonicalCryptoAmount(amount, selectedCurrency as CryptoCurrency);
    }
    if (isLightning) {
      _addressService
          .fetchPaymentRequestUri(rawAmount: this._amount, token: tokenCurrency)
          .then((uri) => _lnPaymentRequest = uri);
    }
  }

  @action
  void updateSearchText(String text) {
    searchText = text;
  }

  @action
  void _convertAmountToCrypto() {
    var cryptoCurrency = tokenCurrency ?? wallet.currency;
    if (cryptoCurrency == CryptoCurrency.btcln) {
      cryptoCurrency = CryptoCurrency.btc;
    }
    final fiatRate = _fiatRate ?? (fiatConversionStore.prices[cryptoCurrency] ?? 0.0);

    if (fiatRate <= 0.0) {
      printV("invalid fiat rate $fiatRate");
      _amount = "";
      return;
    }

    try {
      final crypto = (double.parse(_amount.replaceAll(",", ".")) / fiatRate).toStringAsFixed(8);
      if (_amount != crypto) {
        _amount = crypto;
      }
    } catch (e) {
      _amount = "";
    }
  }

  @action
  void deleteAddress(ListItem item) {
    if (item is WalletAddressListItem) {
      _addressService.deleteSilentPaymentAddress(item.address);
    }
  }
}
