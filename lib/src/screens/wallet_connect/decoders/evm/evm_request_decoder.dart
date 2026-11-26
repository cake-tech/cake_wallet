import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/dex_router_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc1155_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc20_token_resolver.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/erc721_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/permit2_decoder.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";

class EvmRequestDecoder {
  EvmRequestDecoder(AppStore? appStore, {FiatConversionStore? fiatConversionStore})
    : this._(Erc20TokenResolver(appStore, fiatConversionStore: fiatConversionStore));

  EvmRequestDecoder._(this.tokenResolver)
    : _erc20 = Erc20Decoder(tokenResolver),
      _router = DexRouterDecoder(tokenResolver),
      _permit2 = Permit2Decoder(tokenResolver);

  final Erc20TokenResolver tokenResolver;
  final Erc20Decoder _erc20;
  final DexRouterDecoder _router;
  final Permit2Decoder _permit2;

  static const _erc721 = Erc721Decoder();
  static const _erc1155 = Erc1155Decoder();

  static const _maxStepsWithLookups = 12;
  late final _withoutLookups = EvmRequestDecoder(null);

  static const _multicallSelectors = {
    EvmSelectors.multicall,
    EvmSelectors.multicallWithDeadline,
    EvmSelectors.multicallWithPreviousBlockhash,
  };

  Future<WCDecodedRequest> decodeTransaction({
    required String? rawData,
    required String? toAddress,
    required String? fromAddress,
    required String nativeSymbol,
    required BigInt valueWei,
    required int? chainId,
  }) async {
    final calldata = EvmCalldata.parse(rawData);
    if (calldata == null) {
      return _decodeNativeTransfer(toAddress, nativeSymbol, valueWei);
    }

    final known = await _decodeKnownCall(
      calldata,
      toAddress,
      fromAddress,
      nativeSymbol,
      valueWei,
      chainId,
    );
    if (known != null) {
      return known;
    }

    final multicall = await _decodeMulticall(
      calldata,
      toAddress,
      fromAddress,
      nativeSymbol,
      valueWei,
      chainId,
    );
    if (multicall != null) {
      return multicall;
    }

    return _unknownCall(calldata, toAddress, nativeSymbol, valueWei);
  }

  Future<WCDecodedRequest?> _decodeKnownCall(
    EvmCalldata calldata,
    String? toAddress,
    String? fromAddress,
    String nativeSymbol,
    BigInt valueWei,
    int? chainId,
  ) async {
    if (toAddress == null) {
      return null;
    }

    final routerResult = await _router.decode(
      calldata: calldata,
      nativeSymbol: nativeSymbol,
      routerAddress: toAddress,
      walletAddress: fromAddress,
      valueWei: valueWei,
      chainId: chainId,
    );
    final paysContract = valueWei > BigInt.zero && calldata.selector != EvmSelectors.wethDeposit;
    if (routerResult != null || paysContract) {
      return routerResult;
    }

    final erc20Result = await _erc20.decode(
      calldata: calldata,
      contractAddress: toAddress,
      nativeSymbol: nativeSymbol,
      chainId: chainId,
    );
    if (erc20Result != null) {
      return erc20Result;
    }

    final erc721Result = _erc721.decode(calldata: calldata, contractAddress: toAddress);
    if (erc721Result != null) {
      return erc721Result;
    }

    final erc1155Result = _erc1155.decode(calldata: calldata, contractAddress: toAddress);
    if (erc1155Result != null) {
      return erc1155Result;
    }

    return _permit2.decode(calldata: calldata, contractAddress: toAddress, chainId: chainId);
  }

  Future<WCDecodedRequest?> _decodeMulticall(
    EvmCalldata calldata,
    String? toAddress,
    String? fromAddress,
    String nativeSymbol,
    BigInt valueWei,
    int? chainId,
  ) async {
    if (!_multicallSelectors.contains(calldata.selector)) {
      return null;
    }

    final hasPrefixWord = calldata.selector != EvmSelectors.multicall;
    final inners = calldata.bytesArrayAt(hasPrefixWord ? 1 : 0);
    if (inners == null || inners.isEmpty) {
      return null;
    }

    final calls = inners.map(EvmCalldata.parse).toList();
    final routerCalls = calls.nonNulls.toList();
    final onlyCall = calls.length == 1 ? calls.single : null;
    WCDecodedRequest? decoded = onlyCall == null
        ? null
        : await _decodeKnownCall(onlyCall, toAddress, fromAddress, nativeSymbol, valueWei, chainId);
    if (routerCalls.length == calls.length) {
      decoded ??= await _router.decodeMulticall(
        calls: routerCalls,
        nativeSymbol: nativeSymbol,
        routerAddress: toAddress,
        walletAddress: fromAddress,
        valueWei: valueWei,
        chainId: chainId,
      );
    }
    decoded ??= await _listMulticallSteps(
      calldata,
      calls,
      contractAddress: toAddress,
      walletAddress: fromAddress,
      nativeSymbol: nativeSymbol,
      valueWei: valueWei,
      chainId: chainId,
    );

    final deadline = calldata.selector == EvmSelectors.multicallWithDeadline
        ? calldata.uintAt(0)
        : null;
    if (deadline == null) {
      return decoded;
    }
    return decoded.copyWith(
      rows: [
        ...decoded.rows,
        WCDecodedRow(label: S.current.wc_deadline, value: tokenResolver.formatExpiry(deadline)),
      ],
    );
  }

