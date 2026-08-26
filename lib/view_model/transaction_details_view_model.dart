import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/address_validator.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/calculate_fiat_amount_raw.dart";
import "package:cake_wallet/entities/priority_for_wallet_type.dart";
import "package:cake_wallet/entities/transaction_description.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/src/screens/transaction_details/address_list_item.dart";
import "package:cake_wallet/src/screens/transaction_details/confirmations_list_item.dart";
import "package:cake_wallet/src/screens/transaction_details/rbf_details_list_fee_picker_item.dart";
import "package:cake_wallet/src/screens/transaction_details/standart_list_item.dart";
import "package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart";
import "package:cake_wallet/src/screens/transaction_details/transaction_expandable_list_item.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cake_wallet/view_model/send/send_view_model.dart";
import "package:cake_wallet/zano/zano.dart";
import "package:collection/collection.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_amount_format.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/transaction_priority.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/foundation.dart";
import "package:hive/hive.dart";
import "package:intl/intl.dart";
import "package:mobx/mobx.dart";
import "package:url_launcher/url_launcher.dart";

part "transaction_details_view_model.g.dart";

bool _trueFunc(_) => true;

/// We're adding a regex here so we can remove any already saved address that has the account in it.
/// In the refactor, we will make another separate variable for accounts and the UI would handle it as needed.
String _moneroRecipientAddressForDisplay(String raw, WalletType walletType) {
  if (walletType != WalletType.monero || raw.isEmpty) {
    return raw;
  }

  final compact = raw.replaceAll(RegExp(r"\s"), "");
  final match = RegExp(
    r"4[0-9a-zA-Z]{94}|8[0-9a-zA-Z]{94}|[0-9a-zA-Z]{106}",
    caseSensitive: false,
  ).firstMatch(compact);
  return match?.group(0) ?? raw.trim();
}

bool isLightning(TransactionInfo tx) => (tx.additionalInfo["isLightning"] as bool?) ?? false;

class TransactionAddressBreakdownItem {
  TransactionAddressBreakdownItem({
    required this.address,
    required this.amount,
    required this.rawAmount,
    required this.isChange,
    this.isUnspent,
    this.txCount,
    this.balanceDisplay,
  });

  final String address;
  final String amount;
  final int rawAmount;
  final bool isChange;

  /// Only meaningful for change entries: whether this output is still
  /// sitting unspent in the wallet's current UTXO set.
  final bool? isUnspent;
  final int? txCount;
  final String? balanceDisplay;
}

bool hasLightningPreimage(TransactionInfo tx) => (tx.additionalInfo["preimage"] as String?) != null;

class TxDetailRowDefinition {
  TxDetailRowDefinition({
    required this.keyString,
    required this.title,
    required this.valueGetter,
    this.applicable = _trueFunc,
    this.listItemBuilder = StandartListItem.new,
    this.advanced = false,
  });

  final String keyString;
  final String title;
  final String Function(TransactionDetailsViewModelBase) valueGetter;
  final bool Function(TransactionDetailsViewModelBase) applicable;

  /// If true, this row is shown on the secondary "Advanced Info" page
  /// instead of the main transaction details list.
  final bool advanced;

  final dynamic Function({
    required String title,
    required String value,
    required Key key,
  }) listItemBuilder;

