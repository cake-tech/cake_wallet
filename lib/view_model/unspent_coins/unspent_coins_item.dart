import 'package:mobx/mobx.dart';

part 'unspent_coins_item.g.dart';

class UnspentCoinsItem = UnspentCoinsItemBase with _$UnspentCoinsItem;

abstract class UnspentCoinsItemBase with Store {
  UnspentCoinsItemBase({
    this.address,
    this.amount,
    this.hash,
    this.isFrozen,
    this.note,
    this.isSending});

  @observable
  String address;

  @observable
  String amount;

  @observable
  String hash;

  @observable
  bool isFrozen;

  @observable
  String note;

  @observable
  bool isSending;
}