  Future<WCDecodedRequest> _listMulticallSteps(
    EvmCalldata calldata,
    List<EvmCalldata?> calls, {
    required String? contractAddress,
    required String? walletAddress,
    required String nativeSymbol,
    required BigInt valueWei,
    required int? chainId,
  }) async {
    final steps = await Future.wait([
      for (final (index, call) in calls.indexed)
        (index < _maxStepsWithLookups ? this : _withoutLookups)._decodeStep(
          call,
          contractAddress: contractAddress,
          walletAddress: walletAddress,
          nativeSymbol: nativeSymbol,
          chainId: chainId,
        ),
    ]);

    final unknown = _unknownCall(calldata, contractAddress, nativeSymbol, valueWei);
    final rows = [...unknown.rows];
    final stepWarnings = <String>{};
    var decodedCount = 0;
    for (var index = 0; index < calls.length; index++) {
      final call = calls[index];
      final step = steps[index];
      final unreadName = call == null
          ? S.current.wc_decode_failed
          : EvmSelectors.humanNameFor(call.selector);
      rows.add(
        WCDecodedRow(
          label: S.current.wc_step_n((index + 1).toString()),
          value: step?.actionTitle ?? unreadName,
        ),
      );
      if (step != null) {
        rows.addAll(step.rows);
        stepWarnings.addAll(step.warnings);
        decodedCount++;
      }
    }

    final isListed =
        contractAddress != null &&
        DexRouter.values.any(
          (router) => EvmSelectors.isKnownRouter(router, chainId, contractAddress),
        );
    return unknown.copyWith(
      rows: rows,
      warnings: {
        if (decodedCount > 1) S.current.wc_warning_swap_extra_transfers,
        if (decodedCount < calls.length) S.current.wc_warning_decode_failed,
        if (!isListed) S.current.wc_warning_unknown_contract,
        ...stepWarnings,
      }.toList(),
    );
  }

  Future<WCDecodedRequest?> _decodeStep(
    EvmCalldata? call, {
    required String? contractAddress,
    required String? walletAddress,
    required String nativeSymbol,
    required int? chainId,
  }) async {
    if (call == null) {
      return null;
    }
    final known = await _decodeKnownCall(
      call,
      contractAddress,
      walletAddress,
      nativeSymbol,
      BigInt.zero,
      chainId,
    );
    if (known != null) {
      return known;
    }

    final payment = await _router.decodeMulticall(
      calls: [call],
      nativeSymbol: nativeSymbol,
      routerAddress: contractAddress,
      walletAddress: walletAddress,
      valueWei: BigInt.zero,
      chainId: chainId,
    );
    return payment?.copyWith(actionTitle: EvmSelectors.humanNameFor(call.selector));
  }

  WCDecodedRequest _decodeNativeTransfer(String? toAddress, String nativeSymbol, BigInt valueWei) {
    final amountStr = tokenResolver.formatNativeAmount(valueWei);
    return WCDecodedRequest(
      actionTitle: S.current.wc_action_send,
      rows: [
        WCDecodedRow(
          label: S.current.wc_amount,
          value: "$amountStr $nativeSymbol",
          kind: WCDecodedRowKind.amount,
        ),
        if (toAddress != null)
          WCDecodedRow(label: S.current.to, value: toAddress, kind: WCDecodedRowKind.address),
      ],
      isValueShown: true,
    );
  }

  WCDecodedRequest _unknownCall(
    EvmCalldata calldata,
    String? toAddress,
    String nativeSymbol,
    BigInt valueWei,
  ) {
    final humanName = EvmSelectors.humanNameFor(calldata.selector);
    final amountStr = tokenResolver.formatNativeAmount(valueWei);

    return WCDecodedRequest(
      actionTitle: S.current.wc_contract_call,
      actionSubtitle: humanName,
      rows: [
        if (toAddress != null)
          WCDecodedRow(
            label: S.current.wc_contract,
            value: toAddress,
            kind: WCDecodedRowKind.address,
          ),
        if (valueWei > BigInt.zero)
          WCDecodedRow(
            label: S.current.wc_value,
            value: "$amountStr $nativeSymbol",
            kind: WCDecodedRowKind.amount,
          ),
      ],
      warnings: [S.current.wc_warning_unknown_contract],
      isValueShown: true,
    );
  }
}
