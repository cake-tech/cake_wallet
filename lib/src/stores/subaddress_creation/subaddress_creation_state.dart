abstract class SubaddressCreationState {}

class SubaddressCreationStateInitial extends SubaddressCreationState {}

class SubaddressIsCreating extends SubaddressCreationState {}

class SubaddressCreatedSuccessfully extends SubaddressCreationState {}

class SubaddressCreationFailure extends SubaddressCreationState {
  String error;

  SubaddressCreationFailure({this.error});
}