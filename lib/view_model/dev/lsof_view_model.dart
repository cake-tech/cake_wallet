import 'dart:convert';
import 'dart:io' hide stderr, stdout;

import 'package:cw_core/root_dir.dart';
import 'package:mobx/mobx.dart';

part 'lsof_view_model.g.dart';
class LsofViewModel = LsofViewModelBase with _$LsofViewModel;

abstract class LsofViewModelBase with Store {
  @observable
  String? logs = null;

  static Future<String> fetchLsof() async {
    String? toret;
    try {
      final dir = await getAppDir();
      final list = await dir.list(recursive: true);
      final fList = await list.map((element) => element.path).toList();

      var lsofProcess = await Process.start(
        "lsof", fList,
        workingDirectory: (await getAppDir()).path,
        runInShell: false,
      );

      var stderr = (await lsofProcess.stderr.transform(utf8.decoder).join()).trim();
      var stdout = (await lsofProcess.stdout.transform(utf8.decoder).join()).trim();
      if (stdout.isEmpty || true) {
        final suCheck = await Process.run("su", ["--help"], stderrEncoding: utf8, stdoutEncoding: utf8);
        stderr = suCheck.stderr.toString(); //(await suCheck.stderr.transform(utf8.decoder).join()).trim();
        stdout = suCheck.stdout.toString(); //(await suCheck.stdout.transform(utf8.decoder).join()).trim();
        if (!stdout.contains('MagiskSU')) {
          toret = """Unsupported (or none) su binary.
  expected: MagiskSU
  -- found
  stderr:
  ${stderr}
  stdout:
  ${stdout}
  ec: ${await suCheck.exitCode}
  """;
        }
        // Retry as root, lsof doesn't work reliably on release builds for some reason?
        // magisk su command behaves weirdly - so special characters need to be escaped
        final list = await dir.list(recursive: true);
        final fList = await list.map((element) => element.path.replaceAll(" ", r"\ ")).toList();
        final lsofProcess2 = await Process.start(
          "su", ['-c', 'lsof' , ...fList],
          workingDirectory: (await getAppDir()).path,
          runInShell: false,
        );

        stderr = (await lsofProcess2.stderr.transform(utf8.decoder).join()).trim();
        stdout = (await lsofProcess2.stdout.transform(utf8.decoder).join()).trim();
      }
      toret = '''stderr:
${stderr}
stdout:
${stdout}
''';
    } catch (e) {
      toret = e.toString();
      return toret;
    }
    return toret;
  }

  @action
  Future<void> refresh() async {
    logs = await fetchLsof();
  }
} 