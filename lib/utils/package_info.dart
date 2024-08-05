import 'dart:io';
import 'package:package_info/package_info.dart' as __package_info__;

abstract class _EnvKeys {
    static const kWinAppName = 'CW_WIN_APP_NAME';
    static const kWinAppPackageName = 'CW_WIN_APP_PACKAGE_NAME';
    static const kWinAppVersion = 'CW_WIN_APP_VERSION';
    static const kWinAppBuildNumber = 'CW_WIN_APP_BUILD_NUMBER';
}

class PackageInfo {
    static Future<PackageInfo> fromPlatform() async {
        if (Platform.isWindows) {
            return _windowsPackageInfo;
        }

        final packageInfo = await __package_info__.PackageInfo.fromPlatform();
        return PackageInfo._(
            appName: packageInfo.appName,
            packageName: packageInfo.packageName,
            version: packageInfo.version,
            buildNumber: packageInfo.buildNumber);
    }

    static const _defaultCWAppName = 'Cake Wallet';
    static const _defaultCWAppPackageName = 'com.cakewallet.cake_wallet';
    static const _defaultCWAppVersion = '1.0.0';
    static const _defaultCWAppBuildNumber = '1';

    static const _windowsPackageInfo = PackageInfo._(
        appName: const String
            .fromEnvironment(_EnvKeys.kWinAppName,
                defaultValue: _defaultCWAppName),
        packageName: const String
            .fromEnvironment(_EnvKeys.kWinAppPackageName,
                defaultValue: _defaultCWAppPackageName),
        version: const String
            .fromEnvironment(_EnvKeys.kWinAppVersion,
                defaultValue: _defaultCWAppVersion),
        buildNumber: const String
            .fromEnvironment(_EnvKeys.kWinAppBuildNumber,
                defaultValue: _defaultCWAppBuildNumber));

    final String appName;
    final String packageName;
    final String version;
    final String buildNumber;

    const PackageInfo._({
        required this.appName,
        required this.packageName,
        required this.version,
        required this.buildNumber});
}
