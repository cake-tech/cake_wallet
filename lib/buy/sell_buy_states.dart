abstract class PaymentMethodLoadingState {}

class InitialPaymentMethod extends PaymentMethodLoadingState {}

class PaymentMethodLoading extends PaymentMethodLoadingState {}

class PaymentMethodLoaded extends PaymentMethodLoadingState {}

class PaymentMethodFailed extends PaymentMethodLoadingState {}


abstract class BuySellQuotLoadingState {}

class InitialBuySellQuotState extends BuySellQuotLoadingState {}

class BuySellQuotLoading extends BuySellQuotLoadingState {}

class BuySellQuotLoaded extends BuySellQuotLoadingState {}

class BuySellQuotFailed extends BuySellQuotLoadingState {}