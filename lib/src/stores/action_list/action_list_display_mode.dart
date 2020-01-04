enum ActionListDisplayMode { transactions, trades }

int serializeActionlistDisplayModes(List<ActionListDisplayMode> modes) {
  var i = 0;

  for (final mode in modes) {
    switch (mode) {
      case ActionListDisplayMode.trades:
        i += 1;
        break;
      case ActionListDisplayMode.transactions:
        i += 10;
        break;
    }
  }

  return i;
}

List<ActionListDisplayMode> deserializeActionlistDisplayModes(int raw) {
  List<ActionListDisplayMode> modes = [];

  if (raw == 1 || raw - 10 == 1) {
    modes.add(ActionListDisplayMode.trades);
  }

  if (raw >= 10) {
    modes.add(ActionListDisplayMode.transactions);
  }

  return modes;
}
