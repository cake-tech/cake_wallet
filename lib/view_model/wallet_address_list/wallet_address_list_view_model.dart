import 'dart:core';
import 'dart:developer' as dev;

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/core/wallet_change_listener_view_model.dart';
import 'package:cake_wallet/decred/decred.dart';
import 'package:cake_wallet/entities/auto_generate_subaddress_status.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/reactions/wallet_utils.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/yat/yat_store.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/utils/list_item.dart';
import 'package:cake_wallet/utils/qr_util.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_account_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_hidden_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_util.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cake_wallet/zcash/zcash.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'wallet_address_list_view_model.g.dart';

class WalletAddressListViewModel = WalletAddressListViewModelBase with _$WalletAddressListViewModel;

abstract class WalletAddressListViewModelBase extends WalletChangeListenerViewModel with Store {
  WalletAddressListViewModelBase({
    required AppStore appStore,
    required this.yatStore,
    required this.fiatConversionStore,
  })  : _baseItems = <ListItem>[],
        selectedCurrency = appStore.wallet!.currency,
        hasAccounts = [WalletType.monero, WalletType.wownero].contains(appStore.wallet!.type),
        _appStore = appStore,
        super(appStore: appStore) {
    _init();
  }

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

  List<Currency> get currencies =>
      [tokenCurrency ?? wallet.currency, ...FiatCurrency.all];

  List<Currency> get tokenCurrencies => wallet.balance.keys.toList();

  @observable
  CryptoCurrency? tokenCurrency;

  @computed
  String get cryptoCurrencySymbol =>
      _appStore.amountParsingProxy.getCryptoSymbol(tokenCurrency ?? wallet.currency);

