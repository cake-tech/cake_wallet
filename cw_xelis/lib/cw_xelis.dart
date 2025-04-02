// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'cw_xelis_platform_interface.dart';

export 'package:xelis_flutter/src/api/api.dart';
export 'package:xelis_flutter/src/api/logger.dart';
export 'package:xelis_flutter/src/api/network.dart';
export 'package:xelis_flutter/src/api/progress_report.dart';
export 'package:xelis_flutter/src/api/seed_search_engine.dart';
export 'package:xelis_flutter/src/api/table_generation.dart';
export 'package:xelis_flutter/src/api/utils.dart';
export 'package:xelis_flutter/src/api/wallet.dart';

class CwXelis {
  Future<String?> getPlatformVersion() {
    return CwXelisPlatform.instance.getPlatformVersion();
  }
}
