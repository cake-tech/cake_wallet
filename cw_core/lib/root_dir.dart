import 'dart:io';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

String? _rootDirPath;

const String _tailsData = '/live/persistence/TailsData_unlocked/TailsData/Persistent';

bool get isNonAmnesticTails {
  try {
    final os = File("/etc/os-release").readAsLinesSync();
    for (var line in os) {
      if (!line.startsWith("ID=")) continue;
      if (!line.contains("tails")) continue;
      return Directory(_tailsData).existsSync();
    }
  } catch (e) {
    return false;
  }
  return false;
}

bool showNotice = true;

void setRootDirFromEnv() =>
    _rootDirPath = Platform.environment['CAKE_WALLET_DIR'];

void copyDirectory(Directory source, Directory destination) {
  source.listSync(recursive: false).forEach((var entity) {
    if (entity is Directory) {    
      var newDirectory = Directory(p.join(destination.absolute.path, p.basename(entity.path)));
      newDirectory.createSync(recursive: true);
      copyDirectory(entity.absolute, newDirectory);
    } else if (entity is File) {
      destination.createSync(recursive: true);
      entity.copySync(p.join(destination.path, p.basename(entity.path)));
    }
  });
}

Future<void> linuxSymlinkSharedPreferences() async {
  if (!Platform.isLinux) return; // nuh-uh
  final dataHome = Platform.environment["XDG_DATA_HOME"] ?? p.join(Platform.environment["HOME"] ?? "", ".local", "share");
  final oldPath = p.join(dataHome, "com.example.cake_wallet");
  final newPath = p.join((await getAppDir()).path, "_local_share");
  final oldDir = Directory(oldPath);
  final oldLink = Link(oldPath);
  final newDir = Directory(newPath);
  if (oldDir.existsSync()) {
    if (oldLink.existsSync()) {
      printV("not creating, link exists");
    } else {
      if (newDir.existsSync()) { 
        newDir.renameSync("${newPath}_${DateTime.now().millisecondsSinceEpoch~/1000}");
      }
      copyDirectory(oldDir, newDir);
      oldDir.deleteSync(recursive: true);
    }
  }
  if (!oldLink.existsSync()) {
    oldLink.create(newPath, recursive: true);
  }
  if (!newDir.existsSync()) {
    newDir.createSync(recursive: true);
  }
}

Future<Directory> getAppDir({String appName = 'cake_wallet'}) async {
  Directory dir;

  if (_rootDirPath != null && _rootDirPath!.isNotEmpty) {
    dir = Directory.fromUri(Uri.file(_rootDirPath!));
    dir.create(recursive: true);
  } else {
    if (Platform.isWindows) {
      dir = await getApplicationSupportDirectory();
    } else if (Platform.isLinux) {
      String? appDirPath;
      try {
        dir = await getApplicationDocumentsDirectory();
        appDirPath = '${dir.path}/$appName';
      } catch (e) {
        appDirPath = null;
      }
      // App will try to use last entry in here, so {distro,package}-specific paths can be
      // be put as one of last items (tails - I'm looking at you), and other paths can be
      // added in the order of preference
      // Which currently is $HOME/.config/$appName - as this is the most standard directory
      // for storing things that users in general back-up
      var linuxAppPath = [
        if (appDirPath != null) appDirPath, // old preferred
        p.join('/home', Platform.environment['USER']??"null", appName), // old fallback
        if (Platform.environment['HOME'] != null) p.join(Platform.environment['HOME']!, ".$appName"), // old fallback but using HOME
        if (Platform.environment['HOME'] != null) p.join(Platform.environment['HOME']!, '.config', appName), // old fallback but using HOME
        if (isNonAmnesticTails) p.join(_tailsData, ".$appName") // tails (if persistance is enabled)
      ];

      String preferredPath = linuxAppPath.last;
      
      preferredLoop:
      for (String notSoPreferredPath in linuxAppPath) {
        if (notSoPreferredPath == linuxAppPath.last) continue;
        bool useThisOne = Directory(notSoPreferredPath).existsSync();
        if (useThisOne) {
          if (showNotice) {
            showNotice = false;
            printV("Not using $preferredPath because $notSoPreferredPath exists, falling back for backwards compatibility");
            printV("Can't see your wallet? Check\n - ${linuxAppPath.join("\n - ")}\n and move directory that to $preferredPath");
            printV("Or use CAKE_WALLET_DIR=/path/to/app/ ${Platform.executable}");
          }
          preferredPath = notSoPreferredPath;
          break preferredLoop;
        }
      }

      dir = Directory.fromUri(Uri.file(preferredPath));
      await dir.create(recursive: true);
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
  }

  return dir;
}
