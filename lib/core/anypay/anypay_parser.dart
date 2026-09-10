import "package:cake_wallet/core/anypay/anypay_models.dart";
import "package:cake_wallet/core/universal_address_detector.dart";
import "package:cake_wallet/utils/payment_request.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/payment_uris.dart";

class AnyPayParser {
  static AnyPayRequest fromRaw(String input) {
    final paymentRequest = PaymentRequest.fromString(input);

    return AnyPayRequest(
      rawInput: input,
      paymentRequest: paymentRequest,
      detection: UniversalAddressDetector.detectAddress(input),
      chainBinding: _bindingFor(paymentRequest),
    );
  }

  static AnyPayRequest fromPaymentRequest(PaymentRequest request) {
    final raw = _reconstructRawInput(request);

    return AnyPayRequest(
      rawInput: raw,
      paymentRequest: request,
      detection: UniversalAddressDetector.detectAddress(raw),
      chainBinding: _bindingFor(request),
    );
  }

  static String _reconstructRawInput(PaymentRequest request) {
    final scheme = request.scheme.toLowerCase();

    if (scheme.isEmpty || scheme == "lightning") {
      return request.address;
    }

    if (scheme == "ethereum") {
      return ERC681URI(
        address: request.address,
        amount: request.amount,
        contractAddress: request.contractAddress,
        chainId: request.chainId ?? 1,
        rawTokenAmount: request.rawTokenAmount,
      ).toString();
    }

    final amount = request.amount.isNotEmpty ? "?amount=${request.amount}" : "";
    return "${request.scheme}:${request.address}$amount";
  }

  static ChainBinding _bindingFor(PaymentRequest request) {
    final scheme = request.scheme.toLowerCase();

    if (scheme == "ethereum") {
      final chainId = request.chainId;
      return chainId != null ? ExplicitEvmChain(chainId) : const ChainlessEvm();
    }

    if (scheme.isNotEmpty) {
      try {
        final chainId = getChainIdByCryptoCurrency(CryptoCurrency.fromString(scheme));
        if (chainId != null) {
          return ExplicitEvmChain(chainId);
        }
      } catch (_) {}
    }

    return const NoEvmBinding();
  }
}
