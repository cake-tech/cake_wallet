import 'dart:convert';
import 'dart:io';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/psbt_extractor_v0.dart';
import 'package:cw_bitcoin/psbt_signer.dart';
import 'package:cw_bitcoin/psbt_v0_deserialize.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ledger_bitcoin/psbt.dart';
import 'package:payjoin_flutter/bitcoin_ffi.dart' as script;
import 'package:payjoin_flutter/common.dart';
import 'package:payjoin_flutter/receive.dart';
import 'package:payjoin_flutter/send.dart' as send;
import 'package:payjoin_flutter/uri.dart' as pj_uri;
import 'package:payjoin_flutter/uri.dart' as pjuri;

export 'package:payjoin_flutter/receive.dart'
    show Receiver, UncheckedProposal, PayjoinProposal;
export 'package:payjoin_flutter/send.dart' show Sender;
export 'package:payjoin_flutter/src/exceptions.dart' show PayjoinException;
export 'package:payjoin_flutter/uri.dart' show Uri;

class BitcoinPayjoin {
  // Private constructor
  BitcoinPayjoin._internal();

  // Singleton instance
  static final BitcoinPayjoin _instance = BitcoinPayjoin._internal();

  // Factory constructor to return the singleton instance
  factory BitcoinPayjoin() {
    return _instance;
  }

  static const pjUrl = "https://payjo.in";
  static const relayUrl = "https://pj.bobspacebkk.com";
  static const v2ContentType = "message/ohttp-req";

  Network get testnet => Network.testnet;

  Network get mainnet => Network.bitcoin;

/*
+-------------------------+
| Receiver starts from here |
+-------------------------+
*/

  Future<Map<String, dynamic>> buildV2PjStr({
    int? amount,
    required String address,
    required Network network,
    required BigInt expireAfter,
  }) async {
    debugPrint(
        '[+] BITCOINPAYJOIN => buildV2PjStr - address: $address \n amount: $amount \n network: $network');

    final _payjoinDirectory = await pjuri.Url.fromStr(pjUrl);
    final _ohttpRelay = await pjuri.Url.fromStr(relayUrl);

    final _ohttpKeys = await pjuri.fetchOhttpKeys(
      ohttpRelay: _ohttpRelay,
      payjoinDirectory: _payjoinDirectory,
    );

    debugPrint(
        '[+] BITCOINPAYJOIN => buildV2PjStr - OHTTP KEYS FETCHED ${_ohttpKeys.toString()}');

    final receiver = await Receiver.create(
      address: address,
      network: network,
      directory: _payjoinDirectory,
      ohttpKeys: _ohttpKeys,
      ohttpRelay: _ohttpRelay,
      expireAfter: expireAfter, // 5 minutes
    );

    String pjUriStr;

    final pjUriBuilder = receiver.pjUriBuilder();

    if (amount != null) {
      // ignore
      final pjUriBuilderWithAmount =
          pjUriBuilder.amountSats(amount: BigInt.from(amount));
      final pjUri = pjUriBuilderWithAmount.build();
      pjUriStr = pjUri.asString();
    } else {
      final pjUri = pjUriBuilder.build();
      pjUriStr = pjUri.asString();
    }

    return {'pjUri': pjUriStr, 'session': receiver};
  }

  Future<UncheckedProposal> handleReceiverSession(Receiver session) async {
    debugPrint("BITCOINPAYJOIN => pollV2Request");
    try {
      final httpClient = HttpClient();
      UncheckedProposal? proposal;

      while (proposal == null) {
        final extractReq = await session.extractReq();
        final request = extractReq.$1;
        final clientResponse = extractReq.$2;

        final url = Uri.parse(request.url.asString());
        final httpRequest = await httpClient.postUrl(url);
        httpRequest.headers.set('Content-Type', request.contentType);
        httpRequest.add(request.body);

        final response = await httpRequest.close();
        final responseBody = await response.fold<List<int>>(
            [], (previous, element) => previous..addAll(element));
        final uint8Response = Uint8List.fromList(responseBody);
        proposal =
            await session.processRes(body: uint8Response, ctx: clientResponse);
      }

      return proposal;
    } catch (e, st) {
      debugPrint(
          '[!] BITCOINPAYJOINERROR => buildV2PjStr - Error: ${e.toString()}, Stacktrace: $st');
      rethrow;
    }
  }

  Future<String> extractOriginalTransaction(UncheckedProposal proposal) async {
    final originalTxBytes = await proposal.extractTxToScheduleBroadcast();
    final originalTx = getTxIdFromTxBytes(originalTxBytes);
    return originalTx;
  }

