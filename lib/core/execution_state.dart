abstract class ExecutionState {}

class InitialExecutionState extends ExecutionState {}

class LoadingTemplateExecutingState extends ExecutionState {}

class IsExecutingState extends ExecutionState {}

class ExecutedSuccessfullyState extends ExecutionState {
  ExecutedSuccessfullyState({this.payload});

  final dynamic payload;
}

class FailureState extends ExecutionState {
  FailureState(this.error);

  final String error;
}

class AwaitingConfirmationState extends ExecutionState {
  AwaitingConfirmationState({this.title, this.message, this.onConfirm, this.onCancel});

  final String? title;
  final String? message;
  final Function()? onConfirm;
  final Function()? onCancel;
}