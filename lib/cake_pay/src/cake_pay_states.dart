abstract class CakePayUserVerificationState {}

class CakePayUserVerificationStateInitial extends CakePayUserVerificationState {}

class CakePayUserVerificationStateSuccess extends CakePayUserVerificationState {}

class CakePayUserVerificationStatePending extends CakePayUserVerificationState {}

class CakePayUserVerificationStateLoading extends CakePayUserVerificationState {}

class CakePayUserVerificationStateFailure extends CakePayUserVerificationState {
  CakePayUserVerificationStateFailure({required this.error});

  final String error;
}

abstract class CakePayOtpState {}

class CakePayOtpValidating extends CakePayOtpState {}

class CakePayOtpSuccess extends CakePayOtpState {}

class CakePayOtpSendDisabled extends CakePayOtpState {}

class CakePayOtpSendEnabled extends CakePayOtpState {}

class CakePayOtpFailure extends CakePayOtpState {
  CakePayOtpFailure({required this.error});

  final String error;
}

class CakePayCreateCardState {}

class CakePayCreateCardStateSuccess extends CakePayCreateCardState {}

class CakePayCreateCardStateLoading extends CakePayCreateCardState {}

class CakePayCreateCardStateFailure extends CakePayCreateCardState {
  CakePayCreateCardStateFailure({required this.error});

  final String error;
}

class UserCakePayCardsState {}

class UserCakePayCardsStateInitial extends UserCakePayCardsState {}

class UserCakePayCardsStateNoCards extends UserCakePayCardsState {}

class UserCakePayCardsStateFetching extends UserCakePayCardsState {}

class UserCakePayCardsStateFailure extends UserCakePayCardsState {
  UserCakePayCardsStateFailure({required this.error});

  final String error;
}

class UserCakePayCardsStateSuccess extends UserCakePayCardsState {}


abstract class CakePayVendorState {}

class InitialCakePayVendorLoadingState extends CakePayVendorState {}

class CakePayVendorLoadingState extends CakePayVendorState {}

class CakePayVendorLoadedState extends CakePayVendorState {}
