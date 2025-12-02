import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:cake_wallet/core/backup_service.dart';
import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_backup/backup.dart' as cake_backup;
import 'package:cake_wallet/utils/package_info.dart';
import 'package:crypto/crypto.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';

enum BackupVersion {
  unknown, // index 0
  v1,
  v2,
  v3,
}

class ChunkChecksum {
  ChunkChecksum({
    required this.encrypted,
    required this.plain,
  });

  final String encrypted;
  final String plain;

  factory ChunkChecksum.fromJson(Map<String, dynamic> json) {
    return ChunkChecksum(
      encrypted: json['encrypted'] as String,
      plain: json['plain'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'encrypted': encrypted,
      'plain': plain,
    };
  }

  @override
  String toString() {
    return 'ChunkChecksum(encrypted: $encrypted, plain: $plain)';
  }
}

class ChunkLength {
  ChunkLength({
    required this.encrypted,
    required this.plain,
  });

  final int encrypted;
  final int plain;

  factory ChunkLength.fromJson(Map<String, dynamic> json) {
    return ChunkLength(
      encrypted: json['encrypted'] as int,
      plain: json['plain'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'encrypted': encrypted,
      'plain': plain,
    };
  }
  @override
  String toString() {
    return 'ChunkLength(encrypted: $encrypted, plain: $plain)';
  }
}

class ChunkDetails {
  ChunkDetails({
    required this.sha512sum,
    required this.length,
  });

  final ChunkChecksum sha512sum;
  final ChunkLength length;

  factory ChunkDetails.fromJson(Map<String, dynamic> json) {
    return ChunkDetails(
      sha512sum: ChunkChecksum.fromJson(json['sha512sum'] as Map<String, dynamic>),
      length: ChunkLength.fromJson(json['length'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sha512sum': sha512sum,
      'length': length,
    };
  }

  @override
  String toString() {
    return 'ChunkDetails(sha512sum: $sha512sum, length: $length)';
  }
}

class BackupMetadata {
  BackupMetadata({
    required this.version,
    required this.sha512sum,
    required this.chunks,
    required this.cakeVersion,
  });

  final BackupVersion version;
  String sha512sum;
  final List<ChunkDetails> chunks;
  String cakeVersion;
  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      version: BackupVersion.values[json['version'] as int],
      sha512sum: json['sha512sum'] as String,
      chunks: (json['chunks'] as List<dynamic>).map((chunk) => ChunkDetails.fromJson(chunk as Map<String, dynamic>)).toList(),
      cakeVersion: json['cakeVersion'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version.index,
      'sha512sum': sha512sum,
      'chunks': chunks.map((chunk) => chunk.toJson()).toList(),
      'cakeVersion': cakeVersion,
    };
  }

  @override
  String toString() {
    return 'BackupMetadata(version: $version, sha512sum: $sha512sum, chunks: $chunks)';
  }
}

class BackupServiceV3 extends $BackupService {
  BackupServiceV3(super.secureStorage, super.transactionDescriptionBox, super.keyService, super.sharedPreferences);

  static BackupVersion get currentVersion => BackupVersion.v3;

  Future<File> exportBackupFile(String password, {String nonce = secrets.backupSalt}) {
    return exportBackupFileV3(password, nonce: nonce);
  }

  BackupVersion getVersionFile(File data) {
    final raf = data.openSync(mode: FileMode.read);
    
    try {
      // Read first 4 bytes to check both version and zip signature
      final buffer = Uint8List(1);
      final bytesRead = raf.readIntoSync(buffer);
      
      if (bytesRead == 0) {
        throw Exception('Invalid backup file: empty file');
      }

      // Check if first byte is version 1 or 2
      if (buffer[0] == 1) {
        return BackupVersion.v1;
      } else if (buffer[0] == 2) {
        return BackupVersion.v2;
      } else if (buffer[0] == 0x50) {
        // $ head -c 64 test-archive.zip | hexdump -C
        // 00000000  50 4b 03 04 ....
        // Here we just check if the first byte is the zip signature
        // Inside of v3 backup we have multiple files.
        // Check metadata.json for version in v3 backup
        final inputStream = InputFileStream(data.path);
        final archive = ZipDecoder().decodeStream(inputStream);
        final metadataFile = archive.findFile('metadata.json');
        if (metadataFile == null) {
          return BackupVersion.unknown;
        }
        final metadataBytes = metadataFile.rawContent!.readBytes();
        final metadataString = utf8.decode(metadataBytes);
        final metadataJsonRaw = json.decode(metadataString) as Map<String, dynamic>;
        final metadata = BackupMetadata.fromJson(metadataJsonRaw);
        if (metadata.version == BackupVersion.v3) {
          return BackupVersion.v3;
        }
      }

      return BackupVersion.unknown;
    } finally {
      raf.closeSync();
    }
  }

