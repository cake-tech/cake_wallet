// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monero_account_list.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$MoneroAccountList on MoneroAccountListBase, Store {
  final _$accountsAtom = Atom(name: 'MoneroAccountListBase.accounts');

  @override
  ObservableList<Account> get accounts {
    _$accountsAtom.reportRead();
    return super.accounts;
  }

  @override
  set accounts(ObservableList<Account> value) {
    _$accountsAtom.reportWrite(value, super.accounts, () {
      super.accounts = value;
    });
  }

  @override
  String toString() {
    return '''
accounts: ${accounts}
    ''';
  }
}
