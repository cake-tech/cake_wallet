import 'package:cake_wallet/view_model/unspent_coins/unspent_coins_item.dart';
import 'package:mobx/mobx.dart';

part 'unspent_coins_list_view_model.g.dart';

const List<Map<String, dynamic>> unspentCoinsMap = [
  <String, dynamic>{
    "address" : "11111111111111121111132432432432432432432443124324324234324324324324332424",
    "amount" : "222",
    "isFrozen" : true,
    "note" : "333cvgf23132132132132131321321314rwrtdggfdddewq ewqasfdxgdhgfgfszczcxgbhhhbcgbc"},
  <String, dynamic>{
    "address" : "444",
    "amount" : "555",
    "note" : "sfjskf"},
  <String, dynamic>{
    "address" : "777",
    "amount" : "888",
    "isFrozen" : false},
  <String, dynamic>{
    "address" : "11111111111111121111132432432432432432432443124324324234324324324324332424",
    "amount" : "222",
    "isFrozen" : true,
    "note" : "333cvgf23132132132132131321321314rwrtdggfdddewq ewqasfdxgdhgfgfszczcxgbhhhbcgbc"},
  <String, dynamic>{
    "address" : "444",
    "amount" : "555",
    "note" : "sffsfsdsgs"},
  <String, dynamic>{
    "address" : "777",
    "amount" : "888",
    "isFrozen" : false},
  <String, dynamic>{},
];

class UnspentCoinsListViewModel = UnspentCoinsListViewModelBase with _$UnspentCoinsListViewModel;

abstract class UnspentCoinsListViewModelBase with Store {
  @computed
  List<UnspentCoinsItem> get items => unspentCoinsMap.map((elem) =>
      UnspentCoinsItem(
        address: elem["address"] as String,
        amount: elem["amount"] as String,
        isFrozen: elem["isFrozen"] as bool,
        note: elem["note"] as String
      )).toList();
}