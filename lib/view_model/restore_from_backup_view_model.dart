import 'dart:io';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/core/backup_service.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';

part 'restore_from_backup_view_model.g.dart';

class RestoreFromBackupViewModel = RestoreFromBackupViewModelBase
    with _$RestoreFromBackupViewModel;

abstract class RestoreFromBackupViewModelBase with Store {
  RestoreFromBackupViewModelBase(this.backupService);

  @observable
  String filePath;

  final BackupService backupService;

  @action
  void reset() => filePath = '';

  Future<void> import(String password) async {
    try {
      if (filePath?.isEmpty ?? true) {
        // FIXME: throw exception;
        return;
      }

      final file = File(filePath);
      final data = await file.readAsBytes();

      await backupService.importBackup(data, password);
      await main();

      final store = getIt.get<AppStore>();
      ReactionDisposer reaction;
      await store.settingsStore.reload(nodeSource: getIt.get<Box<Node>>());

      reaction = autorun((_) {
        final wallet = store.wallet;

        if (wallet != null) {
          store.authenticationStore.state = AuthenticationState.allowed;
          reaction?.reaction?.dispose();
        }
      });
    } catch (e) {
      print(e.toString());
    }
  }
}
