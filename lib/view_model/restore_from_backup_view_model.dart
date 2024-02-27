import 'dart:io';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/core/backup_service.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';

part 'restore_from_backup_view_model.g.dart';

class RestoreFromBackupViewModel = RestoreFromBackupViewModelBase
    with _$RestoreFromBackupViewModel;

abstract class RestoreFromBackupViewModelBase with Store {
  RestoreFromBackupViewModelBase(this.backupService)
  : state = InitialExecutionState(),
    filePath = '';

  final BackupService backupService;

  @observable
  String filePath;

  @observable
  ExecutionState state;

  @action
  void reset() => filePath = '';

  @action
  Future<void> import(String password) async {
    try {
      state = IsExecutingState();

      if (filePath.isEmpty) {
        state = FailureState('Backup file is not selected.');
        return;
      }

      final file = File(filePath);
      final data = await file.readAsBytes();

      await backupService.importBackup(data, password);
      await main();

      final store = getIt.get<AppStore>();
      ReactionDisposer? reaction;
      await store.settingsStore.reload(nodeSource: getIt.get<Box<Node>>());

      reaction = autorun((_) {
        final wallet = store.wallet;

        if (wallet != null) {
          store.authenticationStore.state = AuthenticationState.allowed;
          reaction?.reaction.dispose();
        }
      });

      state = ExecutedSuccessfullyState();
    } catch (e, s) {
      var msg = e.toString();

      if (msg.toLowerCase().contains("message authentication code (mac)")) {
        msg = 'Incorrect backup password';
      } else {
        ExceptionHandler.onError(FlutterErrorDetails(
          exception: e,
          stack: s,
          library: this.toString(),
        ));
      }

      state = FailureState(msg);
    }
  }
}
