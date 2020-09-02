import 'package:flutter/foundation.dart';

abstract class SendViewModelState {}

class InitialSendViewModelState extends SendViewModelState {}

class TransactionIsCreating extends SendViewModelState {}
class TransactionCreatedSuccessfully extends SendViewModelState {}

class TransactionCommitting extends SendViewModelState {}

class TransactionCommitted extends SendViewModelState {}

class SendingFailed extends SendViewModelState {
  SendingFailed({@required this.error});

  String error;
}