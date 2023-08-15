import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/nano_account.dart';
import 'package:mobx/mobx.dart';
import 'package:hive/hive.dart';

part 'nano_account_list.g.dart';

class NanoAccountList = NanoAccountListBase with _$NanoAccountList;

abstract class NanoAccountListBase with Store {
  NanoAccountListBase(this.address)
      : accounts = ObservableList<NanoAccount>(),
        _isRefreshing = false,
        _isUpdating = false {
    refresh();
  }

  @observable
  ObservableList<NanoAccount> accounts;
  bool _isRefreshing;
  bool _isUpdating;

  String address;

  Future<void> update(String? address) async {
    if (_isUpdating) {
      return;
    }

    try {
      _isUpdating = true;

      final accounts = await getAll(address: address ?? this.address);

      if (accounts.isNotEmpty) {
        this.accounts.clear();
        this.accounts.addAll(accounts);
      }

      _isUpdating = false;
    } catch (e) {
      _isUpdating = false;
      rethrow;
    }
  }

  Future<List<NanoAccount>> getAll({String? address}) async {
    final box = await CakeHive.openBox<NanoAccount>(address ?? this.address);

    // get all accounts in box:
    return box.values.toList();
  }

  Future<void> addAccount({required String label}) async {
    final box = await CakeHive.openBox<NanoAccount>(address);
    final account = NanoAccount(id: box.length, label: label, balance: "0.00", isSelected: false);
    await box.add(account);
    await account.save();
  }

  Future<void> setLabelAccount({required int accountIndex, required String label}) async {
    final box = await CakeHive.openBox<NanoAccount>(address);
    final account = box.getAt(accountIndex);
    account!.label = label;
    await account.save();
  }

  void refresh() {}
}
