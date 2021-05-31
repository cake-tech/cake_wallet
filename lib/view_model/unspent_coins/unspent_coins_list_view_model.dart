import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_item.dart';
import 'package:mobx/mobx.dart';

part 'unspent_coins_list_view_model.g.dart';

const List<Map<String, dynamic>> unspentCoinsMap = [
  <String, dynamic>{
    "address" : "bc1qm80mu5p3mf04a7cj7teymasf04dwpc3av2fwtr",
    "amount" : "0.00358 BTC",
    "isFrozen" : true,
    "note" : "333cvgf23132132132132131321321314rwrtdggfdddewq ewqasfdxgdhgfgfszczcxgbhhhbcgbc"},
  <String, dynamic>{
    "address" : "bc1qm80mu5p3mf04a7cj7teymasf04dwpc3av2fwtr",
    "amount" : "0.00567894 BTC",
    "note" : "sfjskf"},
  <String, dynamic>{
    "address" : "bc1qm80mu5p3mf04a7cj7teymasf04dwpc3av2fwtr",
    "amount" : "0.00087 BTC",
    "isFrozen" : false},
  <String, dynamic>{
    "address" : "bc1qm80mu5p3mf04a7cj7teymasf04dwpc3av2fwtr",
    "amount" : "0.00012 BTC",
    "isFrozen" : true,
    "note" : "333cvgf23132132132132131321321314rwrtdggfdddewq ewqasfdxgdhgfgfszczcxgbhhhbcgbc"},
  <String, dynamic>{
    "address" : "bc1qm80mu5p3mf04a7cj7teymasf04dwpc3av2fwtr",
    "amount" : "0.00574 BTC",
    "note" : "sffsfsdsgs"},
  <String, dynamic>{
    "address" : "bc1qm80mu5p3mf04a7cj7teymasf04dwpc3av2fwtr",
    "amount" : "0.000482 BTC",
    "isFrozen" : false},
  <String, dynamic>{},
  <String, dynamic>{
    "address" : "bc1qm80mu5p3mf04a7cj7teymasf04dwpc3av2fwtr",
    "amount" : "0.00012 BTC",
    "isFrozen" : true,
    "note" : "333cvgf23132132132132131321321314rwrtdggfdddewq ewqasfdxgdhgfgfszczcxgbhhhbcgbc"},
  <String, dynamic>{
    "address" : "bc1qm80mu5p3mf04a7cj7teymasf04dwpc3av2fwtr",
    "amount" : "0.00574 BTC",
    "note" : "sffsfsdsgs"},
  <String, dynamic>{
    "address" : "bc1qm80mu5p3mf04a7cj7teymasf04dwpc3av2fwtr",
    "amount" : "0.000482 BTC",
    "isFrozen" : false},
];

class UnspentCoinsListViewModel = UnspentCoinsListViewModelBase with _$UnspentCoinsListViewModel;

abstract class UnspentCoinsListViewModelBase with Store {
  @computed
  ObservableList<UnspentCoinsItem> get items =>
      ObservableList.of(unspentCoinsMap.map((elem) =>
        UnspentCoinsItem(
          address: elem["address"] as String,
          amount: elem["amount"] as String,
          isFrozen: elem["isFrozen"] as bool,
          note: elem["note"] as String
      )));
}