import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/textfield_list_item.dart';
import 'package:cake_wallet/src/screens/transaction_details/transaction_details_list_item.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_item.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_list_view_model.dart';
import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_switch_item.dart';
import 'package:mobx/mobx.dart';

part 'unspent_coins_details_view_model.g.dart';

class UnspentCoinsDetailsViewModel = UnspentCoinsDetailsViewModelBase
    with _$UnspentCoinsDetailsViewModel;

abstract class UnspentCoinsDetailsViewModelBase with Store {
  UnspentCoinsDetailsViewModelBase({
    this.unspentCoinsItem, this.unspentCoinsListViewModel}) {

    final amount = unspentCoinsItem.amount ?? '';
    final address = unspentCoinsItem.address ?? '';
    isFrozen = unspentCoinsItem.isFrozen ?? false;
    note = unspentCoinsItem.note ?? '';

    items = [
      StandartListItem(
        title: S.current.transaction_details_amount,
        value: amount
      ),
      StandartListItem(
        title: S.current.widgets_address,
        value: address
      ),
      TextFieldListItem(
          title: S.current.note_tap_to_change,
          value: note,
          onSubmitted: (value) {
            unspentCoinsItem.note = value;
            unspentCoinsListViewModel.saveUnspentCoinInfo(unspentCoinsItem);
          }),
      UnspentCoinsSwitchItem(
        title: S.current.freeze,
        value: '',
        switchValue: () => isFrozen,
        onSwitchValueChange: (value) async {
          isFrozen = value;
          unspentCoinsItem.isFrozen = value;
          if (value) {
            unspentCoinsItem.isSending = !value;
          }
          await unspentCoinsListViewModel.saveUnspentCoinInfo(unspentCoinsItem);
        }
      )
    ];
  }

  @observable
  bool isFrozen;

  @observable
  String note;

  final UnspentCoinsItem unspentCoinsItem;
  final UnspentCoinsListViewModel unspentCoinsListViewModel;
  List<TransactionDetailsListItem> items;
}