  static final List<TxDetailRowDefinition> defs = [
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_details_date_key",
      title: S.current.transaction_details_date,
      valueGetter: (vm) => DateFormat("d MMMM yyyy, HH:mm", vm._appStore.settingsStore.languageCode)
          .format(vm.transactionInfo.date),
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_details_height_key",
      title: S.current.transaction_details_height,
      valueGetter: (vm) => vm.transactionInfo.height?.toString() ?? "",
      applicable: (vm) =>
          ![WalletType.solana, WalletType.tron].contains(vm.wallet.type) ||
          !isLightning(vm.transactionInfo),
      advanced: true,
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_details_fee_key",
      title: S.current.transaction_details_fee,
      valueGetter: (vm) => vm.transactionInfo.fee != null ? vm.feeAmount : "…",
      applicable: (vm) =>
          vm.wallet.type != WalletType.nano &&
          vm.transactionInfo.direction != TransactionDirection.incoming &&
          !vm.hasForeignInputs &&
          ((vm.transactionInfo.fee?.toStringWithSymbol() ?? "").isNotEmpty || vm.isFetchingFee),
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_details_advanced_fee_key",
      title: S.current.tx_fee,
      // See the non-advanced fee row above for why this must be non-empty.
      valueGetter: (vm) => vm.transactionInfo.fee != null ? vm.feeAmount : "…",
      applicable: (vm) =>
          electrumWalletTypes.contains(vm.wallet.type) &&
          (vm.transactionInfo.fee != null || vm.isFetchingFee),
      advanced: true,
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_details_size_key",
      title: S.current.size,
      valueGetter: (vm) => "${vm.transactionInfo.additionalInfo['txSize']} bytes",
      applicable: (vm) =>
          electrumWalletTypes.contains(vm.wallet.type) &&
          vm.transactionInfo.additionalInfo['txSize'] != null,
      advanced: true,
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_details_fee_rate_key",
      title: S.current.tx_fee_rate,
      valueGetter: (vm) => vm.feeRate,
      applicable: (vm) =>
          electrumWalletTypes.contains(vm.wallet.type) &&
          vm.transactionInfo.fee != null &&
          vm.transactionInfo.additionalInfo['txSize'] != null,
      advanced: true,
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_confirmations_key",
      title: S.current.confirmations,
      valueGetter: (vm) => "${vm.transactionInfo.confirmations}/${vm.neededConfirmations}",
      applicable: (vm) =>
          [...electrumWalletTypes, ...evmWalletTypes, WalletType.zcash, WalletType.monero]
              .contains(vm.wallet.type) &&
          !isLightning(vm.transactionInfo),
      listItemBuilder: ConfirmationsListItem.new,
      advanced: true,
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_details_recipient_address_key",
      title: S.current.transaction_details_recipient_address,
      valueGetter: (vm) {
        String? ret;

        switch (vm.wallet.type) {
          case WalletType.monero:
            if (vm.transactionInfo.direction == TransactionDirection.incoming) {
              ret = monero!.getTransactionAddress(
                vm.wallet,
                vm.transactionInfo.additionalInfo["accountIndex"] as int,
                vm.transactionInfo.additionalInfo["addressIndex"] as int,
              );
            }
          case WalletType.bitcoin:
            ret = (bitcoin!.getTransactionAddresses(vm.wallet, vm.transactionInfo) ?? [])
                    .firstOrNull ??
                "";
          case WalletType.tron:
            if (vm.transactionInfo.to != null) {
              ret = tron!.getTronBase58Address(vm.transactionInfo.to!, vm.wallet);
            }
          default:
            break;
        }
        ret ??= vm.transactionInfo.to ?? "";

        final resolvedAddress = _moneroRecipientAddressForDisplay(ret, vm.wallet.type);
        vm.isRecipientAddressShown = resolvedAddress.isNotEmpty;
        return resolvedAddress;
      },
      applicable: (vm) =>
          vm.showRecipientAddress &&
          (vm.transactionInfo.to != null ||
              [WalletType.monero, WalletType.tron].contains(vm.wallet.type) ||
              vm.wallet.type == WalletType.bitcoin &&
                  vm.transactionInfo.direction == TransactionDirection.incoming),
      listItemBuilder: AddressListItem.new,
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_details_source_address_key",
      title: S.current.transaction_details_source_address,
      valueGetter: (vm) {
        switch (vm.wallet.type) {
          case WalletType.tron:
            return tron!.getTronBase58Address(vm.transactionInfo.from!, vm.wallet);
          default:
            return vm.transactionInfo.from!;
        }
      },
      applicable: (vm) => vm.transactionInfo.from != null,
      listItemBuilder: AddressListItem.new,
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_address_label_key",
      title: S.current.address_label,
      valueGetter: (vm) => monero!.getSubaddressLabel(
        vm.wallet,
        vm.transactionInfo.additionalInfo["accountIndex"] as int,
        vm.transactionInfo.additionalInfo["addressIndex"] as int,
      ),
      applicable: (vm) => vm.wallet.type == WalletType.monero,
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_key",
      title: S.current.transaction_key,
      valueGetter: (vm) {
        final descriptionKey =
            "${vm.transactionInfo.txHash}_${vm.wallet.walletAddresses.primaryAddress}";

        final description = vm.transactionDescriptionBox.values.firstWhere(
          (val) => val.id == descriptionKey || val.id == vm.transactionInfo.txHash,
          orElse: () => TransactionDescription(id: descriptionKey),
        );
        return vm.transactionInfo.additionalInfo["key"] as String? ??
            description.transactionKey ??
            "";
      },
      applicable: (vm) => vm.wallet.type == WalletType.monero,
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_lightning_preimage",
      title: S.current.transaction_preimage,
      valueGetter: (vm) => vm.transactionInfo.additionalInfo["preimage"] as String? ?? "",
      applicable: (vm) =>
          hasLightningPreimage(vm.transactionInfo) && isLightning(vm.transactionInfo),
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_confirmed_key",
      title: S.current.confirmed_tx,
      valueGetter: (vm) => (vm.transactionInfo.confirmations > 0).toString(),
      applicable: (vm) => vm.wallet.type == WalletType.nano,
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_details_memo_key",
      title: S.current.memo,
      valueGetter: (vm) => vm.transactionInfo.additionalInfo["memo"] as String,
      applicable: (vm) =>
          vm.wallet.type == WalletType.zcash && vm.transactionInfo.additionalInfo["memo"] != null,
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_details_asset_id_key",
      title: S.current.asset_id,
      valueGetter: (vm) =>
          vm.transactionInfo.additionalInfo["assetId"] as String? ?? S.current.unknown_asset_id,
      applicable: (vm) => vm.wallet.type == WalletType.zano,
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_details_comment_key",
      title: S.current.transaction_details_title,
      valueGetter: (vm) => vm.transactionInfo.additionalInfo["comment"] as String? ?? "",
      applicable: (vm) => vm.wallet.type == WalletType.zano,
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_details_id_key",
      title: S.current.transaction_details_transaction_id,
      valueGetter: (vm) => vm.transactionInfo.txHash,
      advanced: true,
    ),
  ];
}

