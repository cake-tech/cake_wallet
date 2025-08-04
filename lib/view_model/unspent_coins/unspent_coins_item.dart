import 'package:cw_core/unspent_comparable_mixin.dart';
import 'package:mobx/mobx.dart';

part 'unspent_coins_item.g.dart';

class UnspentCoinsItem = UnspentCoinsItemBase with _$UnspentCoinsItem;

abstract class UnspentCoinsItemBase with Store, UnspentComparable {
  UnspentCoinsItemBase({
    required this.address,
    required this.amount,
    required this.hash,
    required this.isFrozen,
    required this.note,
    required this.isSending,
    required this.isChange,
    required this.value,
    required this.vout,
    required this.keyImage,
    required this.isSilentPayment,
  });

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

  @observable
  bool isChange;

  @observable
  int value;

  @observable
  int vout;

  @observable
  String? keyImage;

  @observable
  bool isSilentPayment;
}
