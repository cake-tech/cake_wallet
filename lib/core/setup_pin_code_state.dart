import 'package:flutter/foundation.dart';

abstract class SetupPinCodeState {}

class InitialSetupPinCodeState extends SetupPinCodeState {}

class SetupPinCodeInProgress extends SetupPinCodeState {}

class SetupPinCodeFinishedSuccessfully extends SetupPinCodeState {}

class SetupPinCodeFinishedFailure extends SetupPinCodeState {
  SetupPinCodeFinishedFailure({@required this.error});

  final String error;
}