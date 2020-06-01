import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cw_monero/subaddress_list.dart' as subaddress_list;
import 'package:cake_wallet/src/domain/monero/subaddress.dart';

class SubaddressList {
  SubaddressList() {
    _isRefreshing = false;
    _isUpdating = false;
    _subaddress = BehaviorSubject<List<Subaddress>>();
  }

  Observable<List<Subaddress>> get subaddresses => _subaddress.stream;

  BehaviorSubject<List<Subaddress>> _subaddress;
  bool _isRefreshing;
  bool _isUpdating;

  void update({int accountIndex}) {
    if (_isUpdating) {
      return;
    }

    try {
      _isUpdating = true;
      refresh(accountIndex: accountIndex);
      _subaddress.add(getAll());
      _isUpdating = false;
    } catch (e) {
      _isUpdating = false;
      rethrow;
    }
  }

  List<Subaddress> getAll() {
    return subaddress_list
        .getAllSubaddresses()
        .map((subaddressRow) => Subaddress.fromRow(subaddressRow))
        .toList();
  }

  Future addSubaddress({int accountIndex, String label}) async {
    await subaddress_list.addSubaddress(
        accountIndex: accountIndex, label: label);
    await update(accountIndex: accountIndex);
  }

  Future setLabelSubaddress(
      {int accountIndex, int addressIndex, String label}) async {
    await subaddress_list.setLabelForSubaddress(
        accountIndex: accountIndex, addressIndex: addressIndex, label: label);
    await update(accountIndex: accountIndex);
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
