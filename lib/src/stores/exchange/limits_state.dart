import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/exchange/limits.dart';

abstract class LimitsState {}

class LimitsInitialState extends LimitsState {}

class LimitsIsLoading extends LimitsState {}

class LimitsLoadedSuccessfully extends LimitsState {
  final Limits limits;

  LimitsLoadedSuccessfully({@required this.limits});
}

class LimitsLoadedFailure extends LimitsState {
  final String error;

  LimitsLoadedFailure({@required this.error});
}
