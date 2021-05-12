import 'package:cake_wallet/bitcoin/bitcoin_transaction_info.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/transaction_info.dart';
import 'package:cake_wallet/monero/monero_transaction_info.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/textfield_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/blockexplorer_list_item.dart';
import 'package:cake_wallet/entities/transaction_direction.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:url_launcher/url_launcher.dart';

part 'transaction_details_view_model.g.dart';

class TransactionDetailsViewModel = TransactionDetailsViewModelBase
    with _$TransactionDetailsViewModel;

abstract class TransactionDetailsViewModelBase with Store {
  TransactionDetailsViewModelBase(
      {this.transactionInfo,
      this.transactionDescriptionBox,
      this.wallet,
      this.settingsStore})
      : items = [] {
    showRecipientAddress = settingsStore?.shouldSaveRecipientAddress ?? false;

    final dateFormat = DateFormatter.withCurrentLocal();
    final tx = transactionInfo;

    if (tx is MoneroTransactionInfo) {
      final _items = [
        StandartListItem(
            title: S.current.transaction_details_transaction_id, value: tx.id),
        StandartListItem(
            title: S.current.transaction_details_date,
            value: dateFormat.format(tx.date)),
        StandartListItem(
            title: S.current.transaction_details_height, value: '${tx.height}'),
        StandartListItem(
            title: S.current.transaction_details_amount,
            value: tx.amountFormatted()),
        StandartListItem(
            title: S.current.transaction_details_fee, value: tx.feeFormatted()),
        BlockExplorerListItem(
            title: "View in Block Explorer",
            value: "View Transaction on XMRChain.net",
            onTap: () {
              launch("https://xmrchain.net/search?value=${tx.id}");
            })
      ];

      if (tx.key?.isNotEmpty ?? null) {
        _items.add(
            StandartListItem(title: S.current.transaction_key, value: tx.key));
      }

      if ((tx.direction == TransactionDirection.incoming)&&
          (wallet is MoneroWallet)) {
        try {
          final accountIndex = tx.accountIndex;
          final addressIndex = tx.addressIndex;
          final _wallet = wallet as MoneroWallet;
          final address =
            _wallet.getTransactionAddress(accountIndex, addressIndex);
          if (address?.isNotEmpty ?? false) {
            _items.add(
                StandartListItem(
                    title: S.current.transaction_details_recipient_address,
                    value: address));
          }
        } catch (e) {
          print(e.toString());
        }
      }

      items.addAll(_items);
    }

    if (tx is BitcoinTransactionInfo) {
      final _items = [
        StandartListItem(
            title: S.current.transaction_details_transaction_id, value: tx.id),
        StandartListItem(
            title: S.current.transaction_details_date,
            value: dateFormat.format(tx.date)),
        StandartListItem(
            title: S.current.confirmations,
            value: tx.confirmations?.toString()),
        StandartListItem(
            title: S.current.transaction_details_height, value: '${tx.height}'),
        StandartListItem(
            title: S.current.transaction_details_amount,
            value: tx.amountFormatted()),
        if (tx.feeFormatted()?.isNotEmpty)
          StandartListItem(
              title: S.current.transaction_details_fee,
              value: tx.feeFormatted()),
        BlockExplorerListItem(
            title: "View in Block Explorer",
            value: "View Transaction on Blockchain.com",
            onTap: () {
              launch("https://www.blockchain.com/btc/tx/${tx.id}");
            })
      ];

      items.addAll(_items);
    }

    if (showRecipientAddress) {
      final recipientAddress = transactionDescriptionBox.values
          .firstWhere((val) => val.id == transactionInfo.id, orElse: () => null)
          ?.recipientAddress;

      if (recipientAddress?.isNotEmpty ?? false) {
        items.add(StandartListItem(
            title: S.current.transaction_details_recipient_address,
            value: recipientAddress));
      }
    }

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
}
