import 'package:flutter/services.dart';

const utils = const MethodChannel('com.cake_wallet/native_utils');

void setIsAppSecureNative(bool isAppSecure) {
    utils.invokeMethod<Uint8List>('setIsAppSecure',  {'isAppSecure': isAppSecure});
}