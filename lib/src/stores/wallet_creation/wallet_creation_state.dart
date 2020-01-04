import 'package:flutter/foundation.dart';

abstract class WalletCreationState {}

class WalletCreationStateInitial extends WalletCreationState {}

class WalletIsCreating extends WalletCreationState {}

class WalletCreatedSuccessfully extends WalletCreationState {}

class WalletCreationFailure extends WalletCreationState {
  String error;
  WalletCreationFailure({@required this.error});
}