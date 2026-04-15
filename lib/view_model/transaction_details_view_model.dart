import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/starknet/starknet.dart';
import 'package:cake_wallet/src/screens/transaction_details/address_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/confirmations_list_item.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_starknet/starknet_transaction_info.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/src/screens/transaction_details/rbf_details_list_fee_picker_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_expandable_list_item.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:cake_wallet/view_model/send/send_view_model.dart';
import 'package:collection/collection.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:url_launcher/url_launcher.dart';

part 'transaction_details_view_model.g.dart';

bool _trueFunc(_) => true;

bool isLightning(TransactionInfo tx) {
  printV(tx.additionalInfo);
  return (tx.additionalInfo["isLightning"] as bool?) ?? false;
}

class TxDetailRowDefinition {
  final String keyString;
  final String title;
  final String Function(TransactionDetailsViewModelBase) valueGetter;
  final bool Function(TransactionDetailsViewModelBase) applicable;
  final dynamic Function({
    required String title,
    required String value,
    required Key key,
  }) listItemBuilder;

  TxDetailRowDefinition(
      {required this.keyString,
      required this.title,
      required this.valueGetter,
      this.applicable = _trueFunc,
      this.listItemBuilder = StandartListItem.new});

  static final List<TxDetailRowDefinition> defs = [
    TxDetailRowDefinition(
        keyString: "standard_list_item_transaction_details_date_key",
        title: S.current.transaction_details_date,
        valueGetter: (vm) =>
            DateFormatter.withCurrentLocal().format(vm.transactionInfo.date)),
    TxDetailRowDefinition(
        keyString: "standard_list_item_transaction_details_height_key",
        title: S.current.transaction_details_height,
        valueGetter: (vm) => vm.transactionInfo.height.toString(),
        applicable: (vm) =>
            !([WalletType.solana, WalletType.tron].contains(vm.wallet.type) &&
                !isLightning(vm.transactionInfo))),
    TxDetailRowDefinition(
        keyString: "standard_list_item_transaction_details_fee_key",
        title: S.current.transaction_details_fee,
        valueGetter: (vm) => vm.transactionInfo.feeFormatted()!,
        applicable: (vm) =>
            vm.wallet.type != WalletType.nano &&
            (vm.transactionInfo.feeFormatted() ?? "").isNotEmpty),
    TxDetailRowDefinition(
        keyString: "standard_list_item_transaction_details_starknet_action_key",
        title: "Action",
        valueGetter: (vm) => vm._starknetActionLabel()!,
        applicable: (vm) => vm._starknetActionLabel() != null),
    TxDetailRowDefinition(
        keyString: "standard_list_item_transaction_details_starknet_type_key",
        title: "Transaction type",
        valueGetter: (vm) => vm._starknetInfo?.transactionTypeLabel() ?? '',
        applicable: (vm) => vm._starknetInfo?.transactionTypeLabel() != null),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_execution_status_key",
        title: "Execution status",
        valueGetter: (vm) => vm._starknetInfo?.executionStatusLabel() ?? '',
        applicable: (vm) => vm._starknetInfo?.executionStatusLabel() != null),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_finality_status_key",
        title: "Finality",
        valueGetter: (vm) => vm._starknetInfo?.finalityStatusLabel() ?? '',
        applicable: (vm) => vm._starknetInfo?.finalityStatusLabel() != null),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_fee_priority_key",
        title: "Fee priority",
        valueGetter: (vm) => vm._starknetInfo?.feePriorityLabel() ?? '',
        applicable: (vm) => vm._starknetInfo?.feePriorityLabel() != null),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_execution_fee_key",
        title: "Execution fee",
        valueGetter: (vm) => vm._starknetInfo?.executionFeeFormatted() ?? '',
        applicable: (vm) => vm._starknetInfo?.executionFeeFormatted() != null),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_deploy_fee_key",
        title: "Deploy fee",
        valueGetter: (vm) =>
            vm._starknetInfo?.deployAccountFeeFormatted() ?? '',
        applicable: (vm) =>
            vm._starknetInfo?.deployAccountFeeFormatted() != null),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_deployment_required_key",
        title: "Account deployment",
        valueGetter: (_) => 'Required',
        applicable: (vm) =>
            vm._starknetInfo?.accountDeploymentRequired == true),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_call_count_key",
        title: "Call count",
        valueGetter: (vm) => vm._starknetInfo?.callCountLabel() ?? '',
        applicable: (vm) => vm._starknetInfo?.callCountLabel() != null),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_primary_contract_key",
        title: "Primary contract",
        valueGetter: (vm) => vm._starknetInfo?.primaryContractAddress() ?? '',
        applicable: (vm) => vm._starknetInfo?.primaryContractAddress() != null,
        listItemBuilder: AddressListItem.new),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_primary_entrypoint_key",
        title: "Primary entrypoint",
        valueGetter: (vm) => vm._starknetInfo?.primaryEntrypoint() ?? '',
        applicable: (vm) => vm._starknetInfo?.primaryEntrypoint() != null),
    TxDetailRowDefinition(
        keyString: "standard_list_item_transaction_details_starknet_tip_key",
        title: "Tip",
        valueGetter: (vm) => vm._starknetInfo?.transactionTipLabel() ?? '',
        applicable: (vm) => vm._starknetInfo?.transactionTipLabel() != null),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_l1_gas_amount_key",
        title: "L1 gas max amount",
        valueGetter: (vm) => vm._starknetInfo?.l1GasMaxAmount() ?? '',
        applicable: (vm) => vm._starknetInfo?.l1GasMaxAmount() != null),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_l1_gas_price_key",
        title: "L1 gas max price",
        valueGetter: (vm) => vm._starknetInfo?.l1GasMaxPriceWei() ?? '',
        applicable: (vm) => vm._starknetInfo?.l1GasMaxPriceWei() != null),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_l2_gas_amount_key",
        title: "L2 gas max amount",
        valueGetter: (vm) => vm._starknetInfo?.l2GasMaxAmount() ?? '',
        applicable: (vm) => vm._starknetInfo?.l2GasMaxAmount() != null),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_l2_gas_price_key",
        title: "L2 gas max price",
        valueGetter: (vm) => vm._starknetInfo?.l2GasMaxPriceWei() ?? '',
        applicable: (vm) => vm._starknetInfo?.l2GasMaxPriceWei() != null),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_l1_data_gas_amount_key",
        title: "L1 data gas max amount",
        valueGetter: (vm) => vm._starknetInfo?.l1DataGasMaxAmount() ?? '',
        applicable: (vm) => vm._starknetInfo?.l1DataGasMaxAmount() != null),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_l1_data_gas_price_key",
        title: "L1 data gas max price",
        valueGetter: (vm) => vm._starknetInfo?.l1DataGasMaxPriceWei() ?? '',
        applicable: (vm) => vm._starknetInfo?.l1DataGasMaxPriceWei() != null),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_starknet_revert_reason_key",
        title: "Revert reason",
        valueGetter: (vm) => vm._starknetInfo?.revertReason() ?? '',
        applicable: (vm) => vm._starknetInfo?.revertReason() != null),
    TxDetailRowDefinition(
        keyString: "standard_list_item_transaction_confirmations_key",
        title: S.current.confirmations,
        valueGetter: (vm) =>
            "${vm.transactionInfo.confirmations}/${vm.neededConfirmations}",
        applicable: (vm) =>
            [
              ...electrumWalletTypes,
              ...evmWalletTypes,
              WalletType.zcash,
              WalletType.monero
            ].contains(vm.wallet.type) &&
            !isLightning(vm.transactionInfo),
        listItemBuilder: ConfirmationsListItem.new),
    TxDetailRowDefinition(
        keyString:
            "standard_list_item_transaction_details_recipient_address_key",
        title: S.current.transaction_details_recipient_address,
        valueGetter: (vm) {
          vm.isRecipientAddressShown = true;
          switch (vm.wallet.type) {
            case WalletType.monero:
              return monero!.getTransactionAddress(
                  vm.wallet,
                  vm.transactionInfo.additionalInfo['accountIndex'] as int,
                  vm.transactionInfo.additionalInfo['addressIndex'] as int);
            case WalletType.bitcoin:
              return (bitcoin!.getTransactionAddresses(
                              vm.wallet, vm.transactionInfo) ??
                          [])
                      .firstOrNull ??
                  "";
            case WalletType.tron:
              return tron!
                  .getTronBase58Address(vm.transactionInfo.to!, vm.wallet);
            default:
              return vm.transactionInfo.to!;
          }
        },
        applicable: (vm) =>
            vm.showRecipientAddress &&
            (vm.transactionInfo.to != null ||
                [WalletType.monero, WalletType.tron].contains(vm.wallet.type) ||
                vm.wallet.type == WalletType.bitcoin &&
                    vm.transactionInfo.direction ==
                        TransactionDirection.incoming),
        listItemBuilder: AddressListItem.new),
    TxDetailRowDefinition(
        keyString: "standard_list_item_transaction_details_source_address_key",
        title: S.current.transaction_details_source_address,
        valueGetter: (vm) {
          switch (vm.wallet.type) {
            case WalletType.tron:
              return tron!
                  .getTronBase58Address(vm.transactionInfo.from!, vm.wallet);
            default:
              return vm.transactionInfo.from!;
          }
        },
        applicable: (vm) => vm.transactionInfo.from != null,
        listItemBuilder: AddressListItem.new),
    TxDetailRowDefinition(
        keyString: "standard_list_item_address_label_key",
        title: S.current.address_label,
        valueGetter: (vm) => monero!.getSubaddressLabel(
            vm.wallet,
            vm.transactionInfo.additionalInfo['accountIndex'] as int,
            vm.transactionInfo.additionalInfo['addressIndex'] as int),
        applicable: (vm) => vm.wallet.type == WalletType.monero),
    TxDetailRowDefinition(
        keyString: "standard_list_item_transaction_key",
        title: S.current.transaction_key,
        valueGetter: (vm) {
          final descriptionKey =
              '${vm.transactionInfo.txHash}_${vm.wallet.walletAddresses.primaryAddress}';

          final description = vm.transactionDescriptionBox.values.firstWhere(
              (val) =>
                  val.id == descriptionKey ||
                  val.id == vm.transactionInfo.txHash,
              orElse: () => TransactionDescription(id: descriptionKey));
          return vm.transactionInfo.additionalInfo['key'] as String? ??
              description.transactionKey ??
              "";
        },
        applicable: (vm) => vm.wallet.type == WalletType.monero),
    TxDetailRowDefinition(
        keyString: "standard_list_item_transaction_confirmed_key",
        title: S.current.confirmed_tx,
        valueGetter: (vm) => (vm.transactionInfo.confirmations > 0).toString(),
        applicable: (vm) => vm.wallet.type == WalletType.nano),
    TxDetailRowDefinition(
        keyString: "standard_list_item_transaction_details_memo_key",
        title: S.current.memo,
        valueGetter: (vm) =>
            vm.transactionInfo.additionalInfo['memo'] as String,
        applicable: (vm) =>
            vm.wallet.type == WalletType.zcash &&
            vm.transactionInfo.additionalInfo["memo"] != null),
    TxDetailRowDefinition(
        keyString: "standard_list_item_transaction_details_asset_id_key",
        title: "Asset ID",
        valueGetter: (vm) =>
            vm.transactionInfo.additionalInfo["assetId"] as String? ??
            "Unknown asset id",
        applicable: (vm) => vm.wallet.type == WalletType.zano),
    TxDetailRowDefinition(
        keyString: "standard_list_item_transaction_details_comment_key",
        title: S.current.transaction_details_title,
        valueGetter: (vm) =>
            vm.transactionInfo.additionalInfo['comment'] as String? ?? "",
        applicable: (vm) => vm.wallet.type == WalletType.zano),
    TxDetailRowDefinition(
      keyString: "standard_list_item_transaction_details_id_key",
      title: S.current.transaction_details_transaction_id,
      valueGetter: (vm) => vm.transactionInfo.txHash,
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
        RBFListItems = [],
        newFee = 0,
        isRecipientAddressShown = false,
        _appStore = appStore,
        showRecipientAddress =
            appStore.settingsStore.shouldSaveRecipientAddress {
    final tx = transactionInfo;

    for (final def in TxDetailRowDefinition.defs) {
      if (def.applicable(this)) {
        items.add(def.listItemBuilder(
            title: def.title,
            value: def.valueGetter(this),
            key: ValueKey(def.keyString)) as TransactionDetailsListItem);
      }
    }

    _checkForRBF(tx);

    final descriptionKey =
        '${transactionInfo.txHash}_${wallet.walletAddresses.primaryAddress}';
    final description = transactionDescriptionBox.values.firstWhere(
        (val) => val.id == descriptionKey || val.id == transactionInfo.txHash,
        orElse: () => TransactionDescription(id: descriptionKey));

    if (showRecipientAddress && !isRecipientAddressShown) {
      final recipientAddress = description.recipientAddress;

      if (recipientAddress?.isNotEmpty ?? false) {
        items.add(
          AddressListItem(
            title: S.current.transaction_details_recipient_address,
            value: recipientAddress!,
            key: ValueKey('standard_list_item_${recipientAddress}_key'),
          ),
        );
      }
    }
  }

  void updateNote(String note) {
    final descriptionKey =
        '${transactionInfo.txHash}_${wallet.walletAddresses.primaryAddress}';
    final description = transactionDescriptionBox.values.firstWhere(
        (val) => val.id == descriptionKey || val.id == transactionInfo.txHash,
        orElse: () => TransactionDescription(id: descriptionKey));

    description.transactionNote = note;

    if (description.isInBox) {
      description.save();
    } else {
      transactionDescriptionBox.add(description);
    }
  }

  String get note {
    final descriptionKey =
        '${transactionInfo.txHash}_${wallet.walletAddresses.primaryAddress}';
    final description = transactionDescriptionBox.values.firstWhereOrNull(
        (val) => val.id == descriptionKey || val.id == transactionInfo.txHash);
    return description?.transactionNote ?? "";
  }

  final TransactionInfo transactionInfo;
  final Box<TransactionDescription> transactionDescriptionBox;
  final WalletBase wallet;
  final SendViewModel sendViewModel;
  final AppStore _appStore;

  final List<TransactionDetailsListItem> items;
  final List<TransactionDetailsListItem> RBFListItems;
  bool showRecipientAddress;
  bool isRecipientAddressShown;
  int newFee;
  String? rawTransaction;
  TransactionPriority? transactionPriority;

  CryptoCurrency get transactionAsset {
    if (isEVMCompatibleChain(wallet.type)) {
      return evm!.assetOfTransaction(wallet, transactionInfo);
    }

    return switch (wallet.type) {
      WalletType.solana => solana!.assetOfTransaction(wallet, transactionInfo),
      WalletType.starknet =>
        starknet!.assetOfTransaction(wallet, transactionInfo),
      WalletType.tron => tron!.assetOfTransaction(wallet, transactionInfo),
      WalletType.zano => zano!.assetOfTransaction(wallet, transactionInfo) ??
          CryptoCurrency.zano,
      _ => walletTypeToCryptoCurrency(wallet.type)
    };
  }

  // TODO integrate these getters with the TransactionInfo object
  String get formattedPendingStatus {
    switch (wallet.type) {
      case WalletType.monero:
      case WalletType.haven:
      case WalletType.zano:
        if (transactionInfo.confirmations >= 0 &&
            transactionInfo.confirmations < 10) {
          return ' (${transactionInfo.confirmations}/10)';
        }
        break;
      case WalletType.wownero:
        if (transactionInfo.confirmations >= 0 &&
            transactionInfo.confirmations < 3) {
          return ' (${transactionInfo.confirmations}/3)';
        }
        break;
      case WalletType.litecoin:
        bool isPegIn =
            (transactionInfo.additionalInfo["isPegIn"] as bool?) ?? false;
        bool isPegOut =
            (transactionInfo.additionalInfo["isPegOut"] as bool?) ?? false;
        bool fromPegOut =
            (transactionInfo.additionalInfo["fromPegOut"] as bool?) ?? false;
        String str = '';
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
        return '';
    }

    return '';
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

    return transactionInfo.isPending ? S.current.pending : '';
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
        bool isPegOut =
            (transactionInfo.additionalInfo["isPegOut"] as bool?) ?? false;
        bool fromPegOut =
            (transactionInfo.additionalInfo["fromPegOut"] as bool?) ?? false;
        if (isPegOut || fromPegOut) return 6;
      default:
        return 0;
    }
    return 0;
  }

  String get formattedTitle {
    if (transactionInfo.additionalInfo['autoShield'] == true) {
      return "Autoshield";
    }
    final starknetActionLabel = _starknetActionLabel();
    if (wallet.type == WalletType.starknet &&
        starknetActionLabel != null &&
        starknetActionLabel.toLowerCase() != 'transfer' &&
        transactionInfo.direction == TransactionDirection.outgoing) {
      return starknetActionLabel;
    }
    if (transactionInfo.direction == TransactionDirection.incoming) {
      return S.current.received;
    }

    return S.current.sent;
  }

  String? _starknetActionLabel() {
    final explicitLabel = transactionInfo.additionalInfo['starknetActionLabel']
        ?.toString()
        .trim();
    if (explicitLabel != null && explicitLabel.isNotEmpty) {
      return explicitLabel;
    }

    final actionName = transactionInfo.evmSignatureName?.trim();
    if (actionName == null || actionName.isEmpty) {
      return null;
    }

    final normalized = actionName.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) {
      return null;
    }

    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  StarknetTransactionInfo? get _starknetInfo =>
      wallet.type == WalletType.starknet &&
              transactionInfo is StarknetTransactionInfo
          ? transactionInfo as StarknetTransactionInfo
          : null;

  @observable
  bool canReplaceByFee;

  String get _explorerUrl {
    final txId = transactionInfo.txHash;
    if (wallet.chainId != null) {
      final explorerUrl = evm!.getExplorerUrlForChainId(wallet.chainId!);
      if (explorerUrl != null) return '$explorerUrl/tx/${txId}';
    }

    switch (wallet.type) {
      case WalletType.monero:
        return 'https://monero.com/tx/${txId}';
      case WalletType.bitcoin:
        return 'https://mempool.cakewallet.com/${wallet.isTestnet ? "testnet/" : ""}tx/${txId}';
      case WalletType.litecoin:
        return bitcoin!.txIsMweb(transactionInfo)
            ? "https://www.mwebexplorer.com/blocks/block/${transactionInfo.height}"
            : 'https://blockchair.com/litecoin/transaction/${txId}';
      case WalletType.bitcoinCash:
        return 'https://blockchair.com/bitcoin-cash/transaction/${txId}';
      case WalletType.haven:
        return 'https://explorer.havenprotocol.org/search?value=${txId}';
      case WalletType.ethereum:
        return 'https://etherscan.io/tx/${txId}';
      case WalletType.base:
        return 'https://basescan.org/tx/${txId}';
      case WalletType.arbitrum:
        return 'https://arbiscan.io/tx/${txId}';
      case WalletType.bsc:
        return 'https://bscscan.com/tx/${txId}';
      case WalletType.polygon:
        return 'https://polygonscan.com/tx/${txId}';
      case WalletType.nano:
        return 'https://nanexplorer.com/nano/block/${txId}';
      case WalletType.banano:
        return 'https://nanexplorer.com/banano/block/${txId}';
      case WalletType.solana:
        return 'https://solscan.io/tx/${txId}';
      case WalletType.starknet:
        return 'https://starkscan.co/tx/${txId}';
      case WalletType.tron:
        return 'https://tronscan.org/#/transaction/${txId}';
      case WalletType.wownero:
        return 'https://explore.wownero.com/tx/${txId}';
      case WalletType.zano:
        return 'https://explorer.zano.org/transaction/${txId}';
      case WalletType.decred:
        return 'https://${wallet.isTestnet ? "testnet" : "dcrdata"}.decred.org/tx/${txId.split(':')[0]}';
      case WalletType.dogecoin:
        return 'https://blockchair.com/dogecoin/transaction/${txId}';
      case WalletType.zcash:
        return 'https://blockchair.com/zcash/transaction/${txId}';
      case WalletType.none:
        return '';
    }
  }

  String get explorerDescription =>
      S.current.view_transaction_on + Uri.parse(_explorerUrl).host;

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
        outputsCount);

    RBFListItems.add(
      StandartListItem(
        title: S.current.old_fee,
        value: tx.feeFormatted() ?? '0.0',
        key: ValueKey('standard_list_item_rbf_old_fee_key'),
      ),
    );

    if (transactionInfo.fee != null && rawTransaction.isNotEmpty) {
      final size = bitcoin!.getTransactionVSize(wallet, rawTransaction);
      final recommendedRate = (transactionInfo.fee! / size).round() + 1;

      RBFListItems.add(StandartListItem(
          title: 'New recommended fee rate',
          value: '$recommendedRate sat/byte'));
    }

    final priorities = priorityForWalletType(wallet.type);
    final selectedItem =
        priorities.indexOf(sendViewModel.feesViewModel.transactionPriority);
    final customItem = priorities.firstWhereOrNull((element) =>
        element ==
        sendViewModel.feesViewModel.bitcoinTransactionPriorityCustom);
    final customItemIndex =
        customItem != null ? priorities.indexOf(customItem) : null;
    final maxCustomFeeRate =
        sendViewModel.feesViewModel.maxCustomFeeRate?.toDouble();

    RBFListItems.add(
      StandardPickerListItem(
        key: ValueKey('standard_picker_list_item_transaction_priorities_key'),
        title: S.current.estimated_new_fee,
        value: bitcoin!.formatterBitcoinAmountToString(amount: newFee) +
            ' ${wallet.currency}',
        items: priorityForWalletType(wallet.type),
        customValue: _appStore.settingsStore.customBitcoinFeeRate.toDouble(),
        maxValue: maxCustomFeeRate,
        selectedIdx: selectedItem,
        customItemIndex: customItemIndex ?? 0,
        displayItem: (dynamic priority, double sliderValue) => sendViewModel
            .feesViewModel
            .displayFeeRate(priority, sliderValue.round()),
        onSliderChanged: (double newValue) =>
            setNewFee(value: newValue, priority: transactionPriority!),
        onItemSelected: (dynamic item, double sliderValue) {
          transactionPriority = item as TransactionPriority;
          return setNewFee(value: sliderValue, priority: transactionPriority!);
        },
      ),
    );

    if (transactionInfo.inputAddresses != null &&
        transactionInfo.inputAddresses!.isNotEmpty) {
      RBFListItems.add(
        StandardExpandableListItem(
          key: ValueKey(
              'standard_expandable_list_item_transaction_input_addresses_key'),
          title: S.current.inputs,
          expandableItems: transactionInfo.inputAddresses!,
        ),
      );
    }

    if (transactionInfo.outputAddresses != null &&
        transactionInfo.outputAddresses!.isNotEmpty) {
      final outputAddresses = transactionInfo.outputAddresses!.map((element) {
        if (element.contains('OP_RETURN:') && element.length > 40) {
          return element.substring(0, 40) + '...';
        }
        return element;
      }).toList();

      RBFListItems.add(
        StandardExpandableListItem(
          title: S.current.outputs,
          expandableItems: outputAddresses,
          key: ValueKey(
              'standard_expandable_list_item_transaction_output_addresses_key'),
        ),
      );
    }
  }

  @action
  Future<void> _checkForRBF(TransactionInfo tx) async {
    if (wallet.type == WalletType.bitcoin &&
        transactionInfo.direction == TransactionDirection.outgoing) {
      final descriptionKey =
          '${transactionInfo.txHash}_${wallet.walletAddresses.primaryAddress}';
      final description = transactionDescriptionBox.values.firstWhereOrNull(
          (val) =>
              val.id == descriptionKey || val.id == transactionInfo.txHash);

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

  String setNewFee({double? value, required TransactionPriority priority}) {
    newFee = priority == bitcoin!.getBitcoinTransactionPriorityCustom() &&
            value != null
        ? bitcoin!.feeAmountWithFeeRate(
            wallet,
            value.round(),
            transactionInfo.inputAddresses?.length ?? 1,
            transactionInfo.outputAddresses?.length ?? 1)
        : bitcoin!.getFeeAmountForPriority(
            wallet,
            priority,
            transactionInfo.inputAddresses?.length ?? 1,
            transactionInfo.outputAddresses?.length ?? 1);

    return bitcoin!.formatterBitcoinAmountToString(amount: newFee);
  }

  void replaceByFee(String newFee) =>
      sendViewModel.replaceByFee(transactionInfo, newFee);

  @computed
  String get pendingTransactionFiatAmountValueFormatted =>
      sendViewModel.isFiatDisabled
          ? ''
          : sendViewModel.pendingTransactionFiatAmount +
              ' ' +
              sendViewModel.fiat.title;

  @computed
  String get pendingTransactionFeeFiatAmountFormatted =>
      sendViewModel.isFiatDisabled
          ? ''
          : sendViewModel.pendingTransactionFeeFiatAmount +
              ' ' +
              sendViewModel.fiat.title;
}
