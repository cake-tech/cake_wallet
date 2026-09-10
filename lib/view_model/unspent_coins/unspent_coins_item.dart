import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/unspent_comparable_mixin.dart";
import "package:mobx/mobx.dart";

part "unspent_coins_item.g.dart";

class UnspentCoinsItem = UnspentCoinsItemBase with _$UnspentCoinsItem;

abstract class UnspentCoinsItemBase with Store, UnspentComparable {
  UnspentCoinsItemBase({
    required this.cryptoCurrency,
    required this.address,
    required this.hash,
    required this.isFrozen,
    required this.note,
    required this.isSending,
    required this.isChange,
    required this.value,
    required this.vout,
    required this.keyImage,
    required this.isSilentPayment,
    this.isBeingSaved = false,
  });

  final CryptoCurrency cryptoCurrency;

  @override
  @observable
  String address;

  @override
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

  @override
  @observable
  int value;

  @override
  @observable
  int vout;

  @override
  @observable
  String? keyImage;

  @observable
  bool isSilentPayment;

  @observable
  bool isBeingSaved;

  @computed
  CryptoMoney get amount => Money.fromInt(value, cryptoCurrency);

  @computed
  String get id => "$hash:$vout:$keyImage";
}
