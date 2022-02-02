import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/wallet_types.g.dart';

bool get isMoneroOnly {
     return availableWalletTypes.length == 1
     	    && availableWalletTypes.first == WalletType.monero;
}

String get approximatedAppName {
     return isMoneroOnly
     ? 'Monero.com'
     : 'Cake Wallet';
}