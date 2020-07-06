import 'package:flutter/foundation.dart';

abstract class MoneroAccountEditOrCreateState {}

class InitialAccountCreationState extends MoneroAccountEditOrCreateState {}

class AccountIsCreating extends MoneroAccountEditOrCreateState {}

class AccountCreatedSuccessfully extends MoneroAccountEditOrCreateState {}

class AccountCreationFailure extends MoneroAccountEditOrCreateState {
  AccountCreationFailure({@required this.error});

  final String error;
}