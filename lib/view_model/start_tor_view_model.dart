import 'dart:async';

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/reactions/bootstrap.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/tor.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'start_tor_view_model.g.dart';

class StartTorViewModel = StartTorViewModelBase with _$StartTorViewModel;

abstract class StartTorViewModelBase with Store {
  StartTorViewModelBase() {
    _startTimer();
  }

  Timer? _timer;
  final int waitTimeInSeconds = 5;

  @observable
  bool isLoading = true;

  @observable
  bool timeoutReached = false;

  @observable
  late int remainingSeconds = waitTimeInSeconds;

  @computed
  bool get showOptions => timeoutReached;

  @action
  void _startTimer() {
    remainingSeconds = waitTimeInSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingSeconds -= 1;
      
      if (remainingSeconds <= 0) {
        timer.cancel();
        timeoutReached = true;
      }
    });
  }

  @observable
  bool didStartTor = false;

  @action
  Future<void> startTor(BuildContext context) async {
    if (didStartTor) {
      return;
    }
    await ensureTorStarted(context: null);
    while (true) {
      await Future.delayed(Duration(milliseconds: 250));
      if (CakeTor.instance.port != -1 && CakeTor.instance.started) {
        break;
      }
    }
    didStartTor = true;
    final appStore = getIt.get<AppStore>();
    bootstrapOnline(navigatorKey, loadWallet: true);
    appStore.wallet?.connectToNode(node: appStore.settingsStore.getCurrentNode(appStore.wallet!.type));
    Navigator.pushReplacementNamed(context, Routes.login);
  }

  @action
  void disableTor(BuildContext context) {
    final settingsStore = getIt.get<SettingsStore>();
    settingsStore.currentBuiltinTor = false;
    bootstrapOnline(navigatorKey, loadWallet: true);
    final appStore = getIt.get<AppStore>();
    appStore.wallet?.connectToNode(node: appStore.settingsStore.getCurrentNode(appStore.wallet!.type));
    Navigator.pushReplacementNamed(context, Routes.login);
  }

  @action
  void ignoreAndLaunchApp(BuildContext context) {
    bootstrapOnline(navigatorKey, loadWallet: true);
    final appStore = getIt.get<AppStore>();
    appStore.wallet?.connectToNode(node: appStore.settingsStore.getCurrentNode(appStore.wallet!.type));
    Navigator.pushReplacementNamed(context, Routes.login);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
} 