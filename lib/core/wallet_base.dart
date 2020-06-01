import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/common/node.dart';

abstract class WalletBase<BalaceType> {
  String get name;

  String get filename;

  @observable
  String address;

  @observable
  BalaceType balance;

  Future<void> connectToNode({@required Node node});
  Future<void> startSync();
  Future<void> createTransaction(Object credentials);
  Future<void> save();
}