  Future<void> importBackupFile(File file, String password, {String nonce = secrets.backupSalt}) {
    final version = getVersionFile(file);
    switch (version) {
      case BackupVersion.unknown:
        throw Exception('unknown_backup_version');
      case BackupVersion.v1:
        final data = file.readAsBytesSync();
        final backupBytes = data.toList()..removeAt(0);
        final backupData = Uint8List.fromList(backupBytes);
        return super.importBackupV1(backupData, password, nonce: nonce);
      case BackupVersion.v2:
        return super.importBackupV2(file.readAsBytesSync(), password);
      case BackupVersion.v3:
        return importBackupFileV3(file, password, nonce: nonce);
    }
  }

  Future<void> importBackupFileV3(File file, String password, {String nonce = secrets.backupSalt}) async{
    // Overall design of v3 backup is the following:
    // 1. backup.zip - plaintext zip file that user can open with any archive manager
    // 2. backup.zip/README.txt - text file to let user know what is inside of this file
    // 3. backup.zip/metadata.json - json file with metadata about backup.
    // 4. backup.zip/data.bin - v2 backup file

    final inputStream = InputFileStream(file.path);
    final archive = ZipDecoder().decodeStream(inputStream);
    final metadataFile = archive.findFile('metadata.json');
    if (metadataFile == null) {
      throw Exception('Invalid v3 backup: missing metadata.json');
    }
    final metadataBytes = metadataFile.rawContent!.readBytes();
    final metadataString = utf8.decode(metadataBytes);
    final metadataJsonRaw = json.decode(metadataString) as Map<String, dynamic>;
    final metadata = BackupMetadata.fromJson(metadataJsonRaw);

    final dataFile = archive.findFile('data.bin');
    if (dataFile == null) {
      throw Exception('Invalid v3 backup: missing data.bin');
    }
    final dataStream = dataFile.rawContent!.getStream();
    
    final decryptedData = File('${file.path}_decrypted'); // decrypted zip file
    if (decryptedData.existsSync()) {
      decryptedData.deleteSync();
    }
    decryptedData.createSync(recursive: true);
    decryptedData.writeAsBytesSync(Uint8List(0), mode: FileMode.write, flush: true);
    
    int chunkIndex = 0;
    for (var chunk in metadata.chunks) {
      chunkIndex++;
      final chunkBytes = dataStream.readBytes(chunk.length.encrypted).toUint8List();
      final chunkChecksum = (await sha512.bind(Stream.fromIterable([chunkBytes])).first).toString();

      // readBytes stores position internally, so we don't need to think about it.
      if (chunk.sha512sum.encrypted != chunkChecksum) {
        throw Exception('Invalid v3 backup: chunk (${chunk.length.encrypted} bytes) checksum mismatch at index $chunkIndex\n'
            'expected: ${chunk.sha512sum.encrypted}\n'
            'got: $chunkChecksum');
      }
      final decryptedChunk = await cake_backup.decrypt(password, chunkBytes);
      decryptedData.writeAsBytesSync(decryptedChunk, mode: FileMode.append, flush: true);
    }


    final sha512sum = (await sha512.bind(decryptedData.openRead()).first).toString();
    if (sha512sum.toString() != metadata.sha512sum) {
      throw Exception('Invalid v3 backup: SHA512 checksum mismatch\n'
          'expected: ${metadata.sha512sum}\n'
          'got: $sha512sum');
    }

    // Decryption done, now we can import the backup (that is, unzip app data)

    // archive is **NOT** backup, it is just a zip file that contains data.bin inside.
    // We need to unzip it to get the backup.
    // data.bin after decryption is available in decryptedData.

    final zip = ZipDecoder();
    final decryptedDataStream = InputFileStream(decryptedData.path);
    final backupArchive = zip.decodeStream(decryptedDataStream);


    final appDir = await getAppDir();

    outer:
    for (var file in backupArchive.files) {
      final filename = file.name;
      for (var ignore in $BackupService.ignoreFiles) {
        if (filename.endsWith(ignore) && !filename.contains("wallets/")) {
          printV("ignoring backup file: $filename");
          continue outer;
        }
      }
      printV("restoring: $filename");
      if (file.isFile) {
        final output = File('${appDir.path}/' + filename)
          ..createSync(recursive: true);
        final outputStream = OutputFileStream(output.path);
        file.writeContent(outputStream);
        outputStream.flush();
      } else {
        final dir = Directory('${appDir.path}/' + filename);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
      }
    };

    // Continue importing the backup the old way
    await super.verifyWallets();
    await verifyHardwareWallets(password);
    await super.importKeychainDumpV2(password);
    await super.importPreferencesDump();
    await super.importTransactionDescriptionDump();

    // Delete decrypted data file
    decryptedData.deleteSync();
  }

