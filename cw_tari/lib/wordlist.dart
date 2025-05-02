import 'package:tari/ffi.dart';
import 'package:tari/tari.dart' as tari;

List<String> englishTariWordList() =>
    tari.TariWallet.getSeedWordList(TariLanguage.English);
