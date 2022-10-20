import 'package:cake_wallet/ionia/ionia_virtual_card.dart';
import 'package:flutter/material.dart';

abstract class IoniaCreateAccountState {}

class IoniaInitialCreateState extends IoniaCreateAccountState {}

class IoniaCreateStateSuccess extends IoniaCreateAccountState {}

class IoniaCreateStateLoading extends IoniaCreateAccountState {}

class IoniaCreateStateFailure extends IoniaCreateAccountState {
  IoniaCreateStateFailure({required this.error});

  final String error;
}

abstract class IoniaOtpState {}

class IoniaOtpValidating extends IoniaOtpState {}

class IoniaOtpSuccess extends IoniaOtpState {}

class IoniaOtpSendDisabled extends IoniaOtpState {}

class IoniaOtpSendEnabled extends IoniaOtpState {}

class IoniaOtpFailure extends IoniaOtpState {
  IoniaOtpFailure({required this.error});

  final String error;
}

class IoniaCreateCardState {}

class IoniaCreateCardSuccess extends IoniaCreateCardState {}

class IoniaCreateCardLoading extends IoniaCreateCardState {}

class IoniaCreateCardFailure extends IoniaCreateCardState {
  IoniaCreateCardFailure({required this.error});

  final String error;
}

class IoniaFetchCardState {}

class IoniaNoCardState extends IoniaFetchCardState {}

class IoniaFetchingCard extends IoniaFetchCardState {}

class IoniaFetchCardFailure extends IoniaFetchCardState {}

class IoniaCardSuccess extends IoniaFetchCardState {
  IoniaCardSuccess({required this.card});

  final IoniaVirtualCard card;
}

abstract class IoniaMerchantState {}

class InitialIoniaMerchantLoadingState extends IoniaMerchantState {}

class IoniaLoadingMerchantState extends IoniaMerchantState {}

class IoniaLoadedMerchantState extends IoniaMerchantState {}


