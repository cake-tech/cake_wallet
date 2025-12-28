import 'dart:io';
import 'package:cake_wallet/core/backup_service_v3.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cw_core/db/sqlite.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/di.dart';
import 'package:cw_core/node.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';

part 'restore_from_backup_view_model.g.dart';

class RestoreFromBackupViewModel = RestoreFromBackupViewModelBase with _$RestoreFromBackupViewModel;

abstract class RestoreFromBackupViewModelBase with Store {
  RestoreFromBackupViewModelBase(this.backupService)
      : state = InitialExecutionState(),
        filePath = '';

  final BackupServiceV3 backupService;

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

      try {
        await backupService.importBackupFile(file, password);
      } catch (e, s) {
        if (e.toString().contains("unknown_backup_version")) {
          state = FailureState('This is not a valid backup file, please make sure you have selected the correct one');
        } else {
          state = FailureState(e.toString() + "\n" + s.toString());
        }
      }

      try {
        await initializeAppAtRoot(reInitializing: true);
      } catch (e, s) {
        state = FailureState('Failed app initialization, please try again');
        ExceptionHandler.onError(FlutterErrorDetails(exception: e, stack: s, silent: true));
      }

      final store = getIt.get<AppStore>();
      ReactionDisposer? reaction;
      await store.settingsStore.reload(nodeSource: getIt.get<Box<Node>>());
      await reloadDb();
      await store.themeStore.loadSavedTheme(isFromBackup: true);
      reaction = autorun((_) {
        final wallet = store.wallet;

        if (wallet != null) {
          store.authenticationStore.state = AuthenticationState.allowed;
          reaction?.reaction.dispose();
        }
      });

      state = ExecutedSuccessfullyState();
    } catch (e, s) {
      var msg = e.toString().toLowerCase();

      // can't use a switch here because of .contains() / not an exact match
      bool shouldBeMadeAware = false;
      if (msg.contains("message authentication code (mac)")) {
        msg = 'Incorrect backup password';
      } else if (msg.contains("faileddecryption")) {
        msg = 'Failed to decrypt backup file, please check you entered the right password';
      } else if (msg.contains("failed_to_decode")) {
        msg = 'Failed to decode backup file, please try again';
        shouldBeMadeAware = true;
      } else if (msg.contains("failed_app_initialization")) {
        msg = 'Failed to initialize app, please try again';
        shouldBeMadeAware = true;
      } else {
        shouldBeMadeAware = true;
      }

      if (shouldBeMadeAware) {
        await ExceptionHandler.onError(FlutterErrorDetails(
          exception: e,
          stack: s,
          library: this.toString(),
        ));
      }

      state = FailureState(msg);
    }
  }
}