class TransactionDetailsViewModel = TransactionDetailsViewModelBase
    with _$TransactionDetailsViewModel;

abstract class TransactionDetailsViewModelBase with Store {
  TransactionDetailsViewModelBase({
    required this.transactionInfo,
    required this.transactionDescriptionBox,
    required this.wallet,
    required AppStore appStore,
    required this.sendViewModel,
    this.canReplaceByFee = false,
  })  : items = [],
        advancedItems = [],
        rbfListItems = [],
        newFee = 0,
        isRecipientAddressShown = false,
        _appStore = appStore,
        showRecipientAddress = appStore.settingsStore.shouldSaveRecipientAddress {
    final tx = transactionInfo;

    // Set before _rebuildStandardItems() so the fee row (with its spinner)
    // is present from the first frame, instead of popping in once
    // _watchFeeResolution resolves it later.
    isFetchingFee = electrumWalletTypes.contains(wallet.type) && transactionInfo.fee == null;

    _rebuildStandardItems();
    _checkForRBF(tx);

    // Watches this tx's resolution so the view refreshes once cw_bitcoin's
    // ElectrumTransactionResolver background loop reaches it.
    if (isFetchingFee && transactionInfo.direction != TransactionDirection.incoming) {
      _startWatchingFeeResolution();
    }
  }

  bool _feeResolutionWatchStarted = false;

  void _startWatchingFeeResolution() {
    if (_feeResolutionWatchStarted) {
      return;
    }
    _feeResolutionWatchStarted = true;
    _watchFeeResolution();
  }

  /// Starts watching this tx's resolution if it hasn't already - the
  /// constructor skips this eagerly for a receive (see above); called once
  /// Advanced Info is opened.
  void ensureFeeResolutionWatched() {
    if (isFetchingFee) {
      _startWatchingFeeResolution();
    }
  }

  /// (Re)builds [items]/[advancedItems] from [TxDetailRowDefinition.defs].
  /// Called at construction and again once resolution completes (see
  /// _applyResolvedFee) so newly-applicable rows appear without a fresh
  /// page navigation.
  void _rebuildStandardItems() {
    final newItems = <TransactionDetailsListItem>[];
    final newAdvancedItems = <TransactionDetailsListItem>[];

    for (final def in TxDetailRowDefinition.defs) {
      if (def.applicable(this)) {
        final listItem = def.listItemBuilder(
          title: def.title,
          value: def.valueGetter(this),
          key: ValueKey(def.keyString),
        ) as TransactionDetailsListItem;

        if (def.advanced) {
          newAdvancedItems.add(listItem);
        } else {
          newItems.add(listItem);
        }
      }
    }

    if (showRecipientAddress && !isRecipientAddressShown) {
      final descriptionKey = "${transactionInfo.txHash}_${wallet.walletAddresses.primaryAddress}";
      final description = transactionDescriptionBox.values.firstWhere(
        (val) => val.id == descriptionKey || val.id == transactionInfo.txHash,
        orElse: () => TransactionDescription(id: descriptionKey),
      );
      final recipientAddress = description.recipientAddress;

      if (recipientAddress?.isNotEmpty ?? false) {
        final recipientAddressForDisplay =
            _moneroRecipientAddressForDisplay(recipientAddress!, wallet.type);
        newItems.add(
          AddressListItem(
            title: S.current.transaction_details_recipient_address,
            value: recipientAddressForDisplay,
            key: ValueKey("standard_list_item_${recipientAddressForDisplay}_key"),
          ),
        );
      }
    }

    items = newItems;
    advancedItems = newAdvancedItems;
  }

  @action
  Future<void> _watchFeeResolution() async {
    try {
      final resolved = await bitcoin!.watchTransactionResolution(
        wallet,
        transactionInfo,
        onProgress: (resolved, total) => runInAction(() => _setFeeFetchProgress(resolved, total)),
      );
      if (resolved != null) {
        _applyResolvedFee(resolved);
      }
    } finally {
      isFetchingFee = false;
    }
  }

  @action
  void _setFeeFetchProgress(int resolved, int total) {
    feeFetchResolvedInputs = resolved;
    feeFetchTotalInputs = total;
  }