  Future<PayjoinProposal> processProposal({
    required UncheckedProposal proposal,
    required Object receiverWallet,
  }) async {
    final bitcoinWallet = receiverWallet as ElectrumWallet;

    final maybeInputsOwned = await proposal.assumeInteractiveReceiver();

    final maybeInputsSeen = await maybeInputsOwned.checkInputsNotOwned(
        isOwned: (outpoint) async =>
            false // TODO Implement actual ownership check
        );

    final outputsUnknown = await maybeInputsSeen.checkNoInputsSeenBefore(
        isKnown: (outpoint) async => false // TODO Implement actual seen check
        );

    final wantsOutputs = await outputsUnknown.identifyReceiverOutputs(
        isReceiverOutput: (script) async {
          return receiverWallet.isMine(Script.fromRaw(byteData: script));
    });

    var wantsInputs = await wantsOutputs.commitOutputs();

    // final unspent = receiverWallet.listUnspent();
    final unspent = bitcoinWallet.unspentCoins.where((e) => (e.isSending || !e.isFrozen));

    List<InputPair> candidateInputs = [];
    List<UtxoWithPrivateKey> utxos = [];

    for (BitcoinUnspent input in unspent) {
      final address = RegexUtils.addressTypeFromStr(input.address, BitcoinNetwork.mainnet);

      final txout = TxOut(
        value: BigInt.from(input.value),
        scriptPubkey: Uint8List.fromList(address.toScriptPubKey().toBytes()),
      );

      final psbtin = PsbtInput(
          witnessUtxo: txout, redeemScript: null, witnessScript: null);

      final previousOutput = OutPoint(txid: input.hash, vout: input.vout);

      final txin = TxIn(
        previousOutput: previousOutput,
        scriptSig: await script.Script.newInstance(rawOutputScript: []),
        witness: [],
        sequence: 0,
      );

      final ip = await InputPair.newInstance(txin, psbtin);

      final hd = input.bitcoinAddressRecord.isHidden
          ? bitcoinWallet.sideHd
          : bitcoinWallet.hd;

      ECPrivate privkey;
      if (input.bitcoinAddressRecord is BitcoinSilentPaymentAddressRecord) {
        final unspentAddress = input.bitcoinAddressRecord as BitcoinSilentPaymentAddressRecord;
        privkey = bitcoinWallet.walletAddresses.silentAddress!.b_spend.tweakAdd(
          BigintUtils.fromBytes(
            BytesUtils.fromHexString(unspentAddress.silentPaymentTweak!),
          ),
        );
      } else {
        privkey =
            generateECPrivate(hd: hd, index: input.bitcoinAddressRecord.index, network: BitcoinNetwork.mainnet);
      }

      utxos.add(
        UtxoWithPrivateKey(
          utxo: BitcoinUtxo(
            txHash: input.hash,
            value: BigInt.from(input.value),
            vout: input.vout,
            scriptType: input.bitcoinAddressRecord.type,
            isSilentPayment: input.bitcoinAddressRecord is BitcoinSilentPaymentAddressRecord,
          ),
          ownerDetails: UtxoAddressDetails(
            publicKey: hd.publicKey.toHex(),
            address: address,
          ),
          privateKey: privkey
        ),
      );
      candidateInputs.add(ip);
    }

    final inputPair = await wantsInputs.tryPreservingPrivacy(
        candidateInputs: candidateInputs);

    wantsInputs =
        await wantsInputs.contributeInputs(replacementInputs: [inputPair]);

    final provisionalProposal = await wantsInputs.commitInputs();

    final finalProposal = await provisionalProposal.finalizeProposal(
        processPsbt: (i) => _processPsbt(i, receiverWallet, utxos),
        maxFeeRateSatPerVb: BigInt.from(25));

    return finalProposal;
  }

  Future<String> sendFinalProposal(PayjoinProposal finalProposal) async {
    final req = await finalProposal.extractV2Req();
    final proposalReq = req.$1;
    final proposalCtx = req.$2;

    final httpClient = HttpClient();
    final httpRequest = await httpClient.postUrl(
      Uri.parse(proposalReq.url.asString()),
    );
    httpRequest.headers.set('content-type', 'message/ohttp-req');
    httpRequest.add(proposalReq.body);

    final response = await httpRequest.close();
    final responseBody = await response.fold<List<int>>(
      [],
      (previous, element) => previous..addAll(element),
    );
    await finalProposal.processRes(
        res: responseBody, ohttpContext: proposalCtx);

    final ps = await finalProposal.psbt();
    printV(ps);

    return "";
  }

  String getTxIdFromTxBytes(Uint8List txBytes) {
    return BtcTransaction.fromRaw(BytesUtils.toHexString(txBytes)).txId();
  }

