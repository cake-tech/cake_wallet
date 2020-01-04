import 'package:flutter/foundation.dart';

abstract class SendingState {}

class SendingStateInitial extends SendingState {}

class CreatingTransaction extends SendingState {}

class TransactionCreatedSuccessfully extends SendingState {}

class TransactionCommiting extends SendingState {}

class TransactionCommitted extends SendingState {}

class SendingFailed extends SendingState {
  String error;

  SendingFailed({@required this.error});
}
