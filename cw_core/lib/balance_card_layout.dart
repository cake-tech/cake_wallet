import "package:cw_core/balance_card_style_settings.dart";

class BalanceCardLayout {
  BalanceCardLayout._(
    this._settings, {
    required List<int> visible,
    required List<int> hidden,
    required this.needsRepair,
  })  : visible = List<int>.unmodifiable(visible),
        hidden = List<int>.unmodifiable(hidden);

  factory BalanceCardLayout.resolve({
    required List<int> accountIndices,
    required List<BalanceCardStyleSettings> settings,
  }) {
    final List<int> accounts = [];
    for (final accountIndex in accountIndices) {
      if (!accounts.contains(accountIndex)) {
        accounts.add(accountIndex);
      }
    }

    final settingsByAccount = <int, BalanceCardStyleSettings>{};
    for (final setting in settings) {
      if (accounts.contains(setting.accountIndex)) {
        settingsByAccount.putIfAbsent(setting.accountIndex, () => setting);
      }
    }

    final hidden = [
      for (final accountIndex in accounts)
        if (settingsByAccount[accountIndex]?.hidden ?? false) accountIndex,
    ]..sort();

    final visible = [
            for (final accountIndex in accounts)
              if (!hidden.contains(accountIndex)) accountIndex,
          ];

    visible.sort((a, b) => _compareStackPosition(a, b, settingsByAccount));

    var needsRepair = false;
    for (var position = 0; position < visible.length; position++) {
      final stored = settingsByAccount[visible[position]];
      if (stored != null && stored.cardOrder != position) {
        needsRepair = true;
      }
    }

    return BalanceCardLayout._(
      settingsByAccount,
      visible: visible,
      hidden: hidden,
      needsRepair: needsRepair,
    );
  }

  final Map<int, BalanceCardStyleSettings> _settings;

  final List<int> visible;
  final List<int> hidden;

  // flag when db order is broken
  final bool needsRepair;

  List<int> get designOrder => designOrderOf(visible);

  static List<int> stackFromOrder(Map<int, int> cardOrder, {bool forceSingleCard = false}) {
    final positions = cardOrder.keys.toList()..sort();
    final accountIndices = [for (final position in positions) cardOrder[position]!];

    if (accountIndices.isEmpty || !forceSingleCard) {
      return accountIndices;
    }
    return [accountIndices.first];
  }

  static List<int> designOrderOf(Iterable<int> accountIndices) =>
      List<int>.of(accountIndices)..sort();

  Map<int, int> get orders =>
      {for (var position = 0; position < visible.length; position++) visible[position]: position};

  BalanceCardStyleSettings? settingFor(int accountIndex) => _settings[accountIndex];

  BalanceCardLayout unhiding(int accountIndex) {
    if (!hidden.contains(accountIndex)) {
      return this;
    }

    return BalanceCardLayout._(
      _settings,
      visible: [...visible, accountIndex],
      hidden: [
        for (final hiddenAccount in hidden)
          if (hiddenAccount != accountIndex) hiddenAccount,
      ],
      needsRepair: true,
    );
  }

  static int _compareStackPosition(
    int a,
    int b,
    Map<int, BalanceCardStyleSettings> settingsByAccount,
  ) {
    final orderA = _storedOrder(settingsByAccount[a]);
    final orderB = _storedOrder(settingsByAccount[b]);

    if (orderA != orderB) {
      if (orderA == null) {
        return 1;
      }
      if (orderB == null) {
        return -1;
      }
      return orderA.compareTo(orderB);
    }

    return a.compareTo(b);
  }

  static int? _storedOrder(BalanceCardStyleSettings? setting) =>
      setting == null || setting.cardOrder < 0 ? null : setting.cardOrder;
}
