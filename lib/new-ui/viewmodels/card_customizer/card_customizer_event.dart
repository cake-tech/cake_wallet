part of "card_customizer_bloc.dart";

@immutable
sealed class CardCustomizerEvent {}

class _Init extends CardCustomizerEvent {}

class CardDesignSelected extends CardCustomizerEvent {

  CardDesignSelected(this.newDesignIndex);
  final int newDesignIndex;
}

class ColorSelected extends CardCustomizerEvent {

  ColorSelected(this.newColorIndex);
  final int newColorIndex;
}

class AccountNameChanged extends CardCustomizerEvent {

  AccountNameChanged(this.newAccountName);
  final String newAccountName;
}

class DesignSaved extends CardCustomizerEvent {}

class IconStyleSelected extends CardCustomizerEvent {

  IconStyleSelected(this.iconIndex);
  final int iconIndex;
}

class AccountHidden extends CardCustomizerEvent {}
