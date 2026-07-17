import 'package:cake_wallet/core/address_service.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
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
  WalletAddressEditOrCreateViewModelBase({
    required WalletBase wallet,
    required AddressService addressService,
    WalletAddressListItem? item,
  })  : isEdit = item != null,
        state = AddressEditOrCreateStateInitial(),
        label = item?.name ?? '',
        _item = item,
        _wallet = wallet,
        _addressService = addressService;

  @observable
  AddressEditOrCreateState state;

  @observable
  String label;

  bool isEdit;

  final WalletAddressListItem? _item;
  final WalletBase _wallet;
  final AddressService _addressService;

  bool get isElectrum =>
      _wallet.type == WalletType.bitcoin ||
      _wallet.type == WalletType.bitcoinCash ||
      _wallet.type == WalletType.litecoin ||
      _wallet.type == WalletType.dogecoin;

  String get derivationPath => _item?.derivationPath ?? '';
  String get index => _item?.id.toString() ?? '';

  Future<void> save() async {
    try {
      state = AddressIsSaving();

      if (isEdit) {
        await _addressService.setLabel(_item!.address, label);
      } else {
        await _addressService.addManualAddress(label);
      }

      state = AddressSavedSuccessfully();
    } catch (e) {
      state = AddressEditOrCreateStateFailure(error: e.toString());
    }
  }
}
