// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'output.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$Output on OutputBase, Store {
  Computed<bool>? _$isParsedAddressComputed;

  @override
  bool get isParsedAddress =>
      (_$isParsedAddressComputed ??= Computed<bool>(() => super.isParsedAddress,
              name: 'OutputBase.isParsedAddress'))
          .value;
  Computed<int>? _$formattedCryptoAmountComputed;

  @override
  int get formattedCryptoAmount => (_$formattedCryptoAmountComputed ??=
          Computed<int>(() => super.formattedCryptoAmount,
              name: 'OutputBase.formattedCryptoAmount'))
      .value;
  Computed<double>? _$estimatedFeeComputed;

  @override
  double get estimatedFee =>
      (_$estimatedFeeComputed ??= Computed<double>(() => super.estimatedFee,
              name: 'OutputBase.estimatedFee'))
          .value;
  // Computed<String> _$estimatedFeeFiatAmountComputed;
  //
  // @override
  // String get estimatedFeeFiatAmount => (_$estimatedFeeFiatAmountComputed ??=
  //         Computed<String>(() => super.estimatedFeeFiatAmount,
  //             name: 'OutputBase.estimatedFeeFiatAmount'))
  //     .value;

  final _$fiatAmountAtom = Atom(name: 'OutputBase.fiatAmount');

  @override
  String? get fiatAmount {
    _$fiatAmountAtom.reportRead();
    return super.fiatAmount;
  }

  @override
  set fiatAmount(String? value) {
    _$fiatAmountAtom.reportWrite(value, super.fiatAmount, () {
      super.fiatAmount = value;
    });
  }

  final _$cryptoAmountAtom = Atom(name: 'OutputBase.cryptoAmount');

  @override
  String? get cryptoAmount {
    _$cryptoAmountAtom.reportRead();
    return super.cryptoAmount;
  }

  @override
  set cryptoAmount(String? value) {
    _$cryptoAmountAtom.reportWrite(value, super.cryptoAmount, () {
      super.cryptoAmount = value;
    });
  }

  final _$addressAtom = Atom(name: 'OutputBase.address');

  @override
  String? get address {
    _$addressAtom.reportRead();
    return super.address;
  }

  @override
  set address(String? value) {
    _$addressAtom.reportWrite(value, super.address, () {
      super.address = value;
    });
  }

  final _$noteAtom = Atom(name: 'OutputBase.note');

  @override
  String? get note {
    _$noteAtom.reportRead();
    return super.note;
  }

  @override
  set note(String? value) {
    _$noteAtom.reportWrite(value, super.note, () {
      super.note = value;
    });
  }

  final _$sendAllAtom = Atom(name: 'OutputBase.sendAll');

  @override
  bool? get sendAll {
    _$sendAllAtom.reportRead();
    return super.sendAll;
  }

  @override
  set sendAll(bool? value) {
    _$sendAllAtom.reportWrite(value, super.sendAll, () {
      super.sendAll = value;
    });
  }

  final _$parsedAddressAtom = Atom(name: 'OutputBase.parsedAddress');

  @override
  ParsedAddress? get parsedAddress {
    _$parsedAddressAtom.reportRead();
    return super.parsedAddress;
  }

  @override
  set parsedAddress(ParsedAddress? value) {
    _$parsedAddressAtom.reportWrite(value, super.parsedAddress, () {
      super.parsedAddress = value;
    });
  }

  final _$extractedAddressAtom = Atom(name: 'OutputBase.extractedAddress');

  @override
  String? get extractedAddress {
    _$extractedAddressAtom.reportRead();
    return super.extractedAddress;
  }

  @override
  set extractedAddress(String? value) {
    _$extractedAddressAtom.reportWrite(value, super.extractedAddress, () {
      super.extractedAddress = value;
    });
  }

  final _$OutputBaseActionController = ActionController(name: 'OutputBase');

  @override
  void setSendAll() {
    final _$actionInfo =
        _$OutputBaseActionController.startAction(name: 'OutputBase.setSendAll');
    try {
      return super.setSendAll();
    } finally {
      _$OutputBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void reset() {
    final _$actionInfo =
        _$OutputBaseActionController.startAction(name: 'OutputBase.reset');
    try {
      return super.reset();
    } finally {
      _$OutputBaseActionController.endAction(_$actionInfo);
    }
  }

  // @override
  // void setCryptoAmount(String amount) {
  //   final _$actionInfo = _$OutputBaseActionController.startAction(
  //       name: 'OutputBase.setCryptoAmount');
  //   try {
  //     return super.setCryptoAmount(amount);
  //   } finally {
  //     _$OutputBaseActionController.endAction(_$actionInfo);
  //   }
  // }
  //
  // @override
  // void setFiatAmount(String amount) {
  //   final _$actionInfo = _$OutputBaseActionController.startAction(
  //       name: 'OutputBase.setFiatAmount');
  //   try {
  //     return super.setFiatAmount(amount);
  //   } finally {
  //     _$OutputBaseActionController.endAction(_$actionInfo);
  //   }
  // }
  //
  // @override
  // void _updateFiatAmount() {
  //   final _$actionInfo = _$OutputBaseActionController.startAction(
  //       name: 'OutputBase._updateFiatAmount');
  //   try {
  //     return super._updateFiatAmount();
  //   } finally {
  //     _$OutputBaseActionController.endAction(_$actionInfo);
  //   }
  // }
  //
  // @override
  // void _updateCryptoAmount() {
  //   final _$actionInfo = _$OutputBaseActionController.startAction(
  //       name: 'OutputBase._updateCryptoAmount');
  //   try {
  //     return super._updateCryptoAmount();
  //   } finally {
  //     _$OutputBaseActionController.endAction(_$actionInfo);
  //   }
  // }

  @override
  String toString() {
    return '''
fiatAmount: ${fiatAmount},
cryptoAmount: ${cryptoAmount},
address: ${address},
note: ${note},
sendAll: ${sendAll},
parsedAddress: ${parsedAddress},
extractedAddress: ${extractedAddress},
isParsedAddress: ${isParsedAddress},
formattedCryptoAmount: ${formattedCryptoAmount},
estimatedFee: ${estimatedFee},
estimatedFeeFiatAmount: estimatedFeeFiatAmount
    ''';
  }
}
