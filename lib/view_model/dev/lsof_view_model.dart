import 'dart:convert';
import 'dart:io';

import 'package:cw_core/root_dir.dart';
import 'package:flutter_daemon/flutter_daemon.dart';
import 'package:mobx/mobx.dart';

part 'lsof_view_model.g.dart';
class LsofViewModel = LsofViewModelBase with _$LsofViewModel;

abstract class LsofViewModelBase with Store {
  @observable
  String? logs = null;

  @action
  Future<void> refresh() async {
    final dir = await getAppDir();
    final list = await dir.list(recursive: true);
    final fList = await list.map((element) => element.path).toList();

    var lsofProcess = await Process.start(
      "/system/bin/lsof", fList,
      // ["walletinfo.hive", "walletinfo.lock"],
      workingDirectory: (await getAppDir()).path,
      runInShell: true,
    );

    logs = '''exitcode: ${await lsofProcess.exitCode}
  stderr: ${await lsofProcess.stderr.transform(utf8.decoder).join()}
  stdout: ${await lsofProcess.stdout.transform(utf8.decoder).join()}
''';
  }

} 