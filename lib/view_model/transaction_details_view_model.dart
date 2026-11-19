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
import "package:cw_core/utils/print_verbose.dart";
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
    required this.isOutput,
    this.isChangeAddress = false,
    this.isUnspent,
    this.txCount,
    this.balanceDisplay,
  });

  final String address;
  final String amount;
  final int rawAmount;

  /// Whether this entry is an owned output of the tx (otherwise an owned input).
  final bool isOutput;

  /// Whether the address is one of the wallet's internal (change) addresses.
  final bool isChangeAddress;

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
      valueGetter: (vm) =>
          vm.transactionInfo.fee != null ? vm.feeAmount : S.current.loading_three_dots,
      applicable: (vm) =>
          vm.wallet.type != WalletType.nano &&
          vm.transactionInfo.direction != TransactionDirection.incoming &&
          !vm.hasForeignInputs &&
          ((vm.transactionInfo.fee?.toStringWithSymbol() ?? "").isNotEmpty || vm.isFetchingFee),
    ),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_details_advanced_fee_key",
      title: S.current.tx_fee,
      valueGetter: (vm) =>
          vm.transactionInfo.fee != null ? vm.feeAmount : S.current.loading_three_dots,
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
    required TransactionInfo transactionInfo,
    required this.transactionDescriptionBox,
    required this.wallet,
    required AppStore appStore,
    required this.sendViewModel,
    this.canReplaceByFee = false,
  })  : _openedTransactionInfo = transactionInfo,
        rbfListItems = [],
        newFee = 0,
        isRecipientAddressShown = false,
        _appStore = appStore,
        showRecipientAddress = appStore.settingsStore.shouldSaveRecipientAddress {
    final tx = this.transactionInfo;

    _checkForRBF(tx);

    if (!electrumWalletTypes.contains(wallet.type)) {
      return;
    }

    // The background loop resolves every tx after each sync anyway; this only
    // serves the one the user has open first. Progress and the resolved tx
    // itself reach the view through observables (see [transactionInfo]).
    if (tx.fee == null || tx.isAmountPending) {
      bitcoin!.prioritizeTransactionResolution(wallet, tx);
    } else {
      // A resolved tx can still have been classified before the wallet knew
      // all its addresses; refresh it now rather than waiting for the
      // sync-wide pass.
      _refreshIfStale();
    }
  }

  Future<void> _refreshIfStale() async {
    try {
      await bitcoin!.refreshTransactionIfStale(wallet, transactionInfo);
    } catch (e, stacktrace) {
      printV("refreshing the transaction failed: $e");
      printV(stacktrace);
    }
  }

  /// Asks the resolver to try this tx again after it gave up (see
  /// [feeFetchFailed]).
  void retryAmountResolution() => bitcoin!.prioritizeTransactionResolution(wallet, transactionInfo);

  /// Rows from [TxDetailRowDefinition.defs] for the main view, or with
  /// [advanced] the Advanced Info view. Rebuilt whenever the tx resolves
  /// further, since the defs read [transactionInfo].
  List<TransactionDetailsListItem> _buildItems({required bool advanced}) {
    final newItems = <TransactionDetailsListItem>[];

    for (final def in TxDetailRowDefinition.defs) {
      if (def.advanced == advanced && def.applicable(this)) {
        newItems.add(def.listItemBuilder(
          title: def.title,
          value: def.valueGetter(this),
          key: ValueKey(def.keyString),
        ) as TransactionDetailsListItem);
      }
    }

    if (!advanced && showRecipientAddress && !isRecipientAddressShown) {
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

    return newItems;
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

  /// The wallet's current instance of this tx. The caller's object can be
  /// older (background resolution and the stale recheck replace history
  /// entries with new instances), and reading it through the observable
  /// history map is what rebuilds the view as the tx resolves.
  TransactionInfo get transactionInfo =>
      wallet.transactionHistory.transactions[_openedTransactionInfo.id] ?? _openedTransactionInfo;

  final TransactionInfo _openedTransactionInfo;

  final Box<TransactionDescription> transactionDescriptionBox;
  final WalletBase wallet;
  final SendViewModel sendViewModel;
  final AppStore _appStore;

  @computed
  List<TransactionDetailsListItem> get items => _buildItems(advanced: false);

  @computed
  List<TransactionDetailsListItem> get advancedItems => _buildItems(advanced: true);

  final List<TransactionDetailsListItem> rbfListItems;

  ({int resolvedInputs, int totalInputs, bool hasFailed})? get _resolutionProgress =>
      electrumWalletTypes.contains(wallet.type)
          ? bitcoin!.transactionResolutionProgress(wallet, transactionInfo)
          : null;

  @computed
  bool get isFetchingFee =>
      electrumWalletTypes.contains(wallet.type) &&
      transactionInfo.fee == null &&
      !(_resolutionProgress?.hasFailed ?? false);

  // Inputs resolved so far while isFetchingFee is true (e.g. "120/365"). Live
  // progress once the resolver reaches this tx; until then, what its last
  // pass recorded, so the count shows while it waits its turn.
  @computed
  int get feeFetchTotalInputs {
    final progress = _resolutionProgress;
    if (progress != null && progress.totalInputs > 0) {
      return progress.totalInputs;
    }

    return transactionInfo.additionalInfo["totalInputCount"] as int? ?? 0;
  }

  @computed
  int get feeFetchResolvedInputs {
    final progress = _resolutionProgress;
    if (progress != null && progress.totalInputs > 0) {
      return progress.resolvedInputs;
    }

    final unresolvedInputCount =
        (transactionInfo.additionalInfo["unresolvedInputTxids"] as List?)?.length ?? 0;
    return feeFetchTotalInputs - unresolvedInputCount;
  }

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

  /// Whether we are certain this wallet funded the tx: it is outgoing, the
  /// wallet owns at least one input, and every input's ownership has been
  /// resolved. Only then is the recorded fee known to be what this wallet paid.
  bool get isConfidentSend {
    final ownedInputs = transactionInfo.additionalInfo['ownedInputs'] as List?;
    // true if ownedInputs is not empty
    final hasOwnedInputs = ownedInputs?.isNotEmpty ?? false;

    final unresolvedInputTxids = transactionInfo.additionalInfo['unresolvedInputTxids'] as List?;
    // true if unresolvedInputTxids is null or is empty
    final isFullyResolved = unresolvedInputTxids?.isEmpty ?? true;

    return transactionInfo.direction == TransactionDirection.outgoing &&
        hasOwnedInputs &&
        isFullyResolved;
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

  bool get isAmountPending => transactionInfo.isAmountPending;

  /// The amount is still unknown and the resolver gave up on it.
  @computed
  bool get feeFetchFailed => isAmountPending && (_resolutionProgress?.hasFailed ?? false);

  String _formatCrypto(Money money) =>
      _appStore.amountParsingProxy.asDisplayStringWithSymbol(money);

  String _formatFiat(Money money) {
    final price = getIt.get<FiatConversionStore>().prices[transactionAsset];
    final fiatValue = calculateFiatAmountRaw(
      cryptoAmount: double.parse(money.toString()),
      price: price,
    ).withLocalSeperator(_appStore.settingsStore.languageCode);

    return "${_appStore.settingsStore.fiatCurrency.title} $fiatValue";
  }

  /// Amount plus fee, or null when the fee is unknown.
  Money? get _totalSent {
    final fee = transactionInfo.fee;

    if (fee == null) {
      return null;
    }

    return transactionInfo.amount + fee;
  }

  @computed
  String get totalSentAmount {
    final total = _totalSent;
    return total == null ? "" : _formatCrypto(total);
  }

  @computed
  String get totalSentFiatAmount {
    final total = _totalSent;
    return total == null ? "" : _formatFiat(total);
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
  TransactionInfo? _addressBreakdownCacheTransaction;

  List<TransactionAddressBreakdownItem> get addressBreakdown {
    final historyLength = wallet.transactionHistory.transactions.length;
    final tx = transactionInfo;

    // Also keyed on the tx instance: resolution replaces it with one that can
    // add owned inputs/outputs without changing the history length.
    if (_addressBreakdownCache != null &&
        _addressBreakdownCacheHistoryLength == historyLength &&
        identical(_addressBreakdownCacheTransaction, tx)) {
      return _addressBreakdownCache!;
    }

    final result = _computeAddressBreakdown();
    _addressBreakdownCache = result;
    _addressBreakdownCacheHistoryLength = historyLength;
    _addressBreakdownCacheTransaction = tx;
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
    // Only the addresses involved in this transaction are looked up.
    final txAddresses = {
      for (final i in ownedInputs) i['address'] as String,
      for (final o in ownedOutputs) o['address'] as String,
    };
    final addressRecordsByAddress = {
      for (final a in bitcoin!.getAddressRecords(wallet, txAddresses)) a.address: a,
    };

    final items = <TransactionAddressBreakdownItem>[];

    for (final input in ownedInputs) {
      final address = input['address'] as String;
      final addressRecord = addressRecordsByAddress[address];
      items.add(
        TransactionAddressBreakdownItem(
          address: address,
          amount: _appStore.amountParsingProxy
              .asDisplayStringWithSymbol(Money.fromInt(input['amount'] as int, currency)),
          rawAmount: input['amount'] as int,
          isOutput: false,
          txCount: addressRecord?.txCount,
          balanceDisplay: addressRecord != null
              ? _appStore.amountParsingProxy.getDisplayCryptoString(addressRecord.balance, currency)
              : null,
        ),
      );
    }

    for (final output in ownedOutputs) {
      final vout = output['vout'] as int;
      final address = output['address'] as String;
      final isUnspent = unspentKeys?.contains("${transactionInfo.txHash}:$vout") ?? false;
      final addressRecord = addressRecordsByAddress[address];
      items.add(
        TransactionAddressBreakdownItem(
          address: address,
          amount: _appStore.amountParsingProxy
              .asDisplayStringWithSymbol(Money.fromInt(output['amount'] as int, currency)),
          rawAmount: output['amount'] as int,
          isOutput: true,
          isChangeAddress: addressRecord?.isChange ?? false,
          isUnspent: isUnspent,
          txCount: addressRecord?.txCount,
          balanceDisplay: addressRecord != null
              ? _appStore.amountParsingProxy.getDisplayCryptoString(addressRecord.balance, currency)
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
      case WalletType.robinhood:
        return "https://robinhoodchain.blockscout.com/tx/${txId}";
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
    launchUrl(Uri.parse(_explorerUrl), mode: LaunchMode.externalApplication);
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
