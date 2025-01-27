import 'dart:convert';

import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/psbt_finalizer_v0.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ledger_bitcoin/psbt.dart';
import 'package:payjoin_flutter/send.dart' as send;
import 'package:payjoin_flutter/uri.dart' as pj_uri;

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

  static const relayUrl = "https://pj.bobspacebkk.com";
  static const v2ContentType = "message/ohttp-req";

/*
+-------------------------+
| Sender starts from here |
+-------------------------+
*/

  Future<String> buildOriginalPsbt(
      Object wallet,
      int fee,
      double amount,
      Object credentials,
      ) async {
    final bitcoinWallet = wallet as BitcoinWallet;

    final psbtv2 = await bitcoinWallet.createPayjoinTransaction(
      credentials as BitcoinTransactionCredentials
    );

    psbtv2.finalizeV0();

    final psbtv0 = base64Encode(psbtv2.asPsbtV0());
    debugPrint('[+] BITCOINPAYJOIN => buildOriginalPsbt - psbtv0: $psbtv0');

    return psbtv0;
  }

  Future<send.Sender> buildPayjoinRequest(
      String originalPsbt,
      String pjUri,
      int fee,
      ) async {
    final uri = await pj_uri.Uri.fromStr(pjUri);

    final senderBuilder = await send.SenderBuilder.fromPsbtAndUri(
      psbtBase64: originalPsbt,
      pjUri: uri.checkPjSupported(),
    );

    return senderBuilder.buildRecommended(minFeeRate: BigInt.from(250));
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

  Future<PendingBitcoinTransaction> extractPjTx(Object wallet, String psbtString) async =>
      (wallet as BitcoinWallet).psbtToPendingTx(psbtString);
}
