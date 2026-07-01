// import 'package:hive/hive.dart';
// import 'package:mobx/mobx.dart';
// import 'package:cake_wallet/entities/contact.dart';
// import 'package:cw_core/crypto_currency.dart';

// part 'contact_model.g.dart';

// class ContactModel = ContactModelBase with _$ContactModel;

// abstract class ContactModelBase with Store {
//   ContactModelBase(this._contacts, {Contact contact}) : _contact = contact {
//     name = _contact?.name;
//     address = _contact?.address;
//     currency = _contact?.type;

//     _contacts.watch(key: contact.key).listen((event) {

//     });
//   }

//   @observable
//   String name;

//   @observable
//   String address;

//   @observable
//   CryptoCurrency currency;

//   // @computed
//   // bool get isReady =>
//   //     (name?.isNotEmpty ?? false) &&
//   //     (currency?.toString()?.isNotEmpty ?? false) &&
//   //     (address?.isNotEmpty ?? false);

//   final Box<ContactBase> _contacts;
//   final Contact _contact;
// }
