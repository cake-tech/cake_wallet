import 'package:cw_core/format_fixed.dart';

abstract class PaymentURI {
  PaymentURI({required this.amount, required this.address});

  final String amount;
  final String address;
}

class MoneroURI extends PaymentURI {
  MoneroURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = 'monero:$address';

    if (amount.isNotEmpty) {
      base += '?tx_amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class HavenURI extends PaymentURI {
  HavenURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = 'haven:$address';

    if (amount.isNotEmpty) {
      base += '?tx_amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class BitcoinURI extends PaymentURI {
  BitcoinURI({required super.amount, required super.address, this.pjUri = ''});

  final String pjUri;

  @override
  String toString() {
    final qp = <String, String>{};

    if (amount.isNotEmpty) qp['amount'] = amount.replaceAll(',', '.');
    if (pjUri.isNotEmpty && !address.startsWith("sp")) {
      qp['pjos'] = '0';
      qp['pj'] = pjUri;
    }

    return Uri(scheme: 'bitcoin', path: address, queryParameters: qp).toString();
  }
}

class LitecoinURI extends PaymentURI {
  LitecoinURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = 'litecoin:$address';

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class EthereumURI extends PaymentURI {
  EthereumURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = 'ethereum:$address';

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class BitcoinCashURI extends PaymentURI {
  BitcoinCashURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = address;

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class NanoURI extends PaymentURI {
  NanoURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = 'nano:$address';
    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class PolygonURI extends PaymentURI {
  PolygonURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = 'polygon:$address';

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class SolanaURI extends PaymentURI {
  SolanaURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = 'solana:$address';

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class TronURI extends PaymentURI {
  TronURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = 'tron:$address';

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class WowneroURI extends PaymentURI {
  WowneroURI({required super.amount, required super.address});

  @override
  String toString() {
    var base = 'wownero:$address';

    if (amount.isNotEmpty) {
      base += '?tx_amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class ZanoURI extends PaymentURI {
  ZanoURI({required String amount, required String address})
      : super(amount: amount, address: address);

  @override
  String toString() {
    var base = 'zano:' + address;

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class DecredURI extends PaymentURI {
  DecredURI({required String amount, required String address})
      : super(amount: amount, address: address);

  @override
  String toString() {
    var base = 'decred:' + address;

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class DogeURI extends PaymentURI {
  DogeURI({required String amount, required String address})
      : super(amount: amount, address: address);

  @override
  String toString() {
    var base = 'doge:' + address;

    if (amount.isNotEmpty) {
      base += '?amount=${amount.replaceAll(',', '.')}';
    }

    return base;
  }
}

class ERC681URI extends PaymentURI {
  final int chainId;
  final String? contractAddress;

  ERC681URI({
    required this.chainId,
    required super.address,
    required super.amount,
    required this.contractAddress,
  });

  @override
  String toString() {
    var uri = 'ethereum:';

    final targetAddress = contractAddress ?? address;
    uri += targetAddress;

    if (chainId != 1) {
      uri += '@$chainId';
    }

    if (contractAddress != null) {
      uri += '/transfer';
    }

    final params = <String, String>{};

    if (amount.isNotEmpty) {
      if (contractAddress != null) {
        // ERC-20 token transfer: address parameter for recipient, uint256 for amount
        params['address'] = address;
        params['uint256'] = _formatAmountForERC20(amount);
      } else {
        params['value'] = _formatAmountForNative(amount);
      }
    }

    if (params.isNotEmpty) {
      uri += '?';
      uri += params.entries.map((e) => '${e.key}=${e.value}').join('&');
    }

    return uri;
  }

  /// Formats amount for ERC-20 token transfers (in atomic units)
  String _formatAmountForERC20(String amount) {
    try {
      // Convert decimal amount to BigInt (assuming 18 decimals)
      final amountDouble = double.parse(amount.replaceAll(',', '.'));
      final amountBigInt = BigInt.from(amountDouble * 1e18);
      return amountBigInt.toString();
    } catch (e) {
      // Fallback to original amount if parsing fails
      return amount.replaceAll(',', '.');
    }
  }

  /// Formats amount for native ETH payments (in wei using scientific notation)
  String _formatAmountForNative(String amount) {
    try {
      // Convert decimal amount to double for scientific notation
      final amountDouble = double.parse(amount.replaceAll(',', '.'));

      // Use scientific notation as recommended by ERC-681
      return '${amountDouble}e18';
    } catch (e) {
      // Fallback to original amount if parsing fails
      return amount.replaceAll(',', '.');
    }
  }

  factory ERC681URI.fromUri(Uri uri) {
    final (isContract, targetAddress) = _getTargetAddress(uri.path);
    final chainId = _getChainID(uri.path);

    final address = isContract ? uri.queryParameters["address"] ?? '' : targetAddress;
    final amount = isContract ? uri.queryParameters["uint256"] : uri.queryParameters["value"];

    var formatedAmount = "";

    if (amount != null) {
      formatedAmount = formatFixed(BigInt.parse(amount), 18);
    } else {
      formatedAmount = uri.queryParameters["amount"] ?? "";
    }

    return ERC681URI(
      chainId: chainId,
      address: address,
      amount: formatedAmount,
      contractAddress: isContract ? targetAddress : null,
    );
  }

  static int _getChainID(String path) {
    return int.parse(RegExp(
          r'@\d*',
        ).firstMatch(path)?.group(0)?.replaceAll("@", "") ??
        "1");
  }

  static (bool, String) _getTargetAddress(String path) {
    final targetAddress =
        RegExp(r'^(0x)?[0-9a-f]{40}', caseSensitive: false).firstMatch(path)!.group(0)!;
    return (path.contains("/"), targetAddress);
  }
}
