import 'package:flutter/services.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_monero/api/coins_info.dart';
import 'package:cw_monero/api/subaddress_list.dart' as subaddress_list;
import 'package:cw_core/subaddress.dart';

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

    return subaddresses.map((subaddressRow) {
      final hasDefaultAddressName =
          subaddressRow.getLabel().toLowerCase() == 'Primary account'.toLowerCase() ||
              subaddressRow.getLabel().toLowerCase() == 'Untitled account'.toLowerCase();
      final isPrimaryAddress = subaddressRow.getId() == 0 && hasDefaultAddressName;
      return Subaddress(
          id: subaddressRow.getId(),
          address: subaddressRow.getAddress(),
          label: isPrimaryAddress
              ? 'Primary address'
              : hasDefaultAddressName
                  ? ''
                  : subaddressRow.getLabel());
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
      print(e);
      rethrow;
    }
  }

  Future<void> updateWithAutoGenerate({
    required int accountIndex,
    required String defaultLabel,
    required List<String> usedAddresses,
  }) async {
    _usedAddresses.addAll(usedAddresses);
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

    if (allAddresses.isEmpty || _usedAddresses.contains(allAddresses.last.getAddress())) {
      final isAddressUnused = await _newSubaddress(accountIndex: accountIndex, label: label);
      if (!isAddressUnused) {
        return await _getAllUnusedAddresses(accountIndex: accountIndex, label: label);
      }
    }

    return allAddresses
        .map((subaddressRow) => Subaddress(
            id: subaddressRow.getId(),
            address: subaddressRow.getAddress(),
            label: subaddressRow.getId() == 0 &&
                    subaddressRow.getLabel().toLowerCase() == 'Primary account'.toLowerCase()
                ? 'Primary address'
                : subaddressRow.getLabel()))
        .toList();
  }

  Future<bool> _newSubaddress({required int accountIndex, required String label}) async {
    await subaddress_list.addSubaddress(accountIndex: accountIndex, label: label);

    return subaddress_list
        .getAllSubaddresses()
        .where((subaddressRow) => !_usedAddresses.contains(subaddressRow.getAddress()))
        .isNotEmpty;
  }
}
