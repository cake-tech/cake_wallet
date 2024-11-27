import 'package:cw_core/subaddress.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_monero/api/coins_info.dart';
import 'package:cw_monero/api/subaddress_list.dart' as subaddress_list;
import 'package:cw_monero/api/wallet.dart';
import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';

part 'monero_subaddress_list.g.dart';

class MoneroSubaddressList = MoneroSubaddressListBase with _$MoneroSubaddressList;

abstract class MoneroSubaddressListBase with Store {
  MoneroSubaddressListBase()
      : _isRefreshing = false,
        _isUpdating = false,
        subaddresses = ObservableList<Subaddress>();

  final List<String> _usedAddresses = [];

  @observable
  ObservableList<Subaddress> subaddresses;

  bool _isRefreshing;
  bool _isUpdating;

  void update({required int accountIndex}) {
    refreshCoins(accountIndex);

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

    return subaddresses.map((s) {
      final address = s.address;
      final label = s.label;
      final id = s.addressIndex;
      return Subaddress(
          id: id,
          address: address,
          balance: (s.received/1e12).toStringAsFixed(6),
          txCount: s.txCount,
          label: label);
    }).toList();
  }

  Future<void> addSubaddress({required int accountIndex, required String label}) async {
    await subaddress_list.addSubaddress(accountIndex: accountIndex, label: label);
    update(accountIndex: accountIndex);
  }

  Future<void> setLabelSubaddress(
      {required int accountIndex, required int addressIndex, required String label}) async {
    await subaddress_list.setLabelForSubaddress(
        accountIndex: accountIndex, addressIndex: addressIndex, label: label);
    update(accountIndex: accountIndex);
  }

  void refresh({required int accountIndex}) {
    if (_isRefreshing) {
      return;
    }

    try {
      _isRefreshing = true;
      subaddress_list.refreshSubaddresses(accountIndex: accountIndex);
      _isRefreshing = false;
    } on PlatformException catch (e) {
      _isRefreshing = false;
      printV(e);
      rethrow;
    }
  }

  Future<void> updateWithAutoGenerate({
    required int accountIndex,
    required String defaultLabel,
    required List<String> usedAddresses,
  }) async {
    _usedAddresses.addAll(usedAddresses);
    final _all = _usedAddresses.toSet().toList();
    _usedAddresses.clear();
    _usedAddresses.addAll(_all);
    if (_isUpdating) {
      return;
    }

    try {
      _isUpdating = true;
      refresh(accountIndex: accountIndex);
      subaddresses.clear();
      final newSubAddresses =
          await _getAllUnusedAddresses(accountIndex: accountIndex, label: defaultLabel);
      subaddresses.addAll(newSubAddresses);
    } catch (e) {
      rethrow;
    } finally {
      _isUpdating = false;
    }
  }

  Future<List<Subaddress>> _getAllUnusedAddresses(
      {required int accountIndex, required String label}) async {
    final allAddresses = subaddress_list.getAllSubaddresses();
    // first because addresses come in reversed order.
    if (allAddresses.isEmpty || _usedAddresses.contains(allAddresses.first.address)) {
      final isAddressUnused = await _newSubaddress(accountIndex: accountIndex, label: label);
      if (!isAddressUnused) {
        return await _getAllUnusedAddresses(accountIndex: accountIndex, label: label);
      }
    }

    return allAddresses
        .map((s) {
          final id = s.addressIndex;
          final address = s.address;
          final label = s.label;
          return Subaddress(
            id: id,
            address: address,
            balance: (s.received/1e12).toStringAsFixed(6),
            txCount: s.txCount,
            label: id == 0 &&
                    label.toLowerCase() == 'Primary account'.toLowerCase()
                ? 'Primary address'
                : label);
      }).toList().reversed.toList();
  }

  Future<bool> _newSubaddress({required int accountIndex, required String label}) async {
    await subaddress_list.addSubaddress(accountIndex: accountIndex, label: label);

    return subaddress_list
        .getAllSubaddresses()
        .where((s) {
          final address = s.address;
          return !_usedAddresses.contains(address);
        })
        .isNotEmpty;
  }
}