  void setTokenCurrency(Currency curr) {
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
  String searchText = '';

  @computed
  int get selectedCurrencyIndex => currencies.indexOf(selectedCurrency);

  @computed
  int get tokenCurrencyIndex => tokenCurrency == null ? 0 : tokenCurrencies.indexOf(tokenCurrency!);

  @observable
  String _amount = '';

  @computed
  String get displayAmount => _appStore.amountParsingProxy
      .getDisplayCryptoAmount(_amount, tokenCurrency ?? wallet.currency);

  // NOT PRECISE! just for display purposes.
  @computed
  String get fiatAmount {
    if (_amount.isEmpty) return "";
    var cryptoCurrency = tokenCurrency ?? wallet.currency;
    if (cryptoCurrency == CryptoCurrency.btcln) cryptoCurrency = CryptoCurrency.btc;
    if (!fiatConversionStore.prices.containsKey(cryptoCurrency)) return "";
    return (double.parse(_amount) * fiatConversionStore.prices[cryptoCurrency]!).toStringAsFixed(2);
  }

  @computed
  String get selectedCurrencyFiatAmount {
    if (_fiatRate == null) return "";
    return (double.parse(_amount) * _fiatRate!).toStringAsFixed(2);
  }

  @action
  Future<void> dismissInfobox() async {
    wallet.walletInfo.receiveInfoboxDismissed = true;
    await wallet.walletInfo.save();
  }

  @computed
  FiatCurrency get fiatCurrency => _appStore.settingsStore.fiatCurrency;

  @computed
  WalletType get type => wallet.type;

  @computed
  WalletAddressListItem get address =>
      WalletAddressListItem(address: wallet.walletAddresses.address, isPrimary: false);

  @computed
  String get payjoinEndpoint =>
      wallet.type == WalletType.bitcoin ? bitcoin!.getPayjoinEndpoint(wallet) : "";

  @computed
  bool get isPayjoinUnavailable =>
      wallet.type == WalletType.bitcoin &&
      _appStore.settingsStore.usePayjoin &&
      payjoinEndpoint.isEmpty;

  @observable
  PaymentURI? _lnPaymentRequest;

  @computed
  PaymentURI get uri {
    if (tokenCurrency != null && isEVMCompatibleChain(wallet.type)) {
      return ERC681URI(
          chainId: wallet.chainId ?? 1,
          address: wallet.walletAddresses.address,
          amount: _amount,
          contractAddress: (tokenCurrency as Erc20Token).contractAddress);
    }
    if (_lnPaymentRequest != null) return _lnPaymentRequest!;
    return wallet.walletAddresses.getPaymentUri(_amount);
  }

  bool get isPayjoinAvailable => !isPayjoinUnavailable && !isSilentPayments && !isLightning;

  @computed
  ObservableList<ListItem> get items => ObservableList<ListItem>()
    ..addAll(_baseItems)
    ..addAll(addressList);

  ObservableList<ListItem> _computeAddressList() {
    final addressList = ObservableList<ListItem>();

    if (wallet.type == WalletType.monero) {
      final primaryAddress = monero!.getSubaddressList(wallet).subaddresses.first;
      final addressItems = monero!.getSubaddressList(wallet).subaddresses.map((subaddress) {
        final isPrimary = subaddress == primaryAddress;

        return WalletAddressListItem(
          id: subaddress.id,
          isPrimary: isPrimary,
          name: subaddress.label,
          address: subaddress.address,
          balance: subaddress.received,
          txCount: subaddress.txCount,
        );
      });
      addressList.addAll(addressItems);
    }

    if (wallet.type == WalletType.wownero) {
      final primaryAddress = wownero!.getSubaddressList(wallet).subaddresses.first;
      final addressItems = wownero!.getSubaddressList(wallet).subaddresses.map((subaddress) {
        final isPrimary = subaddress == primaryAddress;

        return WalletAddressListItem(
            id: subaddress.id,
            isPrimary: isPrimary,
            name: subaddress.label,
            address: subaddress.address);
      });
      addressList.addAll(addressItems);
    }

    if (isElectrumWallet) {
      if (bitcoin!.hasSelectedSilentPayments(wallet)) {
        final addressItems = bitcoin!.getSilentPaymentAddresses(wallet).map((address) {
          final isPrimary = address.id == 0;

          return WalletAddressListItem(
            id: address.id,
            isPrimary: isPrimary,
            name: address.name,
            address: address.address,
            txCount: address.txCount,
            balance: _appStore.amountParsingProxy
                .getDisplayCryptoString(address.balance, walletTypeToCryptoCurrency(type)),
            isChange: address.isChange,
          );
        });
        addressList.addAll(addressItems);
        addressList.add(WalletAddressListHeader(title: S.current.received));

        final receivedAddressItems =
            bitcoin!.getSilentPaymentReceivedAddresses(wallet).map((address) {
          return WalletAddressListItem(
            id: address.id,
            isPrimary: false,
            name: address.name,
            address: address.address,
            txCount: address.txCount,
            balance: _appStore.amountParsingProxy
                .getDisplayCryptoString(address.balance, walletTypeToCryptoCurrency(type)),
            isChange: address.isChange,
            isOneTimeReceiveAddress: true,
          );
        });
        addressList.addAll(receivedAddressItems);
      } else {
        var addressItems = bitcoin!.getSubAddresses(wallet).map((subaddress) {
          final isPrimary = subaddress.id == 0;

          return WalletAddressListItem(
              id: subaddress.id,
              isPrimary: isPrimary,
              name: subaddress.name,
              address: subaddress.address,
              txCount: subaddress.txCount,
              balance: _appStore.amountParsingProxy
                  .getDisplayCryptoString(subaddress.balance, walletTypeToCryptoCurrency(type)),
              isChange: subaddress.isChange);
        });

        // don't show all 1000+ mweb addresses:
        if (wallet.type == WalletType.litecoin && addressItems.length >= 1000) {
          // find the index of the last item with a txCount > 0
          final addressItemsList = addressItems.toList();
          int index = addressItemsList.lastIndexWhere((item) => (item.txCount ?? 0) > 0);
          if (index == -1) {
            index = 0;
          }
          // show only up to that index + 20:
          addressItems = addressItemsList.sublist(0, index + 20);
        }
        addressList.addAll(addressItems);
      }
    }

    if (isEVMCompatibleChain(wallet.type)) {
      final primaryAddress = evm!.getAddress(wallet);

      addressList.add(WalletAddressListItem(isPrimary: true, name: null, address: primaryAddress));
    }

    if (wallet.type == WalletType.solana) {
      final primaryAddress = solana!.getAddress(wallet);

      addressList.add(WalletAddressListItem(isPrimary: true, name: null, address: primaryAddress));
    }

    if (wallet.type == WalletType.nano) {
      addressList.add(WalletAddressListItem(
        isPrimary: true,
        name: null,
        address: wallet.walletAddresses.address,
      ));
    }

    if (wallet.type == WalletType.tron) {
      final primaryAddress = tron!.getAddress(wallet);

      addressList.add(WalletAddressListItem(isPrimary: true, name: null, address: primaryAddress));
    }

    if (wallet.type == WalletType.decred) {
      final addrInfos = decred!.getAddressInfos(wallet);
      addrInfos.forEach((info) {
        addressList.add(
            new WalletAddressListItem(isPrimary: false, address: info.address, name: info.label));
      });
    }

    if (wallet.type == WalletType.zcash) {
      final addrInfos = zcash!.getAddressInfos(wallet);
      addrInfos.forEach((info) {
        addressList.add(
            new WalletAddressListItem(isPrimary: false, address: info.address, name: info.label));
      });
    }

    for (var i = 0; i < addressList.length; i++) {
      if (!(addressList[i] is WalletAddressListItem)) continue;
      (addressList[i] as WalletAddressListItem).isHidden = wallet.walletAddresses.hiddenAddresses
          .contains((addressList[i] as WalletAddressListItem).address);
    }

    for (var i = 0; i < addressList.length; i++) {
      if (!(addressList[i] is WalletAddressListItem)) continue;
      (addressList[i] as WalletAddressListItem).isManual = wallet.walletAddresses.manualAddresses
          .contains((addressList[i] as WalletAddressListItem).address);
    }

    if (wallet.type == WalletType.zano) {
      final primaryAddress = zano!.getAddress(wallet);

      addressList.add(WalletAddressListItem(isPrimary: true, name: null, address: primaryAddress));
    }

    if (searchText.isNotEmpty) {
      return ObservableList.of(addressList.where((item) {
        if (item is WalletAddressListItem) {
          return item.address.toLowerCase().contains(searchText.toLowerCase());
        }
        return false;
      }));
    }

    return addressList;
  }

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
    if (item.isHidden) {
      item.isHidden = false;
      wallet.walletAddresses.hiddenAddresses.removeWhere((element) => element == item.address);
    } else {
      item.isHidden = true;
      wallet.walletAddresses.hiddenAddresses.add(item.address);
    }
    // update the address list:
    await wallet.walletAddresses.saveAddressesInBox();
    if (wallet.type == WalletType.monero) {
      monero!
          .getSubaddressList(wallet)
          .update(wallet, accountIndex: monero!.getCurrentAccount(wallet).id);
    } else if (wallet.type == WalletType.wownero) {
      wownero!
          .getSubaddressList(wallet)
          .update(wallet, accountIndex: wownero!.getCurrentAccount(wallet).id);
    }
  }