  @action
  void _applyResolvedFee(TransactionInfo resolved) {
    // Update amount/direction too, not just fee/additionalInfo: for a
    // partial-ownership send, the pre-resolution amount depends on the same
    // input resolution this fetch just completed.
    transactionInfo.amount = resolved.amount;
    transactionInfo.direction = resolved.direction;
    transactionInfo.fee = resolved.fee;
    transactionInfo.additionalInfo = resolved.additionalInfo;
    _rebuildStandardItems();
  }

  void updateNote(String note) {
    final descriptionKey = "${transactionInfo.txHash}_${wallet.walletAddresses.primaryAddress}";
    final description = transactionDescriptionBox.values.firstWhere(
      (val) => val.id == descriptionKey || val.id == transactionInfo.txHash,
      orElse: () => TransactionDescription(id: descriptionKey),
    );

    description.transactionNote = note;

    if (description.isInBox) {
      description.save();
    } else {
      transactionDescriptionBox.add(description);
    }
  }

  String get note {
    final descriptionKey = "${transactionInfo.txHash}_${wallet.walletAddresses.primaryAddress}";
    final description = transactionDescriptionBox.values.firstWhereOrNull(
      (val) => val.id == descriptionKey || val.id == transactionInfo.txHash,
    );
    return description?.transactionNote ?? "";
  }

  final TransactionInfo transactionInfo;
  final Box<TransactionDescription> transactionDescriptionBox;
  final WalletBase wallet;
  final SendViewModel sendViewModel;
  final AppStore _appStore;

  // Not final: _rebuildStandardItems() reassigns these once a fee fetch
  // resolves, so newly-applicable rows appear without a fresh navigation.
  @observable
  List<TransactionDetailsListItem> items;
  @observable
  List<TransactionDetailsListItem> advancedItems;
  final List<TransactionDetailsListItem> rbfListItems;

  @observable
  bool isFetchingFee = false;

  // Inputs resolved so far while isFetchingFee is true (e.g. "120/365").
  // feeFetchTotalInputs is 0 until the target tx's input count is known.
  @observable
  int feeFetchResolvedInputs = 0;
  @observable
  int feeFetchTotalInputs = 0;

  bool get hasAdvancedInfo => advancedItems.isNotEmpty || hasAddressBreakdown;
  bool get hasAddressBreakdown => addressBreakdown.isNotEmpty;
  bool showRecipientAddress;
  bool isRecipientAddressShown;
  int newFee;
  String? rawTransaction;
  TransactionPriority? transactionPriority;

  CryptoCurrency get transactionAsset {
    if (isEVMCompatibleChain(wallet.type)) {
      return evm!.assetOfTransaction(wallet, transactionInfo);
    }

    if (isLightning(transactionInfo)) {
      return CryptoCurrency.btcln;
    }

    return switch (wallet.type) {
      WalletType.solana => solana!.assetOfTransaction(wallet, transactionInfo),
      WalletType.tron => tron!.assetOfTransaction(wallet, transactionInfo),
      WalletType.zano => zano!.assetOfTransaction(wallet, transactionInfo) ?? CryptoCurrency.zano,
      _ => walletTypeToCryptoCurrency(wallet.type)
    };
  }

  @computed
  String get transactionAmount =>
      _appStore.amountParsingProxy.asDisplayStringWithSymbol(transactionInfo.amount);

  @computed
  String get transactionFiatAmount {
    final price = getIt.get<FiatConversionStore>().prices[transactionAsset];
    final fiatValue = calculateFiatAmountRaw(
      cryptoAmount: double.parse(transactionInfo.amount.toString()),
      price: price,
    ).withLocalSeperator(_appStore.settingsStore.languageCode);
    return "${_appStore.settingsStore.fiatCurrency.title} $fiatValue";
  }

  @computed
  String get feeAmount =>
      _appStore.amountParsingProxy.asDisplayStringWithSymbol(transactionInfo.fee!);

  @computed
  String get feeFiatAmount {
    final fee = transactionInfo.fee;
    if (fee == null) {
      return "";
    }
    final price = getIt.get<FiatConversionStore>().prices[transactionAsset];
    final fiatValue =
        calculateFiatAmountRaw(cryptoAmount: double.parse(fee.toString()), price: price)
            .withLocalSeperator(_appStore.settingsStore.languageCode);
    return "${_appStore.settingsStore.fiatCurrency.title} $fiatValue";
  }

  bool get isConfidentSend {
    final ownedInputs = transactionInfo.additionalInfo['ownedInputs'] as List?;
    final unresolvedInputTxids = transactionInfo.additionalInfo['unresolvedInputTxids'] as List?;
    return transactionInfo.direction == TransactionDirection.outgoing &&
        (ownedInputs?.isNotEmpty ?? false) &&
        (unresolvedInputTxids?.isEmpty ?? true);
  }

