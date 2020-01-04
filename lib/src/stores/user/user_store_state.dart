import 'package:flutter/foundation.dart';

abstract class UserStoreState {}

class UserStoreStateInitial extends UserStoreState {}

class PinCodeSetSuccesfully extends UserStoreState {}

class PinCodeSetFailed extends UserStoreState {
  String error;

  PinCodeSetFailed({@required this.error});
}