  Future<void> verifyHardwareWallets(String password,
      {String keychainSalt = secrets.backupKeychainSalt}) async {
    final appDir = await getAppDir();
    final keychainDumpFile = File('${appDir.path}/~_keychain_dump');
    final decryptedKeychainDumpFileData = await decryptV2(
        keychainDumpFile.readAsBytesSync(), '$keychainSalt$password');
    final keychainJSON = json.decode(utf8.decode(decryptedKeychainDumpFileData))
        as Map<String, dynamic>;
    final keychainWalletsInfo = keychainJSON['wallets'] as List;

    final expectedHardwareWallets = keychainWalletsInfo
        .where((e) =>
            (e as Map<String, dynamic>).containsKey("hardwareWalletType") &&
            e["hardwareWalletType"] != null)
        .toList();

    for (final expectedHardwareWallet in expectedHardwareWallets) {
      final info = expectedHardwareWallet as Map<String, dynamic>;
      final actualWalletInfo = await WalletInfo.get(info['name'] as String, WalletType.values.firstWhere((e) => e.toString() == info['type'] as String));
      if (actualWalletInfo != null &&
          info["hardwareWalletType"] !=
              actualWalletInfo.hardwareWalletType?.index) {
        actualWalletInfo.hardwareWalletType =
            HardwareWalletType.values[info["hardwareWalletType"] as int];
        await actualWalletInfo.save();
      }
    }
  }

  Future<File> exportBackupFileV3(String password, {String nonce = secrets.backupSalt}) async {
    final metadata = BackupMetadata(
      version: BackupVersion.v3,
      sha512sum: 'tbd',
      chunks: [],
      cakeVersion: 'tbd',
    );
    final zipEncoder = ZipFileEncoder();
    final appDir = await getAppDir();
    final now = DateTime.now().toIso8601String().replaceAll(':', '-');
    final tmpDir = Directory('${appDir.path}/~_BACKUP_TMP');
    final archivePath = '${tmpDir.path}/backup_${now}.tmp.zip';
    final archivePathExport = '${tmpDir.path}/backup_${now}.zip';
    final fileEntities = appDir.listSync(recursive: false);
    final keychainDump = await super.exportKeychainDumpV2(password);
    final preferencesDump = await super.exportPreferencesJSON();
    final preferencesDumpFile = File('${tmpDir.path}/~_preferences_dump_TMP');
    final keychainDumpFile = File('${tmpDir.path}/~_keychain_dump_TMP');
    final transactionDescriptionDumpFile =
        File('${tmpDir.path}/~_transaction_descriptions_dump_TMP');

    final transactionDescriptionData = super.transactionDescriptionBox
        .toMap()
        .map((key, value) => MapEntry(key.toString(), value.toJson()));
    final transactionDescriptionDump = jsonEncode(transactionDescriptionData);

    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }

