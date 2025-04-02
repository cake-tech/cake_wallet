import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/wallet_connect/walletkit_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class DeepLinkHandler {
  static const _methodChannel = MethodChannel(
    'com.walletconnect.flutterwallet/methods',
  );
  static const _eventChannel = EventChannel(
    'com.walletconnect.flutterwallet/events',
  );
  static final waiting = ValueNotifier<bool>(false);

  static void initListener() {
    if (kIsWeb) return;
    _eventChannel.receiveBroadcastStream().listen(
          _onLink,
          onError: _onError,
        );
  }

  static void checkInitialLink() async {
    if (kIsWeb) return;
    try {
      final initialLink = await _methodChannel.invokeMethod('initialLink');
      if (initialLink != null) {
        _onLink(initialLink);
      }
    } catch (e) {
      debugPrint('[DeepLinkHandler] checkInitialLink $e');
    }
  }

  static IReownWalletKit get _walletKit => getIt.get<WalletKitService>().walletKit;
  static Uri get nativeUri => Uri.parse(_walletKit.metadata.redirect?.native ?? '');
  static Uri get universalUri => Uri.parse(_walletKit.metadata.redirect?.universal ?? '');
  static String get host => universalUri.host;

  static void _onLink(dynamic link) async {
    debugPrint('_onLink $link');
    try {
      return await _walletKit.dispatchEnvelope('$link');
    } catch (e) {
      final decodedUri = Uri.parse(Uri.decodeFull('$link'));
      if (decodedUri.isScheme('wc')) {
        debugPrint('Its legacy uri $decodedUri');
        waiting.value = true;
        await _walletKit.pair(uri: decodedUri);
      } else {
        final uriParam = ReownCoreUtils.getSearchParamFromURL(
          decodedUri.toString(),
          'uri',
        );
        if (decodedUri.isScheme(nativeUri.scheme) && uriParam.isNotEmpty) {
          debugPrint('Its custom uri $decodedUri');
          waiting.value = true;
          final pairingUri = decodedUri.query.replaceFirst('uri=', '');
          await _walletKit.pair(uri: Uri.parse(pairingUri));
        }
      }
    }
  }

  static void _onError(Object error) {
    waiting.value = false;
    debugPrint('[DeepLinkHandler] _onError $error');
  }
}
