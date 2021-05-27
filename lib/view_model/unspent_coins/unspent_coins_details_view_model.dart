import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/textfield_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_item.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_switch_item.dart';
import 'package:mobx/mobx.dart';

part 'unspent_coins_details_view_model.g.dart';

class UnspentCoinsDetailsViewModel = UnspentCoinsDetailsViewModelBase
    with _$UnspentCoinsDetailsViewModel;

abstract class UnspentCoinsDetailsViewModelBase with Store {
  UnspentCoinsDetailsViewModelBase({this.unspentCoinsItem}) {
    final amount = unspentCoinsItem.amount ?? '';
    final address = unspentCoinsItem.address ?? '';
    isFrozen = unspentCoinsItem.isFrozen ?? false;
    note = unspentCoinsItem.note ?? '';

    items = [
      StandartListItem(
        title: 'Amount',
        value: amount
      ),
      StandartListItem(
        title: 'Address',
        value: address
      ),
      TextFieldListItem(
          title: S.current.note_tap_to_change,
          value: note,
          onSubmitted: (value) {
            note = value;
          }),
      UnspentCoinsSwitchItem(
        title: 'Freeze',
        value: '',
        switchValue: () => isFrozen,
        onSwitchValueChange: (value) {
          isFrozen = value;
        }
      )
    ];
  }

  @observable
  bool isFrozen;

  @observable
  String note;

  final UnspentCoinsItem unspentCoinsItem;
  List<TransactionDetailsListItem> items;
}