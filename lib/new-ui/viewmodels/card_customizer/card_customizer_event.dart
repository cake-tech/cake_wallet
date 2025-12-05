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

class DesignSaved extends CardCustomizerEvent {}
