import 'package:cake_wallet/core/execution_state.dart';

class IsDeviceSigningResponseState extends IsExecutingState {}
class IsAwaitingDeviceResponseState extends IsExecutingState {}
class TransactionCommitting extends ExecutionState {}
class TransactionCommitted extends ExecutionState {}
