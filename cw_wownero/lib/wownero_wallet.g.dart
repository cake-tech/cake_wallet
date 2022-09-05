// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wownero_wallet.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$WowneroWallet on WowneroWalletBase, Store {
  final _$syncStatusAtom = Atom(name: 'WowneroWalletBase.syncStatus');

  @override
  SyncStatus? get syncStatus {
    _$syncStatusAtom.reportRead();
    return super.syncStatus;
  }

  @override
  set syncStatus(SyncStatus? value) {
    _$syncStatusAtom.reportWrite(value, super.syncStatus, () {
      super.syncStatus = value;
    });
  }

  final _$balanceAtom = Atom(name: 'WowneroWalletBase.balance');

  @override
  ObservableMap<CryptoCurrency?, WowneroBalance>? get balance {
    _$balanceAtom.reportRead();
    return super.balance;
  }

  @override
  set balance(ObservableMap<CryptoCurrency?, WowneroBalance>? value) {
    _$balanceAtom.reportWrite(value, super.balance, () {
      super.balance = value;
    });
  }

  @override
  String toString() {
    return '''
syncStatus: ${syncStatus},
balance: ${balance}
    ''';
  }
}
