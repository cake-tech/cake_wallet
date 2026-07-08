import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';

/// A transaction-detail row holding a free-form message (e.g. the payer's LNURL
/// comment on a received lightning payment). Extends [StandartListItem] so it
/// still renders as a plain row on renderers that don't special-case it.
class MessageListItem extends StandartListItem {
  MessageListItem({
    required String super.title,
    required String super.value,
    super.key,
  });
}
