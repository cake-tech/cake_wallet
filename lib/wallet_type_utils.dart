import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/wallet_types.g.dart';

bool get isMoneroOnly {
    return availableWalletTypes.length == 1
     	&& availableWalletTypes.first == WalletType.monero;
}

bool get isHaven {
    return availableWalletTypes.length == 1
        && availableWalletTypes.first == WalletType.haven;
}

bool get isWownero {
    return availableWalletTypes.length == 1
        && availableWalletTypes.first == WalletType.wownero;
}

bool get isSingleCoin {
     return availableWalletTypes.length == 1;
}

String get approximatedAppName {
    if (isMoneroOnly) {
        return 'Monero.com';   
    }

    if (isHaven) {
        return 'Haven';
    }

    if (isWownero) {
        return 'Wownero';
    }

    return 'Cake Wallet';
}