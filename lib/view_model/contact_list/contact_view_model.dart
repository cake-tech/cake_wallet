import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/core/contact_service.dart';
import 'package:cake_wallet/src/domain/common/contact.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model_state.dart';

part 'contact_view_model.g.dart';

class ContactViewModel = ContactViewModelBase with _$ContactViewModel;

abstract class ContactViewModelBase with Store {
  ContactViewModelBase(this._contactService, this._wallet, {Contact contact})
      : state = InitialContactViewModelState(),
        currencies = CryptoCurrency.all,
        _contact = contact {
    name = _contact?.name;
    address = _contact?.address;
    currency = _contact?.type; //_wallet.currency;
  }

  @observable
  ContactViewModelState state;

  @observable
  String name;

  @observable
  String address;

  @observable
  CryptoCurrency currency;

  @computed
  bool get isReady =>
      (name?.isNotEmpty ?? false) && (currency?.toString()?.isNotEmpty ?? false)
      && (address?.isNotEmpty ?? false);

  final List<CryptoCurrency> currencies;
  final ContactService _contactService;
  final WalletBase _wallet;
  final Contact _contact;

  @action
  void reset() {
    address = '';
    name = '';
    //currency = _wallet.currency;
    currency = null;
  }

  Future save() async {
    try {
      state = ContactIsCreating();

      if (_contact != null) {
        _contact.name = name;
        _contact.address = address;
        _contact.updateCryptoCurrency(currency: currency);
        await _contactService.update(_contact);
      } else {
        await _contactService
            .add(Contact(name: name, address: address, type: currency));
      }

      state = ContactSavingSuccessfully();
    } catch (e) {
      state = ContactCreationFailure(e.toString());
    }
  }
}
