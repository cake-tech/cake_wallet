// code shamelessly stolen from xmruw
// https://raw.githubusercontent.com/MrCyjaneK/unnamed_monero_wallet/refs/heads/master-rewrite/lib/pages/debug/performance.dart
import 'dart:math';

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cake_wallet/zano/zano.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class DevMoneroCallProfilerPage extends BasePage {
  DevMoneroCallProfilerPage();

  @override
  String? get title => "[dev] xmr call profiler";

  @override
  Widget body(BuildContext context) {
    return PerformanceDebug();
  }
}



class PerformanceDebug extends StatefulWidget {
  const PerformanceDebug({super.key});

  @override
  State<PerformanceDebug> createState() => _PerformanceDebugState();
}

enum ProfilableWallet {
  monero,
  wownero,
  zano,
}

class _PerformanceDebugState extends State<PerformanceDebug> {
  List<Widget> widgets = [];

  final dashboardViewModel = getIt.get<DashboardViewModel>();

  late ProfilableWallet wallet = switch (dashboardViewModel.wallet.type) {
    WalletType.monero => ProfilableWallet.monero,
    WalletType.wownero => ProfilableWallet.wownero,
    WalletType.zano => ProfilableWallet.zano,
    _ => throw Exception("Unknown wallet type"),
  };
  final precalc = 1700298;

  late Map<String, List<int>> debugCallLength = switch (wallet) {
    ProfilableWallet.monero => monero!.debugCallLength(),
    ProfilableWallet.wownero => wownero!.debugCallLength(),
    ProfilableWallet.zano => zano!.debugCallLength(),
  };

  int getOpenWalletTime() {
    if (debugCallLength["MONERO_Wallet_init"] == null) {
      return precalc;
    }
    if (debugCallLength["MONERO_Wallet_init"]!.isEmpty) {
      return precalc;
    }
    return debugCallLength["MONERO_Wallet_init"]!.last;
  }

late final String perfInfo = """
---- Performance tuning
This page lists all calls that take place during the app runtime.-
As per Flutter docs we can read:
> Flutter aims to provide 60 frames per second (fps) performance, or 120 fps-
performance on devices capable of 120Hz updates.

With that in mind we will aim to render frames every 8.3ms (~8333 µs). It is-
however acceptable to reach 16.6 ms (~16666 µs) but we should also keep in mind-
that there are also UI costs that aren't part of this benchmark.

For some calls it is also acceptable to exceed this amount of time, for example-
MONERO_Wallet_init takes ~${getOpenWalletTime()}µs-
(${(getOpenWalletTime() / frameTime).toStringAsFixed(2)} frames). That time would-
be unnaceptable in most situations but since we call this function only when-
opening the wallet it is completely fine to freeze the UI for the time being --
as the user won't even notice that something happened.

---- Details
count: how many times did we call this function [total time (% of frame)]
average: average execution time (% of frame)
min: fastest execution (% of frame)
max: slowest execution (% of frame)
95th: 95% of the time, the function is faster than this amount of time (% of frame)
"""
    .split("-\n")
    .join(" ");

  late final frameTime = 8333;
  late final frameGreenTier = frameTime ~/ 100;
  late final frameBlueTier = frameTime ~/ 10;
  late final frameBlueGreyTier = frameTime ~/ 2;
  late final frameYellowTier = frameTime;
  late final frameOrangeTier = frameTime * 2;

  Color? perfc(num frame) {
    if (frame < frameGreenTier) return Colors.green;
    if (frame < frameBlueTier) return Colors.blue;
    if (frame < frameBlueGreyTier) return Colors.blueGrey;
    if (frame < frameGreenTier) return Colors.green;
    if (frame < frameYellowTier) return Colors.yellow;
    if (frame < frameOrangeTier) return Colors.orange;
    return Colors.red;
  }


  @override
  void initState() {
    _buildWidgets();
    super.initState();
  }

  SelectableText cw(String text, Color? color) {
    return SelectableText(
      text,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: color),
    );
  }

  void _buildWidgets() {
    List<Widget> ws = [];
    ws.add(Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(perfInfo),
        cw("<   1% of a frame (max: $frameGreenTierµs)", Colors.green),
        cw("<  10% of a frame (max: $frameBlueTierµs)", Colors.blue),
        cw("<  50% of a frame (max: $frameBlueGreyTierµs)", Colors.blueGrey),
        cw("< 100% of a frame (max: $frameYellowTierµs)", Colors.yellow),
        cw("< 200% of a frame (max: $frameOrangeTierµs)", Colors.orange),
        cw("> 200% of a frame (UI junk visible)", Colors.red),
      ],
    ));
    final keys = debugCallLength.keys.toList();
    keys.sort((s1, s2) =>
        _n95th(debugCallLength[s2]!) -
        _n95th(debugCallLength[s1]!));
    for (var key in keys) {
      final value = debugCallLength[key];
      if (value == null) continue;
      final avg = _avg(value);
      final min = _min(value);
      final max = _max(value);
      final np = _n95th(value);
      final total = _total(value);
      ws.add(
        Card(
          child: ListTile(
            title: Text(
              key,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: perfc(np)),
            ),
            subtitle: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  cw("count: ${value.length}", null),
                  const Spacer(),
                  cw("${_str(total / 1000)}ms", perfc(total)),
                ]),
                cw("average: ${_str(avg)}µs (~${_str(avg / (frameTime))}f)",
                    perfc(avg)),
                cw("min: $minµs (~${_str(min / (frameTime) * 100)})",
                    perfc(min)),
                cw("max: $maxµs (~${_str(max / (frameTime) * 100)}%)",
                    perfc(max)),
                cw("95th: $npµs (~${_str(np / (frameTime) * 100)}%)",
                    perfc(np)),
              ],
            ),
          ),
        ),
      );
    }
    if (debugCallLength.isNotEmpty) {
      ws.add(
        PrimaryButton(
          text: "Purge statistics",
          onPressed: _purgeStats,
          color: Colors.red,
          textColor: Colors.white,
        ),
      );
    }
    setState(() {
      widgets = ws;
    });
  }

  void _purgeStats() {
    debugCallLength.clear();
    _buildWidgets();
  }

  int _min(List<int> l) {
    return l.reduce(min);
  }

  int _max(List<int> l) {
    return l.reduce(max);
  }

  int _n95th(List<int> l) {
    final l0 = l.toList();
    l0.sort();
    int i = (0.95 * l.length).ceil() - 1;
    return l0[i];
  }

  double _avg(List<int> l) {
    int c = 0;
    for (var i = 0; i < l.length; i++) {
      c += l[i];
    }
    return c / l.length;
  }

  int _total(List<int> l) {
    int c = 0;
    for (var i = 0; i < l.length; i++) {
      c += l[i];
    }
    return c;
  }

  String _str(num d) => d.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: widgets,
        ),
      ),
    );
  }
}
