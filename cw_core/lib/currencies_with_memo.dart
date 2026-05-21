import 'package:cw_core/crypto_currency.dart';

enum MemoLabelType { destinationTag, memo }

const Map<CryptoCurrency, MemoLabelType> _currenciesRequiringMemo = {
  CryptoCurrency.xrp: MemoLabelType.destinationTag,
  CryptoCurrency.xlm: MemoLabelType.memo,
  CryptoCurrency.ton: MemoLabelType.memo,
  CryptoCurrency.eos: MemoLabelType.memo,
  CryptoCurrency.hbar: MemoLabelType.memo,
};

MemoLabelType? memoLabelTypeFor(CryptoCurrency currency) => _currenciesRequiringMemo[currency];