  @observable
  bool hasAccounts;

  @computed
  String get accountLabel {
    switch (wallet.type) {
      case WalletType.monero:
        return monero!.getCurrentAccount(wallet).label;
      case WalletType.wownero:
        wownero!.getCurrentAccount(wallet).label;
      default:
        return '';
    }
    return '';
  }

  @computed
  bool get hasTokensList => hasTokens(type);

  @computed
  String get walletTypeName => walletTypeToString(type);

  @computed
  bool get hasAddressList => [
        WalletType.monero,
        WalletType.wownero,
        WalletType.haven,
        WalletType.bitcoinCash,
        WalletType.bitcoin,
        WalletType.litecoin,
        WalletType.decred,
        WalletType.dogecoin,
        WalletType.zcash
      ].contains(wallet.type) && !isLightning && isZCashTransparent;

  @computed
  bool get hasAddressRotation => [
    WalletType.monero,
    WalletType.wownero,
    WalletType.haven,
    WalletType.bitcoinCash,
    WalletType.bitcoin,
    WalletType.litecoin,
    WalletType.decred,
    WalletType.dogecoin,
  ].contains(wallet.type);

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
            'assets/images/crypto/ethereum.webp',
            'assets/images/usdc_icon.svg',
            'assets/images/usdt_wallet_icon.svg',
            'assets/images/deuro_icon.svg',
            'assets/images/more_tokens.svg',
          ];
        case 137:
          return [
            'assets/images/crypto/polygon.webp',
            'assets/images/eth_pol_icon.svg',
            'assets/images/usdc_icon.svg',
            'assets/images/usdt_wallet_icon.svg',
            'assets/images/more_tokens.svg',
          ];
        case 8453:
          return [
            'assets/images/crypto/ethereum.webp',
            'assets/images/usdc_icon.svg',
            'assets/images/more_tokens.svg',
          ];
        case 42161:
          return [
            'assets/images/crypto/arbitrum.webp',
            'assets/images/usdc_icon.svg',
            'assets/images/more_tokens.svg',
          ];
        case 56:
          return [
            'assets/images/crypto/BNB.webp',
            'assets/images/usdc_icon.svg',
            'assets/images/usdt_wallet_icon.svg',
            'assets/images/more_tokens.svg',
          ];
        default:
          return [
            'assets/images/crypto/ethereum.webp',
            'assets/images/usdc_icon.svg',
            'assets/images/usdt_wallet_icon.svg',
          ];
      }
    }

    switch (wallet.type) {
      case WalletType.solana:
        return [
          'assets/images/sol_icon.svg',
          'assets/images/usdc_icon.svg',
          'assets/images/usdt_wallet_icon.svg',
          'assets/images/more_tokens.svg',
        ];
      case WalletType.tron:
        return [
          'assets/images/trx_icon.svg',
          'assets/images/usdc_icon.svg',
          'assets/images/usdt_wallet_icon.svg',
          'assets/images/more_tokens.svg',
        ];
      case WalletType.zano:
        return [
          'assets/images/zano_icon.svg',
          'assets/images/more_tokens.svg',
        ];
      default:
        return [];
    }
  }

  @computed
  String get qrImage {
    if (isLightning) return 'assets/images/btc_chain_qr_lightning.svg';
    return getQrImage(type);
  }

  @computed
  String get monoImage => getChainMonoImage(type);

  @computed
  bool get isBalanceAvailable => isElectrumWallet;

  @computed
  bool get isReceivedAvailable => [WalletType.monero, WalletType.wownero].contains(wallet.type);

  @computed
  bool get isSilentPayments =>
      wallet.type == WalletType.bitcoin && bitcoin!.hasSelectedSilentPayments(wallet);

  @computed
  bool get isLightning => wallet.type == WalletType.bitcoin && (uri is LightningPaymentRequest);

  @computed
  bool get isZCashTransparent =>
      wallet.type == WalletType.zcash && zcash!.hasSelectedTransparentAddress(wallet);

  @computed
  bool get isBitcoinViewOnly =>
      wallet.type == WalletType.bitcoin &&
      (bitcoin!.getWalletKeys(wallet)["privateKey"] ?? "").isEmpty;

  @computed
  bool get isAutoGenerateSubaddressEnabled =>
      _appStore.settingsStore.autoGenerateSubaddressStatus !=
          AutoGenerateSubaddressStatus.disabled &&
      !isSilentPayments;

  @computed
  bool get showAddManualAddresses =>
      !isAutoGenerateSubaddressEnabled ||
      [WalletType.monero, WalletType.wownero].contains(wallet.type);

  List<ListItem> _baseItems;

  final YatStore yatStore;

  @action
  void setAddress(WalletAddressListItem address) =>
      wallet.walletAddresses.address = address.address;

  @action
  Future<void> rotateAddress() async {
    await createNewAddress(wallet, "");
    if (isElectrumWallet) {
      wallet.walletAddresses.address = (addressList.last as WalletAddressListItem).address;
    }
  }

  @action
  Future<void> setAddressType(dynamic option) async {
    if ([WalletType.bitcoin, WalletType.litecoin].contains(wallet.type)) {
      await bitcoin!.setAddressType(wallet, option);
    }
    if (wallet.type == WalletType.zcash) {
      await zcash!.setAddressType(wallet, option);
    }
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

    // reaction((_) => amount, (_) => refreshUri());
    // reaction((_) => address, (_) => refreshUri());
  }

  @action
  void selectCurrency(Currency currency) {
    selectedCurrency = currency;

    if (currency is FiatCurrency && _appStore.settingsStore.fiatCurrency != currency) {
      final cryptoCurrency = wallet.currency;

      dev.log("Requesting Fiat rate for $cryptoCurrency-$currency");
      FiatConversionService.fetchPrice(
        crypto: cryptoCurrency,
        fiat: currency,
        torOnly: _appStore.settingsStore.fiatApiMode == FiatApiMode.torOnly,
      ).then((value) {
        dev.log("Received Fiat rate 1 $cryptoCurrency = $value $currency");
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
      wallet.walletAddresses
          .getPaymentRequestUri(this._amount)
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
    if (cryptoCurrency == CryptoCurrency.btcln) cryptoCurrency = CryptoCurrency.btc;
    final fiatRate = _fiatRate ?? (fiatConversionStore.prices[cryptoCurrency] ?? 0.0);

    if (fiatRate <= 0.0) {
      dev.log("Invalid Fiat Rate $fiatRate");
      _amount = '';
      return;
    }

    try {
      final crypto = (double.parse(_amount.replaceAll(',', '.')) / fiatRate).toStringAsFixed(8);
      if (_amount != crypto) {
        _amount = crypto;
      }
    } catch (e) {
      _amount = '';
    }
  }

  @action
  void deleteAddress(ListItem item) {
    if (wallet.type == WalletType.bitcoin && item is WalletAddressListItem) {
      bitcoin!.deleteSilentPaymentAddress(wallet, item.address);
    }
  }
}
