abstract class ExecutionState {}

class InitialExecutionState extends ExecutionState {}

class IsExecutingState extends ExecutionState {}

class ExecutedSuccessfullyState extends ExecutionState {
  ExecutedSuccessfullyState({this.payload});

  final dynamic payload;
}

class FailureState extends ExecutionState {
  FailureState(this.error);

  final String error;
}