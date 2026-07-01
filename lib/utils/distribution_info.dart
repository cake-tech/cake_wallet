import 'dart:io';
import 'package:cake_wallet/utils/package_info.dart';
import 'package:cw_core/utils/print_verbose.dart';

enum DistributionType { googleplay, github, appstore, fdroid }

class DistributionInfo {
  DistributionInfo._();

  static DistributionInfo get instance => DistributionInfo._();

  Future<String> getDistributionPath() async {
    final isPlayStore = await isInstalledFromPlayStore();
    final distributionPath = _getDistributionPath(isPlayStore);

    return distributionPath.name;
  }

  DistributionType _getDistributionPath(bool isPlayStore) {
    if (isPlayStore) {
      return DistributionType.googleplay;
    } else if (Platform.isAndroid) {
      return DistributionType.github;
    } else if (Platform.isIOS) {
      return DistributionType.appstore;
    } else {
      return DistributionType.github;
    }
  }

  Future<bool> isInstalledFromPlayStore() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.packageName == 'com.android.vending';
    } catch (e) {
      printV('Error: $e');
      return false;
    }
  }
}