  String get feeTitle => isConfidentSend ? S.current.fee_paid : S.current.transaction_details_fee;

  /// Whether this is a co-spend transaction mixing in other parties' inputs,
  /// the fee row is hidden entirely for these, since this
  /// wallet's exact share of the recorded fee can't be known for certain.
  bool get hasForeignInputs {
    final totalInputCount = transactionInfo.additionalInfo['totalInputCount'] as int?;
    final ownedInputCount = (transactionInfo.additionalInfo['ownedInputs'] as List?)?.length ?? 0;
    return totalInputCount != null && ownedInputCount > 0 && ownedInputCount < totalInputCount;
  }

  // Mirrors fromElectrumBundle's partial-ownership correction. Not
  // Bitcoin-specific in principle, but isWalletDisplayAmountExact is only
  // ever written by ElectrumTransactionInfo, so this is naturally false
  // (never pending) for every other wallet type.
  bool get isAmountPending {
    // A partially-owned send's amount only grows as more inputs resolve, so
    // it's not final yet - only relevant for outgoing txs.
    if (transactionInfo.direction != TransactionDirection.outgoing) {
      return false;
    }
    final inputsOwnershipFullyResolved =
        transactionInfo.additionalInfo['inputsOwnershipFullyResolved'] as bool?;
    // Checked first: every input being resolved guarantees the amount is
    // exact, even over a stale isWalletDisplayAmountExact:false left by an
    // older buggy formula - safe since this tx will never be re-fetched
    // again to correct it.
    if (inputsOwnershipFullyResolved == true) {
      return false;
    }
    final isWalletDisplayAmountExact =
        transactionInfo.additionalInfo['isWalletDisplayAmountExact'] as bool?;
    // A fully self-owned send is exact once inputs are *locally* confirmed
    // ours, before inputsOwnershipFullyResolved (which waits on the fee too).
    if (isWalletDisplayAmountExact != null) {
      return !isWalletDisplayAmountExact;
    }
    // Old signal, for history persisted before isWalletDisplayAmountExact
    // existed - keeps it from looking pending again after an upgrade.
    return inputsOwnershipFullyResolved == false;
  }

  @computed
  bool get feeFetchFailed => !isFetchingFee && isAmountPending;

  @computed
  String get totalSentAmount {
    final fee = transactionInfo.fee;
    if (fee == null) {
      return "";
    }
    final total =
        Money.fromInt(transactionInfo.amount.amount.toInt() + fee.amount.toInt(), transactionAsset);
    return _appStore.amountParsingProxy.asDisplayStringWithSymbol(total);
  }

  @computed
  String get totalSentFiatAmount {
    final fee = transactionInfo.fee;
    if (fee == null) {
      return "";
    }
    final total = double.parse(transactionInfo.amount.toString()) + double.parse(fee.toString());
    final price = getIt.get<FiatConversionStore>().prices[transactionAsset];
    final fiatValue = calculateFiatAmountRaw(cryptoAmount: total, price: price)
        .withLocalSeperator(_appStore.settingsStore.languageCode);
    return "${_appStore.settingsStore.fiatCurrency.title} $fiatValue";
  }

  int get _changeReceivedRawAmount => addressBreakdown
      .where((entry) => entry.isChange)
      .fold<int>(0, (sum, entry) => sum + entry.rawAmount);

  @computed
  String get changeReceivedAmount {
    final rawAmount = _changeReceivedRawAmount;
    if (rawAmount <= 0) {
      return "";
    }
    return _appStore.amountParsingProxy
        .asDisplayStringWithSymbol(Money.fromInt(rawAmount, transactionAsset));
  }

  @computed
  String get changeReceivedFiatAmount {
    final rawAmount = _changeReceivedRawAmount;
    if (rawAmount <= 0) {
      return "";
    }
    final price = getIt.get<FiatConversionStore>().prices[transactionAsset];
    final fiatValue = calculateFiatAmountRaw(
      cryptoAmount: double.parse(Money.fromInt(rawAmount, transactionAsset).toString()),
      price: price,
    ).withLocalSeperator(_appStore.settingsStore.languageCode);
    return "${_appStore.settingsStore.fiatCurrency.title} $fiatValue";
  }

  @computed
  String get feeRate {
    final txSize = transactionInfo.additionalInfo['txSize'] as int?;
    final fee = transactionInfo.fee;
    if (txSize == null || txSize == 0 || fee == null) {
      return "";
    }
    final satPerVByte = fee.amount.toInt() / txSize;
    return "${satPerVByte.toStringAsFixed(2)} sat/vB";
  }

  // Deliberately not @computed: @computed would rerun _computeAddressBreakdown
  // on every read following any transaction mutation, including every
  // addOne() call cw_bitcoin's ElectrumTransactionResolver background loop
  // makes while resolving *other* transactions. Invalidated only when the
  // transaction *count* changes; an in-place update to an existing transaction
  // reuses the cache, since it adds no new address association.
  List<TransactionAddressBreakdownItem>? _addressBreakdownCache;
  int? _addressBreakdownCacheHistoryLength;

