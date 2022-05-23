import 'package:cw_wownero/api/structs/subaddress_row.dart';
import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_wownero/api/subaddress_list.dart' as subaddress_list;
import 'package:cw_core/subaddress.dart';

part 'wownero_subaddress_list.g.dart';

class WowneroSubaddressList = WowneroSubaddressListBase
    with _$WowneroSubaddressList;

abstract class WowneroSubaddressListBase with Store {
  WowneroSubaddressListBase() {
    _isRefreshing = false;
    _isUpdating = false;
    subaddresses = ObservableList<Subaddress>();
  }

  @observable
  ObservableList<Subaddress> subaddresses;

  bool _isRefreshing;
  bool _isUpdating;

  void update({int accountIndex}) {
    if (_isUpdating) {
      return;
    }

    try {
      _isUpdating = true;
      refresh(accountIndex: accountIndex);
      subaddresses.clear();
      subaddresses.addAll(getAll());
      _isUpdating = false;
    } catch (e) {
      _isUpdating = false;
      rethrow;
    }
  }

  List<Subaddress> getAll() {
    var subaddresses = subaddress_list.getAllSubaddresses();

    if (subaddresses.length > 2) {
      final primary = subaddresses.first;
      final rest = subaddresses.sublist(1).reversed;
      subaddresses = [primary] + rest.toList();
    }

    return subaddresses
        .map((subaddressRow) => Subaddress(
          id: subaddressRow.getId(),
          address: subaddressRow.getAddress(),
          label: subaddressRow.getId() == 0 &&
                subaddressRow.getLabel().toLowerCase() == 'Primary account'.toLowerCase()
            ? 'Primary address'
            : subaddressRow.getLabel()))
        .toList();
  }

  Future addSubaddress({int accountIndex, String label}) async {
    await subaddress_list.addSubaddress(
        accountIndex: accountIndex, label: label);
    update(accountIndex: accountIndex);
  }

  Future setLabelSubaddress(
      {int accountIndex, int addressIndex, String label}) async {
    await subaddress_list.setLabelForSubaddress(
        accountIndex: accountIndex, addressIndex: addressIndex, label: label);
    update(accountIndex: accountIndex);
  }

  void refresh({int accountIndex}) {
    if (_isRefreshing) {
      return;
    }

    try {
      _isRefreshing = true;
      subaddress_list.refreshSubaddresses(accountIndex: accountIndex);
      _isRefreshing = false;
    } on PlatformException catch (e) {
      _isRefreshing = false;
      print(e);
      rethrow;
    }
  }
}
