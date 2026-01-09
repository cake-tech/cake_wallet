part of 'card_customizer_bloc.dart';

@immutable
sealed class CardCustomizerEvent {}

class _Init extends CardCustomizerEvent {}

class CardDesignSelected extends CardCustomizerEvent {
  final int newDesignIndex;

  CardDesignSelected(this.newDesignIndex);
}

class ColorSelected extends CardCustomizerEvent {
  final int newColorIndex;

  ColorSelected(this.newColorIndex);
}


class AccountNameChanged extends CardCustomizerEvent {
  final String newAccountName;

  AccountNameChanged(this.newAccountName);
}


class DesignSaved extends CardCustomizerEvent {}