  List<TransactionAddressBreakdownItem> get addressBreakdown {
    final historyLength = wallet.transactionHistory.transactions.length;
    if (_addressBreakdownCache != null && _addressBreakdownCacheHistoryLength == historyLength) {
      return _addressBreakdownCache!;
    }
    final result = _computeAddressBreakdown();
    _addressBreakdownCache = result;
    _addressBreakdownCacheHistoryLength = historyLength;
    return result;
  }

  List<TransactionAddressBreakdownItem> _computeAddressBreakdown() {
    if (!electrumWalletTypes.contains(wallet.type)) {
      return [];
    }

    final ownedInputs =
        (transactionInfo.additionalInfo['ownedInputs'] as List?)?.cast<Map<dynamic, dynamic>>() ??
            const [];
    final ownedOutputs =
        (transactionInfo.additionalInfo['ownedOutputs'] as List?)?.cast<Map<dynamic, dynamic>>() ??
            const [];

    if (ownedInputs.isEmpty && ownedOutputs.isEmpty) {
      return [];
    }

    final currency = transactionAsset;
    Set<String>? unspentKeys;
    if (ownedOutputs.isNotEmpty) {
      final unspents = bitcoin!.getUnspents(wallet);
      unspentKeys = unspents.map((u) => "${u.hash}:${u.vout}").toSet();
    }

    // Per-address transaction count comes from the wallet's own address
    // records (already incrementally maintained during sync), not
    // re-derived here by rescanning the whole transaction history.
    final subAddressesByAddress = {
      for (final a in bitcoin!.getAllAddressRecords(wallet)) a.address: a,
    };

    final items = <TransactionAddressBreakdownItem>[];

    for (final input in ownedInputs) {
      final address = input['address'] as String;
      final subAddress = subAddressesByAddress[address];
      items.add(
        TransactionAddressBreakdownItem(
          address: address,
          amount: _appStore.amountParsingProxy
              .asDisplayStringWithSymbol(Money.fromInt(input['amount'] as int, currency)),
          rawAmount: input['amount'] as int,
          isChange: false,
          txCount: subAddress?.txCount,
          balanceDisplay: subAddress != null
              ? _appStore.amountParsingProxy.getDisplayCryptoString(subAddress.balance, currency)
              : null,
        ),
      );
    }

    for (final output in ownedOutputs) {
      final vout = output['vout'] as int;
      final address = output['address'] as String;
      final isUnspent = unspentKeys?.contains("${transactionInfo.txHash}:$vout") ?? false;
      final subAddress = subAddressesByAddress[address];
      items.add(
        TransactionAddressBreakdownItem(
          address: address,
          amount: _appStore.amountParsingProxy
              .asDisplayStringWithSymbol(Money.fromInt(output['amount'] as int, currency)),
          rawAmount: output['amount'] as int,
          isChange: true,
          isUnspent: isUnspent,
          txCount: subAddress?.txCount,
          balanceDisplay: subAddress != null
              ? _appStore.amountParsingProxy.getDisplayCryptoString(subAddress.balance, currency)
              : null,
        ),
      );
    }

    return items;
  }

