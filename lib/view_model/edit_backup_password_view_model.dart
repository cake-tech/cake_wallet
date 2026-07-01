import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/default_settings_migration.dart' show generateBackupPassword;
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';

part 'edit_backup_password_view_model.g.dart';

class EditBackupPasswordViewModel = EditBackupPasswordViewModelBase
    with _$EditBackupPasswordViewModel;

abstract class EditBackupPasswordViewModelBase with Store {
  EditBackupPasswordViewModelBase(this.secureStorage,)
  : backupPassword = "",
    _originalPassword = ''{init();}

  final SecureStorage secureStorage;

  @observable
  String backupPassword;

  @computed
  bool get canSave {
    return !(_originalPassword == backupPassword);
  }

  String _originalPassword;

  @action
  Future<void> init() async {
    final key = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    final password = (await secureStorage.read(key: key)) ?? '';
    if (backupPassword.isEmpty) {
      generateBackupPassword(secureStorage);
    }
    _originalPassword = password;
    backupPassword = password;
  }

  @action
  Future<void> save() async {
    final key = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    await secureStorage.write(key: key, value: backupPassword);
  }
}
