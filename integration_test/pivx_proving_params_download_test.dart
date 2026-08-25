import 'dart:io';

import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/tor/disabled.dart';
import 'package:cw_pivx/src/sapling/sapling_constants.dart';
import 'package:cw_pivx/src/sapling/sapling_factories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'downloads and verifies PIVX Sapling proving params in app storage',
    (_) async {
      CakeTor.instance = CakeTorDisabled();

      final appDir = await getApplicationDocumentsDirectory();
      final paramsDir = Directory('${appDir.path}/pivx_sapling_params_it');
      if (await paramsDir.exists()) {
        await paramsDir.delete(recursive: true);
      }

      final progress = <double>[];
      await SaplingTransactionBuilderWrapper.downloadProvingParamsToPath(
        path: paramsDir.path,
        onProgress: progress.add,
      );

      final spendFile =
          File('${paramsDir.path}/${SaplingParams.spendParamsFileName}');
      final outputFile =
          File('${paramsDir.path}/${SaplingParams.outputParamsFileName}');

      expect(await spendFile.length(), SaplingParams.spendParamsSize);
      expect(await outputFile.length(), SaplingParams.outputParamsSize);
      expect(await File('${spendFile.path}.download').exists(), isFalse);
      expect(await File('${outputFile.path}.download').exists(), isFalse);
      expect(progress, isNotEmpty);
      expect(progress.last, 1.0);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