  String formatAddressBreakdownTotal(List<TransactionAddressBreakdownItem> entries) {
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.rawAmount);
    return _appStore.amountParsingProxy
        .asDisplayStringWithSymbol(Money.fromInt(total, transactionAsset));
  }

  @computed
  String get transactionCopyAmount =>
      _appStore.amountParsingProxy.asDisplayString(transactionInfo.amount);

  // TODO(malik1004x): integrate these getters with the TransactionInfo object
  String get formattedPendingStatus {
    switch (wallet.type) {
      case WalletType.monero:
      case WalletType.haven:
      case WalletType.zano:
        if (transactionInfo.confirmations >= 0 && transactionInfo.confirmations < 10) {
          return " (${transactionInfo.confirmations}/10)";
        }
        break;
      case WalletType.wownero:
        if (transactionInfo.confirmations >= 0 && transactionInfo.confirmations < 3) {
          return " (${transactionInfo.confirmations}/3)";
        }
        break;
      case WalletType.litecoin:
        final isPegIn = (transactionInfo.additionalInfo["isPegIn"] as bool?) ?? false;
        final isPegOut = (transactionInfo.additionalInfo["isPegOut"] as bool?) ?? false;
        final fromPegOut = (transactionInfo.additionalInfo["fromPegOut"] as bool?) ?? false;
        String str = "";
        if (transactionInfo.confirmations <= 0) {
          str = S.current.pending;
        }
        if ((isPegOut || fromPegOut) &&
            transactionInfo.confirmations >= 0 &&
            transactionInfo.confirmations < 6) {
          str = " (${transactionInfo.confirmations}/6)";
        }
        if (isPegIn) {
          str += " (Peg In)";
        }
        if (isPegOut) {
          str += " (Peg Out)";
        }
        return str;
      default:
        return "";
    }

    return "";
  }

  String get formattedStatus {
    if ([
      WalletType.monero,
      WalletType.haven,
      WalletType.wownero,
      WalletType.litecoin,
      WalletType.zano,
    ].contains(wallet.type)) {
      return formattedPendingStatus;
    }

    return transactionInfo.isPending ? S.current.pending : "";
  }

  int get neededConfirmations {
    switch (wallet.type) {
      case WalletType.monero:
      case WalletType.haven:
      case WalletType.zano:
        return 10;
      case WalletType.wownero:
        return 3;
      case WalletType.litecoin:
        final isPegOut = (transactionInfo.additionalInfo["isPegOut"] as bool?) ?? false;
        final fromPegOut = (transactionInfo.additionalInfo["fromPegOut"] as bool?) ?? false;
        if (isPegOut || fromPegOut) {
          return 6;
        }
      default:
        return 0;
    }
    return 0;
  }

  String get formattedTitle {
    if (transactionInfo.additionalInfo['isIronwoodMigration'] == true) {
      return 'Migration';
    }
    if (transactionInfo.additionalInfo['isAutoShield'] == true) {
      return S.current.shielding;
    }
    if (transactionInfo.direction == TransactionDirection.incoming) {
      return S.current.received;
    }

    return S.current.sent;
  }

  @observable
  bool canReplaceByFee;

  String get _explorerUrl {
    final txId = transactionInfo.txHash;
    if (wallet.chainId != null) {
      final explorerUrl = evm!.getExplorerUrlForChainId(wallet.chainId!);
      if (explorerUrl != null) {
        return "$explorerUrl/tx/${txId}";
      }
    }

    switch (wallet.type) {
      case WalletType.monero:
        return "https://monero.com/tx/${txId}";
      case WalletType.bitcoin:
        return isLightning(transactionInfo)
            ? "https://sparkscan.io/tx/${txId}"
            : 'https://mempool.cakewallet.com/${wallet.isTestnet ? "testnet/" : ""}tx/${txId}';
      case WalletType.litecoin:
        return bitcoin!.txIsMweb(transactionInfo)
            ? "https://www.mwebexplorer.com/blocks/block/${transactionInfo.height}"
            : "https://blockchair.com/litecoin/transaction/${txId}";
      case WalletType.bitcoinCash:
        return "https://blockchair.com/bitcoin-cash/transaction/${txId}";
      case WalletType.haven:
        return "https://explorer.havenprotocol.org/search?value=${txId}";
      case WalletType.ethereum:
        return "https://etherscan.io/tx/${txId}";
      case WalletType.base:
        return "https://basescan.org/tx/${txId}";
      case WalletType.arbitrum:
        return "https://arbiscan.io/tx/${txId}";
      case WalletType.bsc:
        return "https://bscscan.com/tx/${txId}";
      case WalletType.polygon:
        return "https://polygonscan.com/tx/${txId}";
      case WalletType.nano:
        return "https://nanexplorer.com/nano/block/${txId}";
      case WalletType.banano:
        return "https://nanexplorer.com/banano/block/${txId}";
      case WalletType.solana:
        return "https://solscan.io/tx/${txId}";
      case WalletType.tron:
        return "https://tronscan.org/#/transaction/${txId}";
      case WalletType.wownero:
        return "https://explore.wownero.com/tx/${txId}";
      case WalletType.zano:
        return "https://explorer.zano.org/transaction/${txId}";
      case WalletType.decred:
        return 'https://${wallet.isTestnet ? "testnet" : "dcrdata"}.decred.org/tx/${txId.split(':')[0]}';
      case WalletType.dogecoin:
        return "https://blockchair.com/dogecoin/transaction/${txId}";
      case WalletType.zcash:
        return "https://blockchair.com/zcash/transaction/${txId}";
      case WalletType.none:
        return "";
    }
  }

  String get explorerDescription => S.current.view_transaction_on + Uri.parse(_explorerUrl).host;

  void launchExplorer() {
    launchUrl(Uri.parse(_explorerUrl));
  }

  void addBumpFeesListItems(TransactionInfo tx, String rawTransaction) {
    transactionPriority = bitcoin!.getBitcoinTransactionPriorityMedium();
    final inputsCount = (transactionInfo.inputAddresses?.isEmpty ?? true)
        ? 1
        : transactionInfo.inputAddresses!.length;
    final outputsCount = (transactionInfo.outputAddresses?.isEmpty ?? true)
        ? 1
        : transactionInfo.outputAddresses!.length;

    newFee = bitcoin!.getFeeAmountForPriority(
      wallet,
      bitcoin!.getBitcoinTransactionPriorityMedium(),
      inputsCount,
      outputsCount,
    );

    rbfListItems.add(
      StandartListItem(
        title: S.current.old_fee,
        value: tx.fee?.toStringWithSymbol() ?? "0.0",
        key: const ValueKey("standard_list_item_rbf_old_fee_key"),
      ),
    );

    if (transactionInfo.fee != null && rawTransaction.isNotEmpty) {
      final size = bitcoin!.getTransactionVSize(wallet, rawTransaction);
      final recommendedRate = (transactionInfo.fee! / BigInt.from(size)) +
          transactionInfo.fee!.copyWith(amount: BigInt.one);

      rbfListItems.add(
        StandartListItem(
          title: S.current.new_recommended_fee_rate,
          value: "$recommendedRate sat/byte",
        ),
      );
    }

    final priorities = priorityForWalletType(wallet.type);
    final selectedItem = priorities.indexOf(sendViewModel.feesViewModel.transactionPriority);
    final customItem = priorities.firstWhereOrNull(
      (element) => element == sendViewModel.feesViewModel.bitcoinTransactionPriorityCustom,
    );
    final customItemIndex = customItem != null ? priorities.indexOf(customItem) : null;
    final maxCustomFeeRate = sendViewModel.feesViewModel.maxCustomFeeRate?.toDouble();

    rbfListItems.add(
      StandardPickerListItem(
        key: const ValueKey("standard_picker_list_item_transaction_priorities_key"),
        title: S.current.estimated_new_fee,
        value: "${bitcoin!.formatterBitcoinAmountToString(amount: newFee)} ${wallet.currency}",
        items: priorityForWalletType(wallet.type),
        customValue: _appStore.settingsStore.customBitcoinFeeRate.toDouble(),
        maxValue: maxCustomFeeRate,
        selectedIdx: selectedItem,
        customItemIndex: customItemIndex ?? 0,
        displayItem: (dynamic priority, sliderValue) =>
            sendViewModel.feesViewModel.displayFeeRate(priority, sliderValue.round()),
        onSliderChanged: (newValue) => setNewFee(value: newValue, priority: transactionPriority!),
        onItemSelected: (dynamic item, sliderValue) {
          transactionPriority = item as TransactionPriority;
          return setNewFee(value: sliderValue, priority: transactionPriority!);
        },
      ),
    );

    if (transactionInfo.inputAddresses != null && transactionInfo.inputAddresses!.isNotEmpty) {
      rbfListItems.add(
        StandardExpandableListItem(
          key: const ValueKey("standard_expandable_list_item_transaction_input_addresses_key"),
          title: S.current.inputs,
          expandableItems: transactionInfo.inputAddresses!,
        ),
      );
    }

    if (transactionInfo.outputAddresses != null && transactionInfo.outputAddresses!.isNotEmpty) {
      final outputAddresses = transactionInfo.outputAddresses!.map((element) {
        if (element.contains("OP_RETURN:") && element.length > 40) {
          return "${element.substring(0, 40)}...";
        }
        return element;
      }).toList();

      rbfListItems.add(
        StandardExpandableListItem(
          title: S.current.outputs,
          expandableItems: outputAddresses,
          key: const ValueKey("standard_expandable_list_item_transaction_output_addresses_key"),
        ),
      );
    }
  }

  @action
  Future<void> _checkForRBF(TransactionInfo tx) async {
    if (wallet.type == WalletType.bitcoin &&
        transactionInfo.direction == TransactionDirection.outgoing) {
      final descriptionKey = "${transactionInfo.txHash}_${wallet.walletAddresses.primaryAddress}";
      final description = transactionDescriptionBox.values
          .firstWhereOrNull((val) => val.id == descriptionKey || val.id == transactionInfo.txHash);

      if (RegExp(AddressValidator.silentPaymentAddressPatternMainnet)
          .hasMatch(description?.recipientAddress ?? "")) {
        canReplaceByFee = false;
        return;
      }

      rawTransaction = await bitcoin!.canReplaceByFee(wallet, tx);
      if (rawTransaction != null) {
        canReplaceByFee = true;
      }
    }
  }

  String setNewFee({required TransactionPriority priority, double? value}) {
    newFee = priority == bitcoin!.getBitcoinTransactionPriorityCustom() && value != null
        ? bitcoin!.feeAmountWithFeeRate(
            wallet,
            value.round(),
            transactionInfo.inputAddresses?.length ?? 1,
            transactionInfo.outputAddresses?.length ?? 1,
          )
        : bitcoin!.getFeeAmountForPriority(
            wallet,
            priority,
            transactionInfo.inputAddresses?.length ?? 1,
            transactionInfo.outputAddresses?.length ?? 1,
          );

    return bitcoin!.formatterBitcoinAmountToString(amount: newFee);
  }

  void replaceByFee(String newFee) => sendViewModel.replaceByFee(transactionInfo, newFee);
}
