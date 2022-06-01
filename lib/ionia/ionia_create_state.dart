import 'package:flutter/material.dart';

abstract class IoniaCreateState {}

class IoniaCreateStateSuccess extends IoniaCreateState {}

class IoniaCreateStateLoading extends IoniaCreateState {}

class IoniaCreateStateFailure extends IoniaCreateState {
  IoniaCreateStateFailure({@required this.error});

  final String error;
}

abstract class IoniaOtpState {}

class IoniaOtpValidating extends IoniaOtpState {}

class IoniaOtpSuccess extends IoniaOtpState {}

class IoniaOtpSendDisabled extends IoniaOtpState {}

class IoniaOtpSendEnabled extends IoniaOtpState {}

class IoniaOtpFailure extends IoniaOtpState {
  IoniaOtpFailure({@required this.error});

  final String error;
}