    tmpDir.createSync();
    zipEncoder.create(archivePath);
    outer:
    for (var entity in fileEntities) {
      if (entity.path == archivePath || entity.path == tmpDir.path) {
        continue;
      }
      for (var ignore in $BackupService.ignoreFiles) {
        final filename = entity.absolute.path;
        if (filename.endsWith(ignore) && !filename.contains("wallets/")) {
          printV("ignoring backup file: $filename");
          continue outer;
        }
      }

      if (entity.statSync().type == FileSystemEntityType.directory) {
        await zipEncoder.addDirectory(Directory(entity.path));
      } else {
        await zipEncoder.addFile(File(entity.path));
      }
    }
    await keychainDumpFile.writeAsBytes(keychainDump.toList());
    await preferencesDumpFile.writeAsString(preferencesDump);
    await transactionDescriptionDumpFile.writeAsString(transactionDescriptionDump);
    await zipEncoder.addFile(preferencesDumpFile, '~_preferences_dump');
    await zipEncoder.addFile(keychainDumpFile, '~_keychain_dump');
    await zipEncoder.addFile(transactionDescriptionDumpFile, '~_transaction_descriptions_dump');
    await zipEncoder.close();

    final dataBinUnencrypted = File(archivePath);

    final dataBin = File('${tmpDir.path}/data.bin');
    dataBin.writeAsBytesSync(Uint8List(0), mode: FileMode.write, flush: true);
    final dataBinWriter = dataBin.openWrite();

    printV("------ Backup stats ------");
    printV("Backup version: ${metadata.version}");
    printV("Backup size: ${await dataBinUnencrypted.length()}");
    printV("Backup chunks: ${(await dataBinUnencrypted.length()) / chunkSize}");
    printV("------ Backup stats ------");

    int chunkIndex = 0;
    final stopwatch = Stopwatch()..start();
    printV("Starting backup encryption...");
    
    metadata.sha512sum = (await sha512.bind(dataBinUnencrypted.openRead()).first).toString();

    final raf = await dataBinUnencrypted.open();
    

    while (true) {
      printV("Reading chunk ${chunkIndex++}");
      
      stopwatch.reset();
      final chunk = await raf.read(chunkSize);
      printV("Chunk read completed in ${stopwatch.elapsed}");
      printV("Chunk length: ${chunk.length} expected: $chunkSize");
      if (chunk.length == 0) {
        break;
      }
      
      stopwatch.reset();
      final encryptedChunk = await cake_backup.encrypt(password, chunk);
      printV("Encryption completed in ${stopwatch.elapsed}");

      stopwatch.reset();
      final sha512sumEncryptedChunk = await sha512.bind(Stream.fromIterable([encryptedChunk])).first;
      final sha512sumUnencryptedChunk = await sha512.bind(Stream.fromIterable([chunk])).first;
      printV("Hashing completed in ${stopwatch.elapsed}");

      stopwatch.reset();
      dataBinWriter.add(encryptedChunk);
      metadata.chunks.add(ChunkDetails(
        sha512sum: ChunkChecksum(
          encrypted: sha512sumEncryptedChunk.toString(),
          plain: sha512sumUnencryptedChunk.toString(),
        ),
        length: ChunkLength(
          encrypted: encryptedChunk.length,
          plain: chunk.length,
        ),
      ));
      
      await dataBinWriter.flush();
      printV("Writing completed in ${stopwatch.elapsed}");
    }
    await raf.close();

    // Give the file to the user

    final metadataFile = File('${tmpDir.path}/metadata.json');
    final packageInfo = await PackageInfo.fromPlatform();
    metadata.cakeVersion = packageInfo.version;

    metadataFile.writeAsStringSync(JsonEncoder.withIndent('    ').convert(metadata.toJson()));
    final readmeFile = File('${tmpDir.path}/README.txt');
    readmeFile.writeAsStringSync('''This is a ${packageInfo.appName} backup. Do not modify this archive.

App version: ${packageInfo.version}

If you have any issues with this backup, please contact our in-app support.
This backup was created on ${DateTime.now().toIso8601String()}
''');
    final zip = ZipFileEncoder();
    zip.create(archivePathExport, level: 9);
    await zip.addFile(dataBin, 'data.bin');
    await zip.addFile(metadataFile, 'metadata.json');
    await zip.addFile(readmeFile, 'README.txt');
    await zip.close();
    // tmpDir.deleteSync(recursive: true);
    final file = File(archivePathExport);
    return file;
  }

  static const chunkSize = 24 * 1024 * 1024; // 24MiB

  File setVersionFile(File file, BackupVersion version) {
    if (version == BackupVersion.v3) return file; // v3 uses
    // helper function to call super.setVersion();
    final data = file.readAsBytesSync();
    super.setVersion(data, version.index);
    file.writeAsBytesSync(data);
    return file;
  }
}
