abstract class ContactViewModelState {}

class InitialContactViewModelState extends ContactViewModelState {}

class ContactIsCreating extends ContactViewModelState {}

class ContactSavingSuccessfully extends ContactViewModelState {}

class ContactCreationFailure extends ContactViewModelState {
  ContactCreationFailure(this.error);

  final String error;
}