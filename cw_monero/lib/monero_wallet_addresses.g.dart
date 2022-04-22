// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monero_wallet_addresses.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$MoneroWalletAddresses on MoneroWalletAddressesBase, Store {
  final _$addressAtom = Atom(name: 'MoneroWalletAddressesBase.address');

  @override
  String get address {
    _$addressAtom.reportRead();
    return super.address;
  }

  @override
  set address(String value) {
    _$addressAtom.reportWrite(value, super.address, () {
      super.address = value;
    });
  }

  final _$accountAtom = Atom(name: 'MoneroWalletAddressesBase.account');

  @override
  Account get account {
    _$accountAtom.reportRead();
    return super.account;
  }

  @override
  set account(Account value) {
    _$accountAtom.reportWrite(value, super.account, () {
      super.account = value;
    });
  }

  final _$subaddressAtom = Atom(name: 'MoneroWalletAddressesBase.subaddress');

  @override
  Subaddress get subaddress {
    _$subaddressAtom.reportRead();
    return super.subaddress;
  }

  @override
  set subaddress(Subaddress value) {
    _$subaddressAtom.reportWrite(value, super.subaddress, () {
      super.subaddress = value;
    });
  }

  @override
  String toString() {
    return '''
address: ${address},
account: ${account},
subaddress: ${subaddress}
    ''';
  }
}
