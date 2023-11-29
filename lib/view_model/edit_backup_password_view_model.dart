import 'package:mobx/mobx.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cake_wallet/store/secret_store.dart';

part 'edit_backup_password_view_model.g.dart';

class EditBackupPasswordViewModel = EditBackupPasswordViewModelBase
    with _$EditBackupPasswordViewModel;

abstract class EditBackupPasswordViewModelBase with Store {
  EditBackupPasswordViewModelBase(this.secureStorage, this.secretStore)
  : backupPassword = secretStore.read(generateStoreKeyFor(key: SecretStoreKey.backupPassword)),
    _originalPassword = '';

  final FlutterSecureStorage secureStorage;
  final SecretStore secretStore;

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
    final password = (await secureStorage.read(key: key))!;
    _originalPassword = password;
    backupPassword = password;
  }

  @action
  Future<void> save() async {
    final key = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    await secureStorage.delete(key: key);
    await secureStorage.write(key: key, value: backupPassword);
    secretStore.write(key: key, value: backupPassword);
  }
}
