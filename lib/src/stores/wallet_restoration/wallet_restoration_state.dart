import 'package:flutter/foundation.dart';

abstract class WalletRestorationState {}

class WalletRestorationStateInitial extends WalletRestorationState {}

class WalletIsRestoring extends WalletRestorationState {}

class WalletRestoredSuccessfully extends WalletRestorationState {}

class WalletRestorationFailure extends WalletRestorationState {
  String error;
  WalletRestorationFailure({@required this.error});
}