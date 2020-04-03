import 'dart:io';
import 'package:path_provider/path_provider.dart';

const reservedNames = ["flutter_assets", "wallets", "db"];

Future<void> migrate_fs() async {
  final appDocDir = await getApplicationDocumentsDirectory();

  await migrate_hives(appDocDir: appDocDir);
  await migrate_wallets(appDocDir: appDocDir);

  appDocDir.listSync(recursive: true).forEach((item) => print(item.path));
}

Future<void> migrate_hives({Directory appDocDir}) async {
  final dbDir = Directory('${appDocDir.path}/db');
  final files = List<File>();

  appDocDir.listSync().forEach((FileSystemEntity item) {
    final ext = item.path.split('.').last;

    if (item is File && (ext == "hive" || ext == "lock")) {
      files.add(item);
    }
  });

  if (!dbDir.existsSync()) {
    dbDir.createSync();
  }

  files.forEach((File hive) {
    final name = hive.path.split('/').last;
    hive.copySync('${dbDir.path}/$name');
    hive.deleteSync();
  });
}

Future<void> migrate_wallets({Directory appDocDir}) async {
  final walletsDir = Directory('${appDocDir.path}/wallets');
  final moneroWalletsDir = Directory('${walletsDir.path}/monero');
  final dirs = List<Directory>();

  appDocDir.listSync().forEach((FileSystemEntity item) {
    final name = item.path.split('/').last;

    if (item is Directory && !reservedNames.contains(name)) {
      dirs.add(item);
    }
  });

  if (!moneroWalletsDir.existsSync()) {
    await moneroWalletsDir.create(recursive: true);
  }

  dirs.forEach((Directory dir) {
    final name = dir.path.split('/').last;
    final newDir = Directory('${moneroWalletsDir.path}/$name');
    newDir.createSync();

    dir.listSync().forEach((file) {
      if (file is File) {
        final fileName = file.path.split('/').last;
        file.copySync('${newDir.path}/$fileName');
        file.deleteSync();
      }
    });

    dir.deleteSync();
  });
}
