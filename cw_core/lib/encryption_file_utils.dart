import 'dart:io';
import 'dart:typed_data';
import 'package:cw_core/utils/file.dart' as file;
import 'package:cake_backup/backup.dart' as cwb;

EncryptionFileUtils encryptionFileUtilsFor(bool direct)
 => direct
 	? XChaCha20EncryptionFileUtils()
 	: Salsa20EncryhptionFileUtils();

abstract class EncryptionFileUtils {
	Future<void> write({required String path, required String password, required String data});
	Future<String> read({required String path, required String password});
}

class Salsa20EncryhptionFileUtils extends EncryptionFileUtils {
	// Requires legacy complex key + iv as password 
	@override
	Future<void> write({required String path, required String password, required String data}) async
		=> await file.write(path: path, password: password, data: data);

	// Requires legacy complex key + iv as password 
	@override
	Future<String> read({required String path, required String password}) async
		=> await file.read(path: path, password: password);
}

class XChaCha20EncryptionFileUtils extends EncryptionFileUtils {
	@override
	Future<void> write({required String path, required String password, required String data}) async {
		final encrypted = await cwb.encrypt(password, Uint8List.fromList(data.codeUnits));
		await File(path).writeAsBytes(encrypted);
	}
	
	@override
	Future<String> read({required String path, required String password}) async {
		final file = File(path);
		final encrypted = await file.readAsBytes();
		final bytes = await cwb.decrypt(password, encrypted);
		return String.fromCharCodes(bytes);
	}
}