import 'package:flutter/foundation.dart';

abstract class WalletCreationState {}

class WalletCreating extends WalletCreationState {}

class WalletCreatedSuccessfully extends WalletCreationState {}

class WalletCreationFailure extends WalletCreationState {
  WalletCreationFailure({required this.error});

  final String error;
}