  Future<String> _processPsbt(String preProcessed, ElectrumWallet wallet,
      List<UtxoWithPrivateKey> utxos) async {
    final signedPsbt = await (wallet as BitcoinWallet).signPsbt(preProcessed, utxos);
    printV(signedPsbt);
    return signedPsbt;
  }

  Future<String> getTxIdFromPsbt(String psbtBase64) async {
    final psbt = PsbtV2()..deserializeV0(base64.decode(psbtBase64))..finalize();
    final doubleSha256 = QuickCrypto.sha256DoubleHash(psbt.extractFromV0());
    final revert = Uint8List.fromList(doubleSha256);
    return hex.encode(revert.reversed.toList());
  }

/*
+-------------------------+
| Sender starts from here |
+-------------------------+
*/

  Future<pj_uri.Uri?> stringToPjUri(String pj) async {
    try {
      return await pjuri.Uri.fromStr(pj);
    } catch (e, st) {
      debugPrint(
          '[!] BITCOINPAYJOINERROR => stringToPjUri - Error: ${e.toString()}, Stacktrace: $st');
      return null;
    }
  }

  Future<send.Sender> buildPayjoinRequest(
    Object wallet,
    int fee,
    double amount,
    Object credentials,
  ) async {
    final _credentials = credentials as BitcoinTransactionCredentials;
    final bitcoinWallet = wallet as BitcoinWallet;

    final psbtv2 = await bitcoinWallet.createPayjoinTransaction(_credentials);
    debugPrint(
        '[+] BITCOINPAYJOIN => buildOriginalPsbt - psbtv2: ${base64Encode(psbtv2.serialize())}');

    final psbtv0 = base64Encode(psbtv2.asPsbtV0());
    debugPrint('[+] BITCOINPAYJOIN => buildOriginalPsbt - psbtv0: $psbtv0');

    final uri = await pjuri.Uri.fromStr(_credentials.payjoinUri!);
    final senderBuilder = await send.SenderBuilder.fromPsbtAndUri(
      psbtBase64: psbtv0,
      pjUri: uri.checkPjSupported(),
    );

    final sender = await senderBuilder.buildRecommended(
      minFeeRate: BigInt.from(250),
    );

    return sender;
  }

  Future<String> requestAndPollV2Proposal(
    send.Sender sender,
  ) async {
    debugPrint(
        '[+] BITCOINPAYJOIN => requestAndPollV2Proposal -  Sending V2 Proposal Request...');

    try {
      final extractV2 = await sender.extractV2(
        ohttpProxyUrl: await pj_uri.Url.fromStr(relayUrl),
      );
      final request = extractV2.$1;
      final postCtx = extractV2.$2;

      final response = await http.post(
        Uri.parse(request.url.asString()),
        headers: {
          'Content-Type': v2ContentType,
        },
        body: request.body,
      );

      final getCtx =
          await postCtx.processResponse(response: response.bodyBytes);

      while (true) {
        debugPrint(
            '[+] BITCOINPAYJOIN => requestAndPollV2Proposal -  Polling V2 Proposal Request...');

        try {
          final extractReq = await getCtx.extractReq(
            ohttpRelay: await pj_uri.Url.fromStr(relayUrl),
          );
          final getReq = extractReq.$1;
          final ohttpCtx = extractReq.$2;

          final loopResponse = await http.post(
            Uri.parse(getReq.url.asString()),
            headers: {
              'Content-Type': v2ContentType,
            },
            body: getReq.body,
          );

          final proposal = await getCtx.processResponse(
              response: loopResponse.bodyBytes, ohttpCtx: ohttpCtx);

          if (proposal != null) {
            debugPrint(
                '[+] BITCOINPAYJOIN => requestAndPollV2Proposal - Received V2 proposal: $proposal');
            return proposal;
          }

          debugPrint(
              '[+] BITCOINPAYJOIN => requestAndPollV2Proposal - No valid proposal received, retrying after 2 seconds...');

          await Future.delayed(const Duration(seconds: 2));
        } catch (e, st) {
          // If the session times out or another error occurs, rethrow the error
          debugPrint(
              '[!] BITCOINPAYJOINERROR => stringToPjUri - Error: ${e.toString()}, Stacktrace: $st');
          rethrow;
        }
      }
    } catch (e, st) {
      // If the initial request fails, rethrow the error
      debugPrint(
          '[!] BITCOINPAYJOINERROR => stringToPjUri - Error: ${e.toString()}, Stacktrace: $st');
      rethrow;
    }
  }

  Future<PendingBitcoinTransaction> extractPjTx(
    Object wallet,
    String psbtString,
    Object credentials,
      dynamic pjUri
  ) async {
    final bitcoinWallet = wallet as BitcoinWallet;

    final pendingTx =
        await bitcoinWallet.psbtToPendingTx(psbtString, credentials, pjUri);

    return pendingTx;
  }
}
