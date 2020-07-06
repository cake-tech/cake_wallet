abstract class NodeCreateOrEditViewModelState {}

class InitialNodeCreateOrEditViewModelState
    extends NodeCreateOrEditViewModelState {}

class NodeIsCreating extends NodeCreateOrEditViewModelState {}

class NodeCreatedSuccessfully extends NodeCreateOrEditViewModelState {}

class NodeCreateOrEditViewModelFailure extends NodeCreateOrEditViewModelState {
  NodeCreateOrEditViewModelFailure(this.error);

  final String error;
}
