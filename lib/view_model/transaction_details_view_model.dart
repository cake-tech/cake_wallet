import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/textfield_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/blockexplorer_list_item.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:hive/hive.dart';
import 'package:intl/src/intl/date_format.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cake_wallet/monero/monero.dart';

part 'transaction_details_view_model.g.dart';

class TransactionDetailsViewModel = TransactionDetailsViewModelBase
    with _$TransactionDetailsViewModel;

abstract class TransactionDetailsViewModelBase with Store {
  TransactionDetailsViewModelBase(
      {required this.transactionInfo,
      required this.transactionDescriptionBox,
      required this.wallet,
      required this.settingsStore})
      : items = [],
        isRecipientAddressShown = false,
        showRecipientAddress = settingsStore.shouldSaveRecipientAddress {
    final dateFormat = DateFormatter.withCurrentLocal();
    final tx = transactionInfo;

    switch (wallet.type) {
      case WalletType.monero:
        _addMoneroListItems(tx, dateFormat);
        break;
      case WalletType.bitcoin:
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
        _addElectrumListItems(tx, dateFormat);
        break;
      case WalletType.haven:
        _addHavenListItems(tx, dateFormat);
        break;
      case WalletType.ethereum:
        _addEthereumListItems(tx, dateFormat);
        break;
      case WalletType.nano:
        _addNanoListItems(tx, dateFormat);
        break;
      case WalletType.polygon:
        _addPolygonListItems(tx, dateFormat);
        break;
      case WalletType.solana:
        _addSolanaListItems(tx, dateFormat);
        break;
      default:
        break;
    }

    if (showRecipientAddress && !isRecipientAddressShown) {
      try {
        final recipientAddress = transactionDescriptionBox.values
            .firstWhere((val) => val.id == transactionInfo.id)
            .recipientAddress;

        if (recipientAddress?.isNotEmpty ?? false) {
          items.add(StandartListItem(
              title: S.current.transaction_details_recipient_address, value: recipientAddress!));
        }
      } catch (_) {
        // FIX-ME: Unhandled exception
      }
    }

    final type = wallet.type;

    items.add(BlockExplorerListItem(
        title: S.current.view_in_block_explorer,
        value: _explorerDescription(type),
        onTap: () {
          try {
            launch(_explorerUrl(type, tx.id));
          } catch (e) {}
        }));

    final description = transactionDescriptionBox.values.firstWhere(
        (val) => val.id == transactionInfo.id,
        orElse: () => TransactionDescription(id: transactionInfo.id));

    items.add(TextFieldListItem(
        title: S.current.note_tap_to_change,
        value: description.note,
        onSubmitted: (value) {
          description.transactionNote = value;

          if (description.isInBox) {
            description.save();
          } else {
            transactionDescriptionBox.add(description);
          }
        }));
  }

  final TransactionInfo transactionInfo;
  final Box<TransactionDescription> transactionDescriptionBox;
  final SettingsStore settingsStore;
  final WalletBase wallet;

  final List<TransactionDetailsListItem> items;
  bool showRecipientAddress;
  bool isRecipientAddressShown;

  String _explorerUrl(WalletType type, String txId) {
    switch (type) {
      case WalletType.monero:
        return 'https://monero.com/tx/${txId}';
      case WalletType.bitcoin:
        return 'https://mempool.space/${wallet.isTestnet == true ? "testnet/" : ""}tx/${txId}';
      case WalletType.litecoin:
        return 'https://blockchair.com/litecoin/transaction/${txId}';
      case WalletType.bitcoinCash:
        return 'https://blockchair.com/bitcoin-cash/transaction/${txId}';
      case WalletType.haven:
        return 'https://explorer.havenprotocol.org/search?value=${txId}';
      case WalletType.ethereum:
        return 'https://etherscan.io/tx/${txId}';
      case WalletType.nano:
        return 'https://nanolooker.com/block/${txId}';
      case WalletType.banano:
        return 'https://bananolooker.com/block/${txId}';
      case WalletType.polygon:
        return 'https://polygonscan.com/tx/${txId}';
      case WalletType.solana:
        return 'https://solscan.io/tx/${txId}';
      default:
        return '';
    }
  }

  String _explorerDescription(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return S.current.view_transaction_on + 'Monero.com';
      case WalletType.bitcoin:
        return S.current.view_transaction_on + 'mempool.space';
      case WalletType.litecoin:
      case WalletType.bitcoinCash:
        return S.current.view_transaction_on + 'Blockchair.com';
      case WalletType.haven:
        return S.current.view_transaction_on + 'explorer.havenprotocol.org';
      case WalletType.ethereum:
        return S.current.view_transaction_on + 'etherscan.io';
      case WalletType.nano:
        return S.current.view_transaction_on + 'nanolooker.com';
      case WalletType.banano:
        return S.current.view_transaction_on + 'bananolooker.com';
      case WalletType.polygon:
        return S.current.view_transaction_on + 'polygonscan.com';
      case WalletType.solana:
        return S.current.view_transaction_on + 'solscan.io';
      default:
        return '';
    }
  }

  void _addMoneroListItems(TransactionInfo tx, DateFormat dateFormat) {
    final key = tx.additionalInfo['key'] as String?;
    final accountIndex = tx.additionalInfo['accountIndex'] as int;
    final addressIndex = tx.additionalInfo['addressIndex'] as int;
    final feeFormatted = tx.feeFormatted();
    final _items = [
      StandartListItem(title: S.current.transaction_details_transaction_id, value: tx.id),
      StandartListItem(
          title: S.current.transaction_details_date, value: dateFormat.format(tx.date)),
      StandartListItem(title: S.current.transaction_details_height, value: '${tx.height}'),
      StandartListItem(title: S.current.transaction_details_amount, value: tx.amountFormatted()),
      if (feeFormatted != null)
        StandartListItem(title: S.current.transaction_details_fee, value: feeFormatted),
      if (key?.isNotEmpty ?? false) StandartListItem(title: S.current.transaction_key, value: key!),
    ];

    if (tx.direction == TransactionDirection.incoming) {
      try {
        final address = monero!.getTransactionAddress(wallet, accountIndex, addressIndex);
        final label = monero!.getSubaddressLabel(wallet, accountIndex, addressIndex);

        if (address.isNotEmpty) {
          isRecipientAddressShown = true;
          _items.add(StandartListItem(
            title: S.current.transaction_details_recipient_address,
            value: address,
          ));
        }

        if (label.isNotEmpty) {
          _items.add(StandartListItem(title: S.current.address_label, value: label));
        }
      } catch (e) {
        print(e.toString());
      }
    }

    items.addAll(_items);
  }

  void _addElectrumListItems(TransactionInfo tx, DateFormat dateFormat) {
    final _items = [
      StandartListItem(title: S.current.transaction_details_transaction_id, value: tx.id),
      StandartListItem(
          title: S.current.transaction_details_date, value: dateFormat.format(tx.date)),
      StandartListItem(title: S.current.confirmations, value: tx.confirmations.toString()),
      StandartListItem(title: S.current.transaction_details_height, value: '${tx.height}'),
      StandartListItem(title: S.current.transaction_details_amount, value: tx.amountFormatted()),
      if (tx.feeFormatted()?.isNotEmpty ?? false)
        StandartListItem(title: S.current.transaction_details_fee, value: tx.feeFormatted()!),
    ];

    items.addAll(_items);
  }

  void _addHavenListItems(TransactionInfo tx, DateFormat dateFormat) {
    items.addAll([
      StandartListItem(title: S.current.transaction_details_transaction_id, value: tx.id),
      StandartListItem(
          title: S.current.transaction_details_date, value: dateFormat.format(tx.date)),
      StandartListItem(title: S.current.transaction_details_height, value: '${tx.height}'),
      StandartListItem(title: S.current.transaction_details_amount, value: tx.amountFormatted()),
      if (tx.feeFormatted()?.isNotEmpty ?? false)
        StandartListItem(title: S.current.transaction_details_fee, value: tx.feeFormatted()!),
    ]);
  }

  void _addEthereumListItems(TransactionInfo tx, DateFormat dateFormat) {
    final _items = [
      StandartListItem(title: S.current.transaction_details_transaction_id, value: tx.id),
      StandartListItem(
          title: S.current.transaction_details_date, value: dateFormat.format(tx.date)),
      StandartListItem(title: S.current.confirmations, value: tx.confirmations.toString()),
      StandartListItem(title: S.current.transaction_details_height, value: '${tx.height}'),
      StandartListItem(title: S.current.transaction_details_amount, value: tx.amountFormatted()),
      if (tx.feeFormatted()?.isNotEmpty ?? false)
        StandartListItem(title: S.current.transaction_details_fee, value: tx.feeFormatted()!),
      if (showRecipientAddress && tx.to != null)
        StandartListItem(title: S.current.transaction_details_recipient_address, value: tx.to!),
      if (tx.direction == TransactionDirection.incoming && tx.from != null)
        StandartListItem(title: S.current.transaction_details_source_address, value: tx.from!),
    ];

    items.addAll(_items);
  }

  void _addNanoListItems(TransactionInfo tx, DateFormat dateFormat) {
    final _items = [
      StandartListItem(title: S.current.transaction_details_transaction_id, value: tx.id),
      if (showRecipientAddress && tx.to != null)
        StandartListItem(title: S.current.transaction_details_recipient_address, value: tx.to!),
      if (showRecipientAddress && tx.from != null)
        StandartListItem(title: S.current.transaction_details_source_address, value: tx.from!),
      StandartListItem(title: S.current.transaction_details_amount, value: tx.amountFormatted()),
      StandartListItem(
          title: S.current.transaction_details_date, value: dateFormat.format(tx.date)),
      StandartListItem(title: S.current.confirmed_tx, value: (tx.confirmations > 0).toString()),
      StandartListItem(title: S.current.transaction_details_height, value: '${tx.height}'),
    ];

    items.addAll(_items);
  }

  void _addPolygonListItems(TransactionInfo tx, DateFormat dateFormat) {
    final _items = [
      StandartListItem(title: S.current.transaction_details_transaction_id, value: tx.id),
      StandartListItem(
          title: S.current.transaction_details_date, value: dateFormat.format(tx.date)),
      StandartListItem(title: S.current.confirmations, value: tx.confirmations.toString()),
      StandartListItem(title: S.current.transaction_details_height, value: '${tx.height}'),
      StandartListItem(title: S.current.transaction_details_amount, value: tx.amountFormatted()),
      if (tx.feeFormatted()?.isNotEmpty ?? false)
        StandartListItem(title: S.current.transaction_details_fee, value: tx.feeFormatted()!),
      if (showRecipientAddress && tx.to != null && tx.direction == TransactionDirection.outgoing)
        StandartListItem(title: S.current.transaction_details_recipient_address, value: tx.to!),
      if (tx.direction == TransactionDirection.incoming && tx.from != null)
        StandartListItem(title: S.current.transaction_details_source_address, value: tx.from!),
    ];

    items.addAll(_items);
  }

  void _addSolanaListItems(TransactionInfo tx, DateFormat dateFormat) {
    final _items = [
      StandartListItem(title: S.current.transaction_details_transaction_id, value: tx.id),
      StandartListItem(
          title: S.current.transaction_details_date, value: dateFormat.format(tx.date)),
      StandartListItem(title: S.current.transaction_details_amount, value: tx.amountFormatted()),
      if (tx.feeFormatted()?.isNotEmpty ?? false)
        StandartListItem(title: S.current.transaction_details_fee, value: tx.feeFormatted()!),
      if (showRecipientAddress && tx.to != null)
        StandartListItem(title: S.current.transaction_details_recipient_address, value: tx.to!),
      if (tx.from != null)
        StandartListItem(title: S.current.transaction_details_source_address, value: tx.from!),
    ];

    items.addAll(_items);
  }
}
