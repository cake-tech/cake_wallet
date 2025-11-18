import 'dart:async';
import 'dart:io';

import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import 'package:flutter/material.dart';

bool didTorStart = false;
Future<void> ensureTorStopped({required BuildContext? context}) async {
  if (!didTorStart || CakeTor.instance is CakeTorDisabled) {
    printV("Tor hasn't been initialized yet, so it can't be stopped.");
    return;
  }
  BuildContext? dialogContext;
  if (context != null) dialogContext = await showFullscreenDialog(context);
  didTorStart = false;
  printV("Stopping tor");
  await CakeTor.instance!.stop();
  printV("Tor stopped");
  if (context != null) dismissFullscreenDialog(dialogContext!);
}

Future<void> ensureTorStarted({required BuildContext? context}) async {
  if (didTorStart) {
    printV("Tor has already started");
    return;
  }
  BuildContext? dialogContext;
  if (context != null) dialogContext = await showFullscreenDialog(context);
  didTorStart = true;
  printV("Starting tor");
  // var rootToken = RootIsolateToken.instance!;
  // await Isolate.run(() async {
  //   BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
  //   await CakeTor.instance!.start();
  // });
  // second start is fast but populates the values on current thread
  await CakeTor.instance!.start();
  printV("Tor started");
  while (!CakeTor.instance!.started) {
    printV("Waiting for tor to start (part 1)");
    await Future.delayed(const Duration(seconds: 1));
  }
  while (CakeTor.instance!.port == -1) {
    printV("Waiting for tor to start (listening on port)");
    await Future.delayed(const Duration(seconds: 1));
  }
  printV("Tor started on port ${CakeTor.instance!.port}");
  if (context != null) dismissFullscreenDialog(dialogContext!);
}

Future<BuildContext> showFullscreenDialog(BuildContext context) async {
  BuildContext? dialogContext;
  unawaited(
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return PopScope(
        canPop: false,
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
            ),
          ),
        );
      },
    ),
  );
  await Future.delayed(const Duration(seconds: 1));
  return dialogContext!;
}

Future<void> dismissFullscreenDialog(BuildContext context) async {
  await Future.delayed(const Duration(seconds: 1));
  Navigator.of(context).pop();
}