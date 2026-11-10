import 'package:cw_core/utils/file.dart' as file;

EncryptionFileUtils encryptionFileUtilsFor(bool isDirect) =>
    XChaCha20MigratingEncryptionFileUtils(isDirect: isDirect);

abstract class EncryptionFileUtils {
  Future<void> write({required String path, required String password, required String data});
  Future<String> read({required String path, required String password});
}

class XChaCha20MigratingEncryptionFileUtils extends EncryptionFileUtils {
  XChaCha20MigratingEncryptionFileUtils({required this.isDirect});

  final bool isDirect;

  @override
  Future<void> write({required String path, required String password, required String data}) {
    return file.write(
      path: path,
      password: password,
      data: data,
      highEntropyPassphrase: !isDirect,
    );
  }

  @override
  Future<String> read({required String path, required String password}) {
    return file.read(
      path: path,
      password: password,
      highEntropyPassphrase: !isDirect,
    );
  }
}
