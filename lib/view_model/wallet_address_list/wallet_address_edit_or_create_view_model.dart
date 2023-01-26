import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/haven/haven.dart';
import 'package:cw_core/wallet_type.dart';

part 'wallet_address_edit_or_create_view_model.g.dart';

class WalletAddressEditOrCreateViewModel = WalletAddressEditOrCreateViewModelBase
    with _$WalletAddressEditOrCreateViewModel;

abstract class AddressEditOrCreateState {}

class AddressEditOrCreateStateInitial extends AddressEditOrCreateState {}

class AddressIsSaving extends AddressEditOrCreateState {}

class AddressSavedSuccessfully extends AddressEditOrCreateState {}

class AddressEditOrCreateStateFailure extends AddressEditOrCreateState {
  AddressEditOrCreateStateFailure({required this.error});

  String error;
}

abstract class WalletAddressEditOrCreateViewModelBase with Store {
  WalletAddressEditOrCreateViewModelBase(
      {required WalletBase wallet, WalletAddressListItem? item})
      : isEdit = item != null,
        state = AddressEditOrCreateStateInitial(),
        label = item?.name ?? '',
        _item = item,
        _wallet = wallet;

  @observable
  AddressEditOrCreateState state;

  @observable
  String label;

  bool isEdit;

  final WalletAddressListItem? _item;
  final WalletBase _wallet;

  Future<void> save() async {
    try {
      state = AddressIsSaving();

      if (isEdit) {
        await _update();
      } else {
        await _createNew();
      }

      state = AddressSavedSuccessfully();
    } catch (e) {
      state = AddressEditOrCreateStateFailure(error: e.toString());
    }
  }

  Future<void> _createNew() async {
    final wallet = _wallet;

    if (wallet.type == WalletType.bitcoin
        || wallet.type == WalletType.litecoin) {
      await bitcoin!.generateNewAddress(wallet);
      await wallet.save();
    }

    if (wallet.type == WalletType.monero) {
      await monero
          !.getSubaddressList(wallet)
          .addSubaddress(
            wallet,
            accountIndex: monero!.getCurrentAccount(wallet).id,
            label: label);
      await wallet.save();
    }

    if (wallet.type == WalletType.haven) {
      await haven
          !.getSubaddressList(wallet)
          .addSubaddress(
            wallet,
            accountIndex: haven!.getCurrentAccount(wallet).id,
            label: label);
      await wallet.save();
    }
  }

  Future<void> _update() async {
    final wallet = _wallet;

    /*if (wallet is BitcoinWallet) {
      await wallet.walletAddresses.updateAddress(_item.address as String);
      await wallet.save();
    }*/
    final index = _item?.id;
    if (index != null) {
      if (wallet.type == WalletType.monero) {
        await monero!.getSubaddressList(wallet).setLabelSubaddress(wallet,
            accountIndex: monero!.getCurrentAccount(wallet).id, addressIndex: index, label: label);
        await wallet.save();
      }
      if (wallet.type == WalletType.haven) {
        await haven!.getSubaddressList(wallet).setLabelSubaddress(wallet,
            accountIndex: haven!.getCurrentAccount(wallet).id,
            addressIndex: index,
            label: label);
        await wallet.save();
      }
    }
  }
}
