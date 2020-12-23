import 'package:cake_wallet/bitcoin/bitcoin_transaction_info.dart';
import 'package:cake_wallet/entities/transaction_info.dart';
import 'package:cake_wallet/monero/monero_transaction_info.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/textfield_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/utils/date_formatter.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'transaction_details_view_model.g.dart';

class TransactionDetailsViewModel = TransactionDetailsViewModelBase with _$TransactionDetailsViewModel;

abstract class TransactionDetailsViewModelBase with Store {
  TransactionDetailsViewModelBase({
    this.transactionInfo,
    this.transactionDescriptionBox,
    this.settingsStore}) : items = [] {

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
        StandartListItem(title: S.current.send_fee, value: tx.feeFormatted()),
      ];

      if (tx.key?.isNotEmpty ?? null) {
        _items.add(StandartListItem(
            title: S.current.transaction_key,
            value: tx.key));
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
            title: S.current.confirmations, value: tx.confirmations?.toString()),
        StandartListItem(
            title: S.current.transaction_details_height, value: '${tx.height}'),
        StandartListItem(
            title: S.current.transaction_details_amount,
            value: tx.amountFormatted()),
        if (tx.feeFormatted()?.isNotEmpty)
          StandartListItem(title: S.current.send_fee, value: tx.feeFormatted())
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
            (val) => val.id == transactionInfo.id, orElse: () => null);

    if (description != null) {
      items.add(TextFieldListItem(
          title: S.current.note_tap_to_change,
          value: description.note,
          onSubmitted: (value) {
            description.transactionNote = value;
            description.save();
          }));
    }
  }

  final TransactionInfo transactionInfo;
  final Box<TransactionDescription> transactionDescriptionBox;
  final SettingsStore settingsStore;

  final List<TransactionDetailsListItem> items;
  bool showRecipientAddress;
}