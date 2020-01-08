abstract class SubaddressCreationState {}

class SubaddressCreationStateInitial extends SubaddressCreationState {}

class SubaddressIsCreating extends SubaddressCreationState {}

class SubaddressCreatedSuccessfully extends SubaddressCreationState {}

class SubaddressCreationFailure extends SubaddressCreationState {
  SubaddressCreationFailure({this.error});
  
  String error;
}