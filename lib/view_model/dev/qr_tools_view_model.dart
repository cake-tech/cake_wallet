import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ur/cbor_lite.dart';
import 'package:ur/ur.dart';
import 'package:mobx/mobx.dart';
import 'package:ur/ur_decoder.dart';

part 'qr_tools_view_model.g.dart';

class QRToolsViewModel = QRToolsViewModelBase with _$QRToolsViewModel;

enum DevQrType {
  zpub,
  xpub,
  bbqr,
  bcur,
  unknown,
}

abstract class QRToolsViewModelBase with Store {
  @observable
  String input = '';



  @computed
  Map<String, dynamic> get data => _getResult(input);

  Uint8List _decodeCBOR(Uint8List cbor) {
    final cborDecoder = CBORDecoder(cbor);
    final out = cborDecoder.decodeBytes();
    return out.$1;
  }


  Map<String, dynamic> _getResult(String input) {
    try {
      final decoder = URDecoder();
      for (var part in input.split('\n')) {
        part = part.toLowerCase();
        part = part.trim();
        if (part.startsWith('-')) {
          part = part.substring(1).trim();
        }
        if (!part.startsWith('ur:')) {
          continue;
        }
        decoder.receivePart(part);
      }
      return {
        "result": (decoder.result != null) ? switch (decoder.result.runtimeType) {
          UR => {
            "cbor": (decoder.result as UR).cbor,
            "_cbor.decode.base64": base64.encode(_decodeCBOR((decoder.result as UR).cbor)),
            "type": (decoder.result as UR).type,
            "toString": (decoder.result as UR).toString(),
          },
          _ => "unknown type: ${decoder.result.runtimeType}"
        } : null,
        "expectedType": decoder.expectedType,
        "estimatedPercentComplete": decoder.estimatedPercentComplete(),
        "processedPartsCount": decoder.processedPartsCount(),
        "expectedPartCount": decoder.expectedPartCount(),
        "isComplete": decoder.isComplete(),
        "isFailure": decoder.isFailure(),
        "isSuccess": decoder.isSuccess(),
        "lastPartIndexes": decoder.lastPartIndexes(),
        "receivedPartIndexes": decoder.receivedPartIndexes(),
        "resultError": decoder.resultError(),
        "resultMessage": decoder.resultMessage(),
        "toString": decoder.toString(),

      };
    } catch (e) {
      return {
        "error": e.toString(),
      };
    }
  }
}