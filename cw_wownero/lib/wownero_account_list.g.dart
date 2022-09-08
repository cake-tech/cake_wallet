// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wownero_account_list.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$WowneroAccountList on WowneroAccountListBase, Store {
  late final _$accountsAtom =
      Atom(name: 'WowneroAccountListBase.accounts', context: context);

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
