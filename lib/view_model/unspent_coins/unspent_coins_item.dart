import 'package:mobx/mobx.dart';

part 'unspent_coins_item.g.dart';

class UnspentCoinsItem = UnspentCoinsItemBase with _$UnspentCoinsItem;

abstract class UnspentCoinsItemBase with Store {
  UnspentCoinsItemBase({
    required this.address,
    required this.amount,
    required this.hash,
    required this.isFrozen,
    required this.note,
    required this.isSending});

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