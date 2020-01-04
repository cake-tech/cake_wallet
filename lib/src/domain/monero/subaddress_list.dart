import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cw_monero/subaddress_list.dart' as subaddressListAPI;
import 'package:cake_wallet/src/domain/monero/subaddress.dart';

class SubaddressList {
  get subaddresses => _subaddress.stream;
  BehaviorSubject<List<Subaddress>> _subaddress;

  bool _isRefreshing;
  bool _isUpdating;

  SubaddressList() {
    _isRefreshing = false;
    _isUpdating = false;
    _subaddress = BehaviorSubject<List<Subaddress>>();
  }

  Future update({int accountIndex}) async {
    if (_isUpdating) {
      return;
    }

    try {
      _isUpdating = true;
      await refresh(accountIndex: accountIndex);
      final subaddresses = getAll();
      _subaddress.add(subaddresses);
      _isUpdating = false;
    } catch (e) {
      _isUpdating = false;
      throw e;
    }
  }

  List<Subaddress> getAll() {
    return subaddressListAPI
        .getAllSubaddresses()
        .map((subaddressRow) => Subaddress.fromRow(subaddressRow))
        .toList();
  }

  Future addSubaddress({int accountIndex, String label}) async {
    await subaddressListAPI.addSubaddress(accountIndex: accountIndex, label: label);
    await update(accountIndex: accountIndex);
  }

  Future setLabelSubaddress(
      {int accountIndex, int addressIndex, String label}) async {
    await subaddressListAPI.setLabelForSubaddress(
        accountIndex: accountIndex, addressIndex: addressIndex, label: label);
    await update();
  }

  Future refresh({int accountIndex}) async {
    if (_isRefreshing) {
      return;
    }

    try {
      _isRefreshing = true;
      subaddressListAPI.refreshSubaddresses(accountIndex: accountIndex);
      _isRefreshing = false;
    } on PlatformException catch (e) {
      _isRefreshing = false;
      print(e);
      throw e;
    }
  }
}
