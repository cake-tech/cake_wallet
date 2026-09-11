part of "coin_control_bloc.dart";

@immutable
sealed class CoinControlEvent {
  const CoinControlEvent();
}

final class _Init extends CoinControlEvent {
  const _Init();
}

final class SelectionChanged extends CoinControlEvent {
  const SelectionChanged(this.id, {required this.value});

  final String id;
  final bool value;
}

final class SelectAllChanged extends CoinControlEvent {
  const SelectAllChanged({required this.value});

  final bool value;
}

final class NoteChanged extends CoinControlEvent {
  const NoteChanged(this.id, {required this.note});

  final String id;
  final String note;
}

final class FreezeToggled extends CoinControlEvent {
  const FreezeToggled(this.id, {required this.value});

  final String id;
  final bool value;
}

final class SelectionSaved extends CoinControlEvent {
  const SelectionSaved